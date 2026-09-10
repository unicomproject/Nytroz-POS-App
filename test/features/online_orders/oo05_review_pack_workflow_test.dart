import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nytroz_pos/features/fulfilment_pickup/domain/entities/pos_online_order.dart';
import 'package:nytroz_pos/features/fulfilment_pickup/domain/repositories/pos_online_orders_repository.dart';
import 'package:nytroz_pos/features/fulfilment_pickup/presentation/providers/pos_online_orders_provider.dart';

void main() {
  group('OO-05 Pack → Ready workflow', () {
    test('Pack then Ready uses post-Pack expectedVersion', () async {
      final repository = _FakePackingRepository();
      final container = _container(repository);
      addTearDown(container.dispose);

      final result = await container
          .read(posPickingActionsProvider('order-1'))
          .markReadyForCollection(packingNote: '  Fragile  ');

      expect(result.status.toUpperCase(), 'READY');
      expect(repository.packCalls, 1);
      expect(repository.readyCalls, 1);
      expect(repository.packExpectedVersion, 3);
      expect(repository.readyExpectedVersion, 4);
      expect(repository.packingNote, 'Fragile');
      expect(repository.getPickingCalls, greaterThanOrEqualTo(2));
    });

    test('Already Packed skips Pack and only Marks Ready', () async {
      final repository = _FakePackingRepository(initialStatus: 'PACKED', version: 8);
      final container = _container(repository);
      addTearDown(container.dispose);

      await container
          .read(posPickingActionsProvider('order-1'))
          .markReadyForCollection(packingNote: 'ignored');

      expect(repository.packCalls, 0);
      expect(repository.readyCalls, 1);
      expect(repository.readyExpectedVersion, 8);
    });

    test('Already Ready does not Pack or Ready again', () async {
      final repository = _FakePackingRepository(initialStatus: 'READY', version: 9);
      final container = _container(repository);
      addTearDown(container.dispose);

      final result = await container
          .read(posPickingActionsProvider('order-1'))
          .markReadyForCollection();

      expect(result.status.toUpperCase(), 'READY');
      expect(repository.packCalls, 0);
      expect(repository.readyCalls, 0);
    });

    test('CanPack false blocks Pack and Ready', () async {
      final repository =
          _FakePackingRepository(canPack: false, picked: 0, requested: 1);
      final container = _container(repository);
      addTearDown(container.dispose);

      await expectLater(
        () => container
            .read(posPickingActionsProvider('order-1'))
            .markReadyForCollection(),
        throwsA(isA<StateError>()),
      );
      expect(repository.packCalls, 0);
      expect(repository.readyCalls, 0);
    });

    test('Pack 409 recovers via refetch and continues when packed by peer',
        () async {
      final repository = _FakePackingRepository(packConflictThenPeerPacked: true);
      final container = _container(repository);
      addTearDown(container.dispose);

      final result = await container
          .read(posPickingActionsProvider('order-1'))
          .markReadyForCollection();

      expect(result.status.toUpperCase(), 'READY');
      expect(repository.packCalls, 1);
      expect(repository.readyCalls, 1);
      expect(repository.readyExpectedVersion, 5);
    });

    test('Duplicate concurrent workflow is rejected client-side', () async {
      final repository = _FakePackingRepository(packDelayMs: 80);
      final container = _container(repository);
      addTearDown(container.dispose);
      final actions = container.read(posPickingActionsProvider('order-1'));

      final first = actions.markReadyForCollection();
      await expectLater(
        () => actions.markReadyForCollection(),
        throwsA(isA<StateError>()),
      );
      await first;
      expect(repository.packCalls, 1);
      expect(repository.readyCalls, 1);
    });

    test('Whitespace packing note is omitted from Pack body', () async {
      final repository = _FakePackingRepository();
      final container = _container(repository);
      addTearDown(container.dispose);

      await container
          .read(posPickingActionsProvider('order-1'))
          .markReadyForCollection(packingNote: '   ');

      expect(repository.packingNote, isNull);
    });

    test('All picked alone does not locally invent Ready without APIs',
        () async {
      final repository = _FakePackingRepository();
      final container = _container(repository);
      addTearDown(container.dispose);

      final before = await container.read(posPickingOrderProvider('order-1').future);
      expect(before.canPack, isTrue);
      expect(before.isReadyForCollection, isFalse);
      expect(repository.packCalls, 0);
      expect(repository.readyCalls, 0);
    });
  });
}

ProviderContainer _container(_FakePackingRepository repository) =>
    ProviderContainer(
      overrides: [
        posOnlineOrdersOutletIdProvider.overrideWithValue('outlet-a'),
        posOnlineOrdersRepositoryProvider.overrideWithValue(repository),
      ],
    );

class _FakePackingRepository implements PosOnlineOrdersRepository {
  _FakePackingRepository({
    this.initialStatus = 'PICKING',
    this.version = 3,
    this.canPack = true,
    this.requested = 1,
    this.picked = 1,
    this.packConflictThenPeerPacked = false,
    this.packDelayMs = 0,
  });

  String initialStatus;
  int version;
  final bool canPack;
  final double requested;
  final double picked;
  final bool packConflictThenPeerPacked;
  final int packDelayMs;

  int packCalls = 0;
  int readyCalls = 0;
  int getPickingCalls = 0;
  int? packExpectedVersion;
  int? readyExpectedVersion;
  String? packingNote;
  bool _packConflictConsumed = false;

  @override
  Future<PosPickingOrder> getPicking({
    required String outletId,
    required String orderId,
    CancelToken? cancelToken,
  }) async {
    getPickingCalls++;
    return _picking(
      status: initialStatus,
      version: version,
      canPack: canPack && initialStatus.toUpperCase() == 'PICKING',
    );
  }

  @override
  Future<PosFulfillmentCommandResult> pack({
    required String outletId,
    required String orderId,
    String? packingNote,
    required int expectedVersion,
  }) async {
    packCalls++;
    packExpectedVersion = expectedVersion;
    this.packingNote = packingNote;
    if (packDelayMs > 0) {
      await Future<void>.delayed(Duration(milliseconds: packDelayMs));
    }
    if (packConflictThenPeerPacked && !_packConflictConsumed) {
      _packConflictConsumed = true;
      initialStatus = 'PACKED';
      version = 5;
      throw DioException(
        requestOptions: RequestOptions(path: '/pack'),
        response: Response<void>(
          requestOptions: RequestOptions(path: '/pack'),
          statusCode: 409,
        ),
      );
    }
    if (expectedVersion != version) {
      throw DioException(
        requestOptions: RequestOptions(path: '/pack'),
        response: Response<void>(
          requestOptions: RequestOptions(path: '/pack'),
          statusCode: 409,
        ),
      );
    }
    version = expectedVersion + 1;
    initialStatus = 'PACKED';
    return PosFulfillmentCommandResult(
      orderId: orderId,
      status: 'PACKED',
      totalLines: 1,
      completedLines: 1,
      fulfillmentVersion: version,
    );
  }

  @override
  Future<PosFulfillmentCommandResult> markReady({
    required String outletId,
    required String orderId,
    required int expectedVersion,
  }) async {
    readyCalls++;
    readyExpectedVersion = expectedVersion;
    if (expectedVersion != version) {
      throw DioException(
        requestOptions: RequestOptions(path: '/ready'),
        response: Response<void>(
          requestOptions: RequestOptions(path: '/ready'),
          statusCode: 409,
        ),
      );
    }
    version = expectedVersion + 1;
    initialStatus = 'READY';
    return PosFulfillmentCommandResult(
      orderId: orderId,
      status: 'READY',
      totalLines: 1,
      completedLines: 1,
      fulfillmentVersion: version,
    );
  }

  PosPickingOrder _picking({
    required String status,
    required int version,
    required bool canPack,
  }) =>
      PosPickingOrder(
        orderId: 'order-1',
        orderNumber: 'ECOMM-SEED-OO05',
        fulfillmentOrderId: 'ful-1',
        fulfillmentNumber: 'FUL-1',
        status: status,
        assignedToName: 'Cashier',
        customerName: 'Customer',
        outletId: 'outlet-a',
        outletName: 'Outlet A',
        totalLines: 1,
        pickedLines: picked >= requested ? 1 : 0,
        totalUnits: requested,
        pickedUnits: picked,
        remainingUnits: (requested - picked).clamp(0, requested),
        canPack: canPack,
        fulfillmentVersion: version,
        serverTime: DateTime.utc(2026, 9, 8, 12),
        collectionAt: DateTime.utc(2026, 9, 8, 12, 30),
        lines: [
          PosPickingLine(
            id: 'line-1',
            lineNumber: 1,
            productName: 'Product',
            requestedQuantity: requested,
            pickedQuantity: picked,
            status: picked >= requested ? 'PICKED' : 'PICKING',
            sku: 'SKU-1',
            locationCode: 'A1',
            locationName: 'Aisle 1',
          ),
        ],
      );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

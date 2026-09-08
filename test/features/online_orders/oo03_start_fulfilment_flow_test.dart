import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nytroz_pos/features/fulfilment_pickup/domain/entities/pos_online_order.dart';
import 'package:nytroz_pos/features/fulfilment_pickup/domain/repositories/pos_online_orders_repository.dart';
import 'package:nytroz_pos/features/fulfilment_pickup/presentation/providers/pos_online_orders_provider.dart';

void main() {
  test('Confirm forwards order, outlet and authoritative expectedVersion once',
      () async {
    final repository = _FakeRepository();
    final container = _container(repository);
    addTearDown(container.dispose);
    final controller = container.read(posOnlineOrdersProvider.notifier);

    await controller.select('order-1');
    final result = await controller.startFulfillment('order-1');

    expect(result, isNotNull);
    expect(repository.startCalls, 1);
    expect(repository.startedOrderId, 'order-1');
    expect(repository.startedOutletId, 'outlet-a');
    expect(repository.expectedVersion, 5);
  });

  test('409 refreshes authoritative detail and does not return false success',
      () async {
    final repository = _FakeRepository(conflict: true);
    final container = _container(repository);
    addTearDown(container.dispose);
    final controller = container.read(posOnlineOrdersProvider.notifier);

    await controller.select('order-1');
    final result = await controller.startFulfillment('order-1');

    expect(result, isNull);
    expect(repository.startCalls, 1);
    expect(repository.detailCalls, 2);
    final state = container.read(posOnlineOrdersProvider);
    expect(state.selected?.fulfillmentStatus, 'PICKING');
    expect(state.selected?.fulfillmentVersion, 6);
    expect(state.detailErrorMessage, contains('updated by another user'));
  });

  test('delayed Order A detail cannot overwrite currently selected Order B',
      () async {
    final repository = _FakeRepository(delayOrderA: true);
    final container = _container(repository);
    addTearDown(container.dispose);
    final controller = container.read(posOnlineOrdersProvider.notifier);

    final orderA = controller.select('order-a');
    await controller.select('order-b');
    repository.completeOrderA();
    await orderA;

    final selected = container.read(posOnlineOrdersProvider).selected;
    expect(selected?.order.id, 'order-b');
    expect(selected?.order.orderNumber, 'ORDER-B');
    expect(selected?.fulfillmentVersion, 22);
  });
}

ProviderContainer _container(_FakeRepository repository) => ProviderContainer(
      overrides: [
        posOnlineOrdersOutletIdProvider.overrideWithValue('outlet-a'),
        posOnlineOrdersRepositoryProvider.overrideWithValue(repository),
      ],
    );

class _FakeRepository implements PosOnlineOrdersRepository {
  _FakeRepository({this.conflict = false, this.delayOrderA = false});

  final bool conflict;
  final bool delayOrderA;
  final Completer<void> _orderAGate = Completer<void>();
  int startCalls = 0;
  int detailCalls = 0;
  String? startedOutletId;
  String? startedOrderId;
  int? expectedVersion;

  void completeOrderA() {
    if (!_orderAGate.isCompleted) _orderAGate.complete();
  }

  @override
  Future<PosOnlineOrderDetail> get({
    required String outletId,
    required String orderId,
    CancelToken? cancelToken,
  }) async {
    detailCalls++;
    if (delayOrderA && orderId == 'order-a') await _orderAGate.future;
    return _detail(
      orderId: orderId,
      status: conflict && detailCalls > 1 ? 'PICKING' : 'PENDING',
      version: delayOrderA && orderId == 'order-b'
          ? 22
          : conflict && detailCalls > 1
              ? 6
              : 5,
    );
  }

  @override
  Future<PosStartFulfillmentResult> startFulfillment({
    required String outletId,
    required String orderId,
    required int expectedVersion,
    CancelToken? cancelToken,
  }) async {
    startCalls++;
    startedOutletId = outletId;
    startedOrderId = orderId;
    this.expectedVersion = expectedVersion;
    if (conflict) {
      throw DioException(
        requestOptions: RequestOptions(path: '/fulfilment/start'),
        response: Response<void>(
          requestOptions: RequestOptions(path: '/fulfilment/start'),
          statusCode: 409,
        ),
      );
    }
    return const PosStartFulfillmentResult(
      orderId: 'order-1',
      fulfillmentOrderId: 'fulfillment-1',
      status: 'PICKING',
      alreadyStarted: false,
      fulfillmentVersion: 6,
    );
  }

  @override
  Future<PosOnlineOrderPage> list(
    PosOnlineOrdersQuery query, {
    CancelToken? cancelToken,
  }) async =>
      const PosOnlineOrderPage(
        items: [],
        summary: PosOnlineOrderSummary(
          total: 0,
          pending: 0,
          preparing: 0,
          ready: 0,
          overdue: 0,
          newOrders: 0,
          collected: 0,
          cancelled: 0,
        ),
        page: 1,
        pageSize: 20,
        totalCount: 0,
        totalPages: 0,
      );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

PosOnlineOrderDetail _detail({
  String orderId = 'order-1',
  required String status,
  required int version,
}) =>
    PosOnlineOrderDetail(
      order: PosOnlineOrder(
        id: orderId,
        orderNumber: orderId.toUpperCase(),
        customerName: 'Customer',
        status: 'ACCEPTED',
        statusLabel: 'Accepted',
        paymentStatus: 'PAID',
        currencyCode: 'LKR',
        totalAmount: 100,
        lineCount: 1,
        unitCount: 1,
      ),
      outletId: 'outlet-a',
      outletName: 'Outlet A',
      paymentStatus: 'PAID',
      subtotal: 100,
      discount: 0,
      tax: 0,
      charges: 0,
      paid: 100,
      balanceDue: 0,
      fulfillmentStatus: status,
      fulfillmentVersion: version,
      lines: const [],
    );

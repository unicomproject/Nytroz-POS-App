import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nytroz_pos/core/access/pos_access_codes.dart';
import 'package:nytroz_pos/core/storage/app_secure_storage.dart';
import 'package:nytroz_pos/features/auth/data/datasources/auth_session_storage.dart';
import 'package:nytroz_pos/features/auth/domain/entities/auth_session.dart';
import 'package:nytroz_pos/features/auth/presentation/providers/session_provider.dart';
import 'package:nytroz_pos/features/fulfilment_pickup/domain/entities/pos_online_order.dart';
import 'package:nytroz_pos/features/fulfilment_pickup/domain/repositories/pos_online_orders_repository.dart';
import 'package:nytroz_pos/features/fulfilment_pickup/presentation/providers/pos_online_orders_provider.dart';
import 'package:nytroz_pos/features/fulfilment_pickup/presentation/screens/ready_for_collection_screen.dart';

void main() {
  group('OO-06 Ready for Collection workflow', () {
    test('notifyCustomerOrderReady posts notify-ready without recipient body',
        () async {
      final remote = _FakeRepo();
      final container = ProviderContainer(overrides: [
        posOnlineOrdersOutletIdProvider.overrideWith((ref) => 'outlet-1'),
        posOnlineOrdersRepositoryProvider.overrideWithValue(remote),
        posPickingOrderProvider('order-ready').overrideWith(
          (ref) async => _readyOrder,
        ),
      ]);
      addTearDown(container.dispose);

      final result = await container
          .read(posPickingActionsProvider('order-ready'))
          .notifyCustomerOrderReady();

      expect(remote.notifyCalls, 1);
      expect(remote.lastNotifyOrderId, 'order-ready');
      expect(remote.lastNotifyOutletId, 'outlet-1');
      expect(remote.lastNotifyBody, isNull);
      expect(result.alreadyExisted, isFalse);
      expect(_readyOrder.status.toUpperCase(), 'READY');
      expect(_readyOrder.collectedAt, isNull);
    });

    test('already notified response is accepted without lifecycle change',
        () async {
      final remote = _FakeRepo()..alreadyExisted = true;
      final container = ProviderContainer(overrides: [
        posOnlineOrdersOutletIdProvider.overrideWith((ref) => 'outlet-1'),
        posOnlineOrdersRepositoryProvider.overrideWithValue(remote),
        posPickingOrderProvider('order-ready').overrideWith(
          (ref) async => _readyOrder,
        ),
      ]);
      addTearDown(container.dispose);

      final result = await container
          .read(posPickingActionsProvider('order-ready'))
          .notifyCustomerOrderReady();
      expect(result.alreadyExisted, isTrue);
      expect(remote.notifyCalls, 1);
    });

    test('notify blocked when order is not READY', () async {
      final remote = _FakeRepo();
      final container = ProviderContainer(overrides: [
        posOnlineOrdersOutletIdProvider.overrideWith((ref) => 'outlet-1'),
        posOnlineOrdersRepositoryProvider.overrideWithValue(remote),
        posPickingOrderProvider('order-picking').overrideWith(
          (ref) async => _pickingOrder,
        ),
      ]);
      addTearDown(container.dispose);

      await expectLater(
        () => container
            .read(posPickingActionsProvider('order-picking'))
            .notifyCustomerOrderReady(),
        throwsA(isA<StateError>()),
      );
      expect(remote.notifyCalls, 0);
    });

    test('duplicate concurrent notify is rejected client-side', () async {
      final remote = _FakeRepo()..delay = const Duration(milliseconds: 80);
      final container = ProviderContainer(overrides: [
        posOnlineOrdersOutletIdProvider.overrideWith((ref) => 'outlet-1'),
        posOnlineOrdersRepositoryProvider.overrideWithValue(remote),
        posPickingOrderProvider('order-ready').overrideWith(
          (ref) async => _readyOrder,
        ),
      ]);
      addTearDown(container.dispose);
      final actions = container.read(posPickingActionsProvider('order-ready'));
      final first = actions.notifyCustomerOrderReady();
      await expectLater(
        () => actions.notifyCustomerOrderReady(),
        throwsA(isA<StateError>()),
      );
      await first;
      expect(remote.notifyCalls, 1);
    });
  });

  group('OO-06 Ready for Collection UI', () {
    final overflow = <String>[];

    setUp(() {
      overflow.clear();
      final previous = FlutterError.onError;
      FlutterError.onError = (details) {
        final text = details.toString();
        if (text.contains('overflowed') || text.contains('OVERFLOWED')) {
          overflow.add(text.split('\n').first);
        }
        previous?.call(details);
      };
      addTearDown(() => FlutterError.onError = previous);
    });

    for (final size in const [
      Size(1280, 800),
      Size(1180, 820),
      Size(1100, 700),
    ]) {
      testWidgets(
          '${size.width.toInt()}x${size.height.toInt()} fits without overflow',
          (tester) async {
        await _pumpReady(tester, size, order: _readyOrder);
        expect(overflow, isEmpty, reason: overflow.join(' | '));
        expect(tester.takeException(), isNull);
        expect(find.text('3 of 3'), findsOneWidget);
        expect(find.textContaining("What's next?"), findsOneWidget);
        expect(find.text('Print Collection Slip'), findsNothing);
        expect(find.text('Share Collection Info'), findsNothing);
        expect(find.byKey(const Key('notify-customer-order-ready')),
            findsOneWidget);
        expect(find.byKey(const Key('view-order-details')), findsOneWidget);
        expect(find.textContaining('All items picked and packed'), findsOneWidget);
        if (size.width >= 1180) {
          expect(find.byType(SingleChildScrollView), findsNothing);
        }
      });
    }

    testWidgets('view_ready denied blocks screen', (tester) async {
      await _pumpReady(
        tester,
        const Size(1280, 800),
        order: _readyOrder,
        permissions: const [
          PosPermissionCodes.accessOnlineOrders,
          PosPermissionCodes.viewOnlineOrders,
        ],
      );
      expect(find.textContaining('Ready-for-collection permission'),
          findsOneWidget);
      expect(find.byKey(const Key('notify-customer-order-ready')), findsNothing);
    });

    testWidgets('notify permission denied hides CTA with reflow', (tester) async {
      await _pumpReady(
        tester,
        const Size(1280, 800),
        order: _readyOrder,
        permissions: const [
          PosPermissionCodes.accessOnlineOrders,
          PosPermissionCodes.viewOnlineOrders,
          PosPermissionCodes.viewOnlineOrderReady,
        ],
      );
      expect(find.textContaining('All items picked and packed'), findsOneWidget);
      expect(find.byKey(const Key('notify-customer-order-ready')), findsNothing);
      expect(find.text('Print Collection Slip'), findsNothing);
    });

    testWidgets('PICKING order does not fake READY hero CTA', (tester) async {
      await _pumpReady(
        tester,
        const Size(1280, 800),
        order: _pickingOrder,
      );
      expect(find.textContaining('not ready for collection'), findsOneWidget);
      expect(find.byKey(const Key('notify-customer-order-ready')), findsNothing);
    });

    testWidgets('primary CTA uses theme primary', (tester) async {
      const primary = Color(0xFFFF6A00);
      await _pumpReady(
        tester,
        const Size(1280, 800),
        order: _readyOrder,
        primary: primary,
      );
      final theme = Theme.of(
        tester.element(find.byKey(const Key('notify-customer-order-ready'))),
      );
      expect(theme.colorScheme.primary.value, primary.value);
    });

    testWidgets('Pink-like theme loads Ready screen', (tester) async {
      await _pumpReady(
        tester,
        const Size(1280, 800),
        order: _readyOrder,
        primary: const Color(0xFFE91E63),
      );
      expect(find.textContaining('All items picked and packed'), findsOneWidget);
      expect(find.text('3 of 3'), findsOneWidget);
    });
  });
}

Future<void> _pumpReady(
  WidgetTester tester,
  Size size, {
  required PosPickingOrder order,
  List<String>? permissions,
  Color primary = const Color(0xFFFF6A00),
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
  const chrome = 120.0;
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authSessionProvider.overrideWith(
          (ref) => _PresetAuthSessionNotifier(
            AuthSession(
              accessToken: 'token',
              userId: 'user-1',
              userDisplayName: 'Cashier',
              permissionCodes: permissions ??
                  const [
                    PosPermissionCodes.accessOnlineOrders,
                    PosPermissionCodes.viewOnlineOrders,
                    PosPermissionCodes.viewOnlineOrderReady,
                    PosPermissionCodes.notifyOnlineOrderCustomer,
                  ],
            ),
          ),
        ),
        posPickingOrderProvider(order.orderId).overrideWith((ref) async => order),
      ],
      child: MaterialApp(
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: primary).copyWith(
            primary: primary,
          ),
          useMaterial3: true,
        ),
        home: Scaffold(
          body: SizedBox(
            width: size.width,
            height: size.height - chrome,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 10, 24, 10),
              child: ReadyForCollectionScreen(
                order: order,
                onBack: () {},
                onBackToReviewPack: () {},
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

class _PresetAuthSessionNotifier extends AuthSessionNotifier {
  _PresetAuthSessionNotifier(AuthSession session) : super(_TestStorage()) {
    state = session;
  }
}

class _TestStorage extends AuthSessionStorage {
  _TestStorage() : super(const AppSecureStorage(FlutterSecureStorage()));
  @override
  Future<AuthSession?> read() async => null;
  @override
  Future<void> save(AuthSession session) async {}
  @override
  Future<void> clear() async {}
}

class _FakeRepo implements PosOnlineOrdersRepository {
  int notifyCalls = 0;
  String? lastNotifyOrderId;
  String? lastNotifyOutletId;
  Map<String, dynamic>? lastNotifyBody;
  bool alreadyExisted = false;
  Duration delay = Duration.zero;
  PosPickingOrder current = _readyOrder;

  @override
  Future<PosPickingOrder> getPicking({
    required String outletId,
    required String orderId,
    CancelToken? cancelToken,
  }) async =>
      current;

  @override
  Future<PosNotifyReadyResult> notifyReady({
    required String outletId,
    required String orderId,
  }) async {
    notifyCalls += 1;
    lastNotifyOrderId = orderId;
    lastNotifyOutletId = outletId;
    lastNotifyBody = null;
    if (delay > Duration.zero) await Future<void>.delayed(delay);
    return PosNotifyReadyResult(
      eventId: 'evt-1',
      eventNumber: 'ECOM-ORDER-READY-$orderId',
      alreadyExisted: alreadyExisted,
      createdMessageCount: alreadyExisted ? 0 : 1,
    );
  }

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

const _line = PosPickingLine(
  id: 'line-1',
  lineNumber: 1,
  productName: 'Training Basketball',
  requestedQuantity: 1,
  pickedQuantity: 1,
  status: 'PICKED',
);

const _readyOrder = PosPickingOrder(
  orderId: 'order-ready',
  orderNumber: 'ECOMM-SEED-ACCEPTED-002',
  fulfillmentOrderId: 'ful-1',
  fulfillmentNumber: 'FUL-1',
  status: 'READY',
  assignedToName: 'Cashier',
  customerName: 'Click Collect Customer',
  outletName: 'Development Main Store',
  totalLines: 1,
  pickedLines: 1,
  totalUnits: 1,
  pickedUnits: 1,
  canPack: false,
  fulfillmentVersion: 5,
  pickupStatus: 'READY',
  readyAt: null,
  collectedAt: null,
  lines: [_line],
);

const _pickingOrder = PosPickingOrder(
  orderId: 'order-picking',
  orderNumber: 'ECOMM-SEED-ACCEPTED-003',
  fulfillmentOrderId: 'ful-2',
  fulfillmentNumber: 'FUL-2',
  status: 'PICKING',
  assignedToName: 'Cashier',
  customerName: 'Customer',
  totalLines: 1,
  pickedLines: 1,
  canPack: true,
  fulfillmentVersion: 3,
  lines: [_line],
);

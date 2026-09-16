import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:nytroz_pos/core/access/pos_access_codes.dart';
import 'package:nytroz_pos/features/auth/domain/entities/auth_session.dart';
import 'package:nytroz_pos/features/auth/presentation/providers/session_provider.dart';
import 'package:nytroz_pos/features/fulfilment_pickup/domain/entities/pos_online_order.dart';
import 'package:nytroz_pos/features/fulfilment_pickup/domain/repositories/pos_online_orders_repository.dart';
import 'package:nytroz_pos/features/fulfilment_pickup/presentation/providers/pos_online_orders_provider.dart';
import 'package:nytroz_pos/features/fulfilment_pickup/presentation/screens/online_order_detail_screen.dart';
import 'package:nytroz_pos/features/fulfilment_pickup/presentation/screens/pos_online_order_detail_route_screen.dart';
import 'package:nytroz_pos/features/fulfilment_pickup/presentation/utils/order_detail_next_action.dart';
import 'package:nytroz_pos/shared/widgets/pos_action_buttons.dart';
import '../helpers/test_auth_session_storage.dart';

final permissions = {
  PosPermissionCodes.accessOnlineOrders,
  PosPermissionCodes.viewOnlineOrders,
  PosPermissionCodes.startOnlineOrderFulfillment,
  PosPermissionCodes.viewOnlineOrderPicking,
  PosPermissionCodes.viewOnlineOrderPacking,
  PosPermissionCodes.viewOnlineOrderReady,
};

PosOnlineOrderDetail detail(
        {String status = 'PICKING',
        double remaining = 2,
        bool canPack = false,
        bool ready = false,
        bool graph = true,
        String? pickup,
        String orderStatus = 'ACCEPTED',
        int? version = 5}) =>
    PosOnlineOrderDetail.fromJson({
      'id': 'order-1',
      'orderNumber': 'ECOMM-PREPARING-001',
      'status': 'PREPARING',
      'statusLabel': 'Preparing',
      'orderStatus': orderStatus,
      'fulfillmentStatus': status,
      'fulfillmentOrderId': graph ? 'fo-1' : null,
      'fulfillmentVersion': version,
      'pickupStatus': pickup ?? (ready ? 'READY' : 'PENDING'),
      'canPack': canPack,
      'isReadyForCollection': ready,
      'readyAt': ready ? '2026-09-15T10:00:00Z' : null,
      'outletName': 'Main Store',
      'customerName': 'Customer 1',
      'paymentStatus': 'UNPAID',
      'currencyCode': 'LKR',
      'totalAmount': 3200,
      'balanceDue': 3200,
      'serverTime': '2026-09-15T10:00:00Z',
      'lines': [
        {
          'id': 'line-1',
          'fulfillmentOrderLineId': graph ? 'fl-1' : null,
          'productName': 'Fan Scarf',
          'quantity': 2,
          'pickedQuantity': 2 - remaining,
          'remainingQuantity': remaining,
          'unitPrice': 1600,
          'lineTotal': 3200
        }
      ],
    });

class _Repo implements PosOnlineOrdersRepository {
  PosOnlineOrderDetail current = detail();
  int calls = 0;
  Completer<PosOnlineOrderDetail>? delayed;
  @override
  Future<PosOnlineOrderDetail> get(
      {required String outletId,
      required String orderId,
      CancelToken? cancelToken}) {
    calls++;
    final pending = delayed;
    delayed = null;
    return pending?.future ?? Future.value(current);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

ProviderContainer _containerFor(_Repo repo, {Set<String>? granted}) =>
    ProviderContainer(overrides: [
      posOnlineOrdersRepositoryProvider.overrideWithValue(repo),
      posOnlineOrdersOutletIdProvider.overrideWith((ref) => 'outlet-1'),
      authSessionProvider.overrideWith((ref) => PresetAuthSessionNotifier(
          AuthSession(
              accessToken: 'test',
              userId: 'cashier',
              userDisplayName: 'Cashier',
              permissionCodes: (granted ?? permissions).toList()))),
    ]);

void main() {
  final cases = <(String, PosOnlineOrderDetail, OrderDetailNextAction)>[
    ('not started', detail(status: 'PENDING'), OrderDetailNextAction.start),
    ('picking', detail(), OrderDetailNextAction.pick),
    (
      'all picked',
      detail(remaining: 0, canPack: true),
      OrderDetailNextAction.pack
    ),
    (
      'packed',
      detail(status: 'PACKED', remaining: 0),
      OrderDetailNextAction.pack
    ),
    (
      'ready',
      detail(status: 'READY', remaining: 0, ready: true),
      OrderDetailNextAction.ready
    ),
    ('collected', detail(pickup: 'COLLECTED'), OrderDetailNextAction.readOnly),
    (
      'cancelled',
      detail(orderStatus: 'CANCELLED'),
      OrderDetailNextAction.readOnly
    ),
    ('missing graph', detail(graph: false), OrderDetailNextAction.unavailable),
    (
      'missing version',
      detail(version: null),
      OrderDetailNextAction.unavailable
    ),
    (
      'display preparing only',
      detail(status: 'PREPARING'),
      OrderDetailNextAction.unavailable
    ),
    (
      'no backend pack approval',
      detail(remaining: 0),
      OrderDetailNextAction.unavailable
    ),
    (
      'conflicting pack approval',
      detail(canPack: true),
      OrderDetailNextAction.unavailable
    ),
    (
      'invalid ready graph',
      detail(status: 'READY'),
      OrderDetailNextAction.unavailable
    ),
  ];
  for (final (name, value, expected) in cases) {
    test(name,
        () => expect(orderDetailNextAction(value, permissions), expected));
  }
  for (final permission in [
    PosPermissionCodes.startOnlineOrderFulfillment,
    PosPermissionCodes.viewOnlineOrderPicking,
    PosPermissionCodes.viewOnlineOrderPacking,
    PosPermissionCodes.viewOnlineOrderReady
  ]) {
    test('missing $permission hides its action', () {
      final index = [
        PosPermissionCodes.startOnlineOrderFulfillment,
        PosPermissionCodes.viewOnlineOrderPicking,
        PosPermissionCodes.viewOnlineOrderPacking,
        PosPermissionCodes.viewOnlineOrderReady
      ].indexOf(permission);
      expect(
          orderDetailNextAction(cases[[0, 1, 2, 4][index]].$2,
              permissions.difference({permission})),
          OrderDetailNextAction.hidden);
    });
  }
  for (final size in [
    const Size(1280, 800),
    const Size(1180, 820),
    const Size(1100, 700)
  ]) {
    for (final primary in [const Color(0xFFFF6A00), const Color(0xFFFF1493)]) {
      testWidgets('visible themed lifecycle CTA $size $primary',
          (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final container = _containerFor(_Repo());
        addTearDown(container.dispose);
        for (final index in [0, 1, 2, 4]) {
          final value = cases[index].$2;
          await tester.pumpWidget(UncontrolledProviderScope(
              container: container,
              child: MaterialApp(
                  theme: ThemeData(
                      colorScheme: ColorScheme.fromSeed(seedColor: primary)
                          .copyWith(primary: primary)),
                  home: Scaffold(
                      appBar: AppBar(title: const Text('Existing header')),
                      bottomNavigationBar: const SizedBox(
                          height: 72, child: Text('Existing footer')),
                      body: OnlineOrderDetailScreen(
                          state: PosOnlineOrdersState(selected: value))))));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          final button = find.byType(PosPrimaryActionButton);
          expect(button.hitTestable(), findsOneWidget);
          final bounds = tester.getRect(button);
          expect(bounds.bottom, lessThanOrEqualTo(size.height - 72));
          final widget = tester.widget<PosPrimaryActionButton>(button);
          expect(widget.semanticLabel, isNotEmpty);
          final decorated = tester.widget<DecoratedBox>(find
              .descendant(of: button, matching: find.byType(DecoratedBox))
              .first);
          expect((decorated.decoration as BoxDecoration).color, primary);
          expect(find.text('Existing header'), findsOneWidget);
          expect(find.text('Existing footer'), findsOneWidget);
        }
      });
    }
  }
  testWidgets('permission-hidden action leaves no action region',
      (tester) async {
    final container = _containerFor(_Repo(), granted: {
      PosPermissionCodes.accessOnlineOrders,
      PosPermissionCodes.viewOnlineOrders
    });
    addTearDown(container.dispose);
    await tester.pumpWidget(UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
            home: Scaffold(
                body: OnlineOrderDetailScreen(
                    state: PosOnlineOrdersState(selected: detail()))))));
    expect(find.byType(PosPrimaryActionButton), findsNothing);
    expect(find.byKey(const Key('oo02-unavailable')), findsNothing);
  });
  testWidgets(
      'existing workspace route and return refetch update lifecycle CTA',
      (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repo = _Repo();
    final container = _containerFor(repo);
    addTearDown(container.dispose);
    final router =
        GoRouter(initialLocation: '/pos/online-orders/order-1', routes: [
      GoRoute(
          path: '/pos/online-orders/:orderId',
          builder: (_, state) => const Scaffold(
              body: PosOnlineOrderDetailRouteScreen(orderId: 'order-1'))),
      GoRoute(
          path: '/pos/online-orders/:orderId/picking',
          builder: (context, state) => Scaffold(
              body: TextButton(
                  onPressed: () => context.pop(),
                  child: const Text('Back from existing workspace')))),
    ]);
    addTearDown(router.dispose);
    await tester.pumpWidget(UncontrolledProviderScope(
        container: container, child: MaterialApp.router(routerConfig: router)));
    await tester.pumpAndSettle();
    for (final next in [
      detail(remaining: 0, canPack: true),
      detail(status: 'READY', remaining: 0, ready: true)
    ]) {
      final before = repo.calls;
      await tester.tap(find.byKey(const Key('oo02-next-action')));
      await tester.pumpAndSettle();
      expect(find.text('Back from existing workspace'), findsOneWidget);
      repo.current = next;
      await tester.tap(find.text('Back from existing workspace'));
      await tester.pumpAndSettle();
      expect(repo.calls, greaterThan(before));
      expect(
          find.text(next.isReadyForCollection
              ? 'View Ready for Collection'
              : 'Review & Pack'),
          findsOneWidget);
      expect(find.text('Continue Picking'), findsNothing);
    }
  });
  test('late detail response cannot restore an obsolete action', () async {
    final repo = _Repo();
    final container = _containerFor(repo);
    addTearDown(container.dispose);
    final pending = Completer<PosOnlineOrderDetail>();
    repo.delayed = pending;
    final notifier = container.read(posOnlineOrdersProvider.notifier);
    final old = notifier.select('order-1');
    repo.current = detail(remaining: 0, canPack: true);
    await notifier.select('order-1');
    pending.complete(detail());
    await old;
    expect(
        orderDetailNextAction(
            container.read(posOnlineOrdersProvider).selected!, permissions),
        OrderDetailNextAction.pack);
  });
}

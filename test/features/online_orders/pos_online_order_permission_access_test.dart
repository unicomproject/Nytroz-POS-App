import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nytroz_pos/core/access/pos_access_codes.dart';
import 'package:nytroz_pos/core/access/pos_permission_access.dart';
import 'package:nytroz_pos/core/storage/app_secure_storage.dart';
import 'package:nytroz_pos/features/auth/data/datasources/auth_session_storage.dart';
import 'package:nytroz_pos/features/auth/domain/entities/auth_session.dart';
import 'package:nytroz_pos/features/auth/presentation/providers/session_provider.dart';
import 'package:nytroz_pos/features/fulfilment_pickup/domain/entities/pos_online_order.dart';
import 'package:nytroz_pos/features/fulfilment_pickup/presentation/providers/pos_online_orders_provider.dart';
import 'package:nytroz_pos/features/fulfilment_pickup/presentation/screens/online_order_detail_screen.dart';

void main() {
  group('online order permission access', () {
    test('queue requires both canonical access and view permissions', () {
      expect(
        PosPermissionAccess.canViewOnlineOrders({
          PosPermissionCodes.accessOnlineOrders,
        }),
        isFalse,
      );
      expect(
        PosPermissionAccess.canViewOnlineOrders({
          PosPermissionCodes.viewOnlineOrders,
        }),
        isFalse,
      );
      expect(
        PosPermissionAccess.canViewOnlineOrders({
          PosPermissionCodes.manageOnlineOrders,
        }),
        isFalse,
      );
      expect(
        PosPermissionAccess.canViewOnlineOrders({
          PosPermissionCodes.accessOnlineOrders,
          PosPermissionCodes.viewOnlineOrders,
        }),
        isTrue,
      );
    });

    test('picking and packing require their exact view permissions', () {
      final queue = {
        PosPermissionCodes.accessOnlineOrders,
        PosPermissionCodes.viewOnlineOrders,
      };

      expect(PosPermissionAccess.canViewOnlineOrderPicking(queue), isFalse);
      expect(
        PosPermissionAccess.canViewOnlineOrderPicking({
          ...queue,
          PosPermissionCodes.viewOnlineOrderPicking,
        }),
        isTrue,
      );
      expect(
        PosPermissionAccess.canViewOnlineOrderPacking({
          ...queue,
          PosPermissionCodes.viewOnlineOrderPicking,
        }),
        isFalse,
      );
      expect(
        PosPermissionAccess.canViewOnlineOrderPacking({
          ...queue,
          PosPermissionCodes.viewOnlineOrderPicking,
          PosPermissionCodes.viewOnlineOrderPacking,
        }),
        isTrue,
      );
    });
  });

  test('maps backend conflict codes to a production-safe message', () {
    final error = DioException(
      requestOptions: RequestOptions(path: '/online-orders'),
      response: Response<Object?>(
        requestOptions: RequestOptions(path: '/online-orders'),
        statusCode: 409,
        data: const {
          'code': 'online_orders.fulfilment_conflict',
          'message': 'internal detail that must not be rendered',
        },
      ),
    );

    final message = onlineOrderErrorMessage(error);
    expect(message, contains('changed'));
    expect(message, isNot(contains('internal detail')));
  });

  test('maps outlet access denial to an actionable safe message', () {
    final error = DioException(
      requestOptions: RequestOptions(path: '/online-orders'),
      response: Response<Object?>(
        requestOptions: RequestOptions(path: '/online-orders'),
        statusCode: 403,
        data: const {
          'code': 'online_orders.outlet_access_denied',
          'message': 'internal authorization detail',
        },
      ),
    );

    final message = onlineOrderErrorMessage(error);
    expect(message, contains('access to this outlet'));
    expect(message, contains('administrator'));
    expect(message, isNot(contains('internal authorization detail')));
  });

  testWidgets('eligible Start is visible with the exact permission',
      (tester) async {
    await _pumpDetail(tester, status: 'PENDING', canStart: true);
    expect(find.byKey(const Key('oo02-start-fulfilment')), findsOneWidget);
  });

  testWidgets('eligible Start is absent without the exact permission',
      (tester) async {
    await _pumpDetail(tester, status: 'PENDING', canStart: false);
    expect(find.byKey(const Key('oo02-start-fulfilment')), findsNothing);
  });

  for (final status in [
    'PICKING',
    'PICKED',
    'PACKED',
    'READY',
    'FULFILLED',
    'CANCELLED',
  ]) {
    testWidgets('Start is absent for lifecycle $status', (tester) async {
      await _pumpDetail(tester, status: status, canStart: true);
      expect(find.byKey(const Key('oo02-start-fulfilment')), findsNothing);
    });
  }
}

Future<void> _pumpDetail(
  WidgetTester tester, {
  required String status,
  required bool canStart,
}) async {
  final permissions = [
    PosPermissionCodes.accessOnlineOrders,
    PosPermissionCodes.viewOnlineOrders,
    if (canStart) PosPermissionCodes.startOnlineOrderFulfillment,
  ];
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authSessionProvider.overrideWith(
          (ref) => _PresetAuthSessionNotifier(
            AuthSession(
              accessToken: 'test-token',
              userId: 'user-1',
              userDisplayName: 'Cashier',
              permissionCodes: permissions,
            ),
          ),
        ),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: OnlineOrderDetailScreen(
            state: PosOnlineOrdersState(selected: _detail(status)),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

PosOnlineOrderDetail _detail(String status) => PosOnlineOrderDetail(
      order: const PosOnlineOrder(
        id: 'order-1',
        orderNumber: 'ORDER-1',
        customerName: 'Customer',
        status: 'ACCEPTED',
        statusLabel: 'Accepted',
        paymentStatus: 'PAID',
        currencyCode: 'LKR',
        totalAmount: 100,
        lineCount: 1,
        unitCount: 1,
      ),
      outletName: 'Outlet A',
      paymentStatus: 'PAID',
      subtotal: 100,
      discount: 0,
      tax: 0,
      charges: 0,
      paid: 100,
      balanceDue: 0,
      fulfillmentStatus: status,
      fulfillmentVersion: 5,
      lines: const [],
    );

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

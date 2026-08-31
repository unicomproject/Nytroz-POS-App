import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nytroz_pos/core/access/pos_access_codes.dart';
import 'package:nytroz_pos/core/access/pos_permission_access.dart';
import 'package:nytroz_pos/features/fulfilment_pickup/presentation/providers/pos_online_orders_provider.dart';

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
}

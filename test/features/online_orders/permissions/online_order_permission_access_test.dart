import 'package:flutter_test/flutter_test.dart';
import 'package:nytroz_pos/core/access/pos_access_codes.dart';
import 'package:nytroz_pos/core/access/pos_permission_access.dart';

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
      expect(
        PosPermissionAccess.canPackOnlineOrder({
          ...queue,
          PosPermissionCodes.viewOnlineOrderPicking,
          PosPermissionCodes.viewOnlineOrderPacking,
        }),
        isFalse,
      );
      expect(
        PosPermissionAccess.canPackOnlineOrder({
          ...queue,
          PosPermissionCodes.viewOnlineOrderPicking,
          PosPermissionCodes.viewOnlineOrderPacking,
          PosPermissionCodes.packOnlineOrder,
        }),
        isTrue,
      );
      expect(
        PosPermissionAccess.canMarkOnlineOrderReady({
          ...queue,
          PosPermissionCodes.viewOnlineOrderPicking,
          PosPermissionCodes.viewOnlineOrderPacking,
          PosPermissionCodes.markOnlineOrderReady,
        }),
        isTrue,
      );
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:nytroz_pos/core/access/cashier_pos/cashier_pos_canonical_permission_codes.dart';
import 'package:nytroz_pos/core/access/effective_permission_set.dart';
import 'package:nytroz_pos/core/access/pos_access_codes.dart';
import 'package:nytroz_pos/core/access/pos_customers_orders_returns_visibility.dart';
import 'package:nytroz_pos/core/access/pos_permission_access.dart';

void main() {
  const productionOnlineOrderCodes = <String>[
    PosPermissionCodes.accessOnlineOrders,
    PosPermissionCodes.viewOnlineOrders,
    PosPermissionCodes.startOnlineOrderFulfillment,
    PosPermissionCodes.viewOnlineOrderPicking,
    PosPermissionCodes.pickOnlineOrderItem,
    PosPermissionCodes.scanOnlineOrderItem,
    PosPermissionCodes.manuallyEnterOnlineOrderItem,
    PosPermissionCodes.reportOnlineOrderPickingIssue,
    PosPermissionCodes.addOnlineOrderPickingNote,
    PosPermissionCodes.viewOnlineOrderPacking,
    PosPermissionCodes.packOnlineOrder,
    PosPermissionCodes.markOnlineOrderReady,
  ];

  group('Online Orders canonical reconciliation', () {
    test('production Online Order codes are in frozen role-assignable catalog', () {
      for (final code in productionOnlineOrderCodes) {
        expect(
          CashierPosCanonicalPermissionCodes.roleAssignableCodes.contains(code),
          isTrue,
          reason: code,
        );
      }
    });

    test('American fulfillment spelling is not in catalog', () {
      const wrong = 'commerce.online_order.fulfillment.start';
      expect(
        CashierPosCanonicalPermissionCodes.roleAssignableCodes.contains(wrong),
        isFalse,
      );
      expect(PosPermissionCodes.startOnlineOrderFulfillment, isNot(wrong));
      expect(
        PosPermissionCodes.startOnlineOrderFulfillment,
        'commerce.online_order.fulfilment.start',
      );
    });

    test('route guard requires access AND view — not access alone', () {
      final accessOnly = {
        PosPermissionCodes.accessOnlineOrders,
      };
      final both = {
        PosPermissionCodes.accessOnlineOrders,
        PosPermissionCodes.viewOnlineOrders,
      };
      expect(PosPermissionAccess.canViewOnlineOrders(accessOnly), isFalse);
      expect(PosPermissionAccess.canViewOnlineOrders(both), isTrue);
    });

    test('route guard rejects missing access even with view', () {
      final viewOnly = {PosPermissionCodes.viewOnlineOrders};
      expect(PosPermissionAccess.canViewOnlineOrders(viewOnly), isFalse);
    });

    test('feature access does not grant Start Fulfilment or Picking', () {
      final p = EffectivePermissionSet.fromIterable([
        PosPermissionCodes.accessOnlineOrders,
        PosPermissionCodes.viewOnlineOrders,
      ]);
      expect(PosCustomersOrdersReturnsVisibility.canAccessOnlineOrders(p), isTrue);
      expect(
        PosCustomersOrdersReturnsVisibility.canStartOnlineFulfilment(p),
        isFalse,
      );
      expect(PosCustomersOrdersReturnsVisibility.canViewOnlinePicking(p), isFalse);
    });

    test('Start Fulfilment and Picking appear only when granted', () {
      final start = EffectivePermissionSet.fromIterable([
        PosPermissionCodes.accessOnlineOrders,
        PosPermissionCodes.viewOnlineOrders,
        PosPermissionCodes.startOnlineOrderFulfillment,
      ]);
      expect(
        PosCustomersOrdersReturnsVisibility.canStartOnlineFulfilment(start),
        isTrue,
      );

      final picking = EffectivePermissionSet.fromIterable([
        PosPermissionCodes.accessOnlineOrders,
        PosPermissionCodes.viewOnlineOrders,
        PosPermissionCodes.viewOnlineOrderPicking,
      ]);
      expect(
        PosCustomersOrdersReturnsVisibility.canViewOnlinePicking(picking),
        isTrue,
      );
    });

    test('Phone/Tablet/Desktop use same Online Order gate helpers', () {
      final p = EffectivePermissionSet.fromIterable([
        PosPermissionCodes.accessOnlineOrders,
        PosPermissionCodes.viewOnlineOrders,
        PosPermissionCodes.startOnlineOrderFulfillment,
      ]);
      // Logical parity: helpers are device-agnostic (no MediaQuery/device branch).
      for (final _ in ['phone', 'tablet', 'desktop']) {
        expect(
          PosCustomersOrdersReturnsVisibility.canAccessOnlineOrders(p),
          isTrue,
        );
        expect(
          PosCustomersOrdersReturnsVisibility.canStartOnlineFulfilment(p),
          isTrue,
        );
      }
    });
  });
}

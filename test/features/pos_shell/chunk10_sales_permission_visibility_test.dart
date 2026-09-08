import 'package:flutter_test/flutter_test.dart';
import 'package:nytroz_pos/core/access/effective_permission_set.dart';
import 'package:nytroz_pos/core/access/pos_access_codes.dart';
import 'package:nytroz_pos/core/access/pos_permission_access.dart';
import 'package:nytroz_pos/features/pos_shell/presentation/widgets/common/pos_shell_bottom_nav_destinations.dart';

void main() {
  group('Part 0 Orders mapping', () {
    test('Orders destination uses receipt history permissions', () {
      final orders = posCashierNavAllDestinations()
          .singleWhere((d) => d.id == PosCashierNavDestinationId.orders);
      expect(orders.route, '/pos/orders');
      expect(orders.label, 'Orders');

      final receiptOnly = EffectivePermissionSet.fromIterable([
        PosPermissionCodes.shellBottomNavContainer,
        PosPermissionCodes.receiptsDigitalView,
      ]);
      expect(orders.isPermitted(receiptOnly), isTrue);

      final onlineOnly = EffectivePermissionSet.fromIterable([
        PosPermissionCodes.shellBottomNavContainer,
        PosPermissionCodes.accessOnlineOrders,
        PosPermissionCodes.viewOnlineOrders,
      ]);
      expect(orders.isPermitted(onlineOnly), isFalse);
    });
  });

  group('Home action permission keys', () {
    test('Returns-only effective set grants returns entry only', () {
      final granted = {
        PosPermissionCodes.homeActionsReturnsEntry,
      };
      expect(
        PosPermissionAccess.grantsCanonicalPermission(
          granted,
          PosPermissionCodes.homeActionsReturnsEntry,
        ),
        isTrue,
      );
      expect(
        PosPermissionAccess.grantsCanonicalPermission(
          granted,
          PosPermissionCodes.salesNewSaleView,
        ),
        isFalse,
      );
      expect(
        PosPermissionAccess.grantsCanonicalPermission(
          granted,
          PosPermissionCodes.cashDrawerPositionView,
        ),
        isFalse,
      );
      expect(
        PosPermissionAccess.grantsCanonicalPermission(
          granted,
          PosPermissionCodes.homeActionsOnlineOrdersEntry,
        ),
        isFalse,
      );
      expect(
        PosPermissionAccess.grantsCanonicalPermission(
          granted,
          PosPermissionCodes.heldSalesView,
        ),
        isFalse,
      );
      expect(
        PosPermissionAccess.grantsCanonicalPermission(
          granted,
          PosPermissionCodes.tillSessionClose,
        ),
        isFalse,
      );
    });

    test('Online Orders home chrome requires entry child exactly', () {
      final parentOnly = {
        PosPermissionCodes.accessOnlineOrders,
        PosPermissionCodes.viewOnlineOrders,
      };
      expect(
        PosPermissionAccess.grantsCanonicalPermission(
          parentOnly,
          PosPermissionCodes.homeActionsOnlineOrdersEntry,
        ),
        isFalse,
      );
      expect(
        PosPermissionAccess.grantsCanonicalPermission(
          {PosPermissionCodes.homeActionsOnlineOrdersEntry},
          PosPermissionCodes.homeActionsOnlineOrdersEntry,
        ),
        isTrue,
      );
    });
  });

  group('Held sale cancel/recall independence', () {
    test('create alone does not grant cancel', () {
      final granted = {PosPermissionCodes.heldSalesCreate};
      expect(
        PosPermissionAccess.grantsCanonicalPermission(
          granted,
          PosPermissionCodes.heldSalesCancel,
        ),
        isFalse,
      );
    });

    test('view alone does not grant recall', () {
      final granted = {PosPermissionCodes.heldSalesView};
      expect(
        PosPermissionAccess.grantsCanonicalPermission(
          granted,
          PosPermissionCodes.heldSalesRecall,
        ),
        isFalse,
      );
    });

    test('exact cancel/recall membership', () {
      expect(
        PosPermissionAccess.grantsCanonicalPermission(
          {PosPermissionCodes.heldSalesCancel},
          PosPermissionCodes.heldSalesCancel,
        ),
        isTrue,
      );
      expect(
        PosPermissionAccess.grantsCanonicalPermission(
          {PosPermissionCodes.heldSalesRecall},
          PosPermissionCodes.heldSalesRecall,
        ),
        isTrue,
      );
    });
  });

  group('Search / catalog helpers', () {
    test('canonical catalog search codes accepted', () {
      expect(
        PosPermissionAccess.canSearchProducts({
          PosPermissionCodes.catalogSearchBar,
        }),
        isTrue,
      );
      expect(
        PosPermissionAccess.canViewProducts({
          PosPermissionCodes.salesCatalogView,
        }),
        isTrue,
      );
    });
  });
}

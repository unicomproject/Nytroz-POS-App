import 'package:flutter_test/flutter_test.dart';
import 'package:nytroz_pos/core/access/pos_access_codes.dart';
import 'package:nytroz_pos/core/access/pos_permission_access.dart';
import 'package:nytroz_pos/features/auth/domain/entities/auth_session.dart';

void main() {
  group('POS new sale access', () {
    test('accepts canonical and sales.create alias only', () {
      expect(
        PosPermissionAccess.canAccessNewSale({PosPermissionCodes.viewNewSale}),
        isTrue,
      );
      expect(
        PosPermissionAccess.canAccessNewSale({PosPermissionCodes.createSale}),
        isTrue,
      );
      expect(
        PosPermissionAccess.canAccessNewSale({'pos.sale.create'}),
        isFalse,
      );
      expect(
        PosPermissionAccess.canAccessNewSale({PosPermissionCodes.startSale}),
        isFalse,
      );
    });
  });

  group('POS home access', () {
    test('accepts canonical home and dashboard alias only', () {
      expect(
        PosPermissionAccess.canViewHome({PosPermissionCodes.viewHome}),
        isTrue,
      );
      expect(
        PosPermissionAccess.canViewHome({PosPermissionCodes.viewDashboard}),
        isTrue,
      );
      expect(
        PosPermissionAccess.canViewHome({'pos.sale.create'}),
        isFalse,
      );
    });
  });

  group('POS home quick actions', () {
    test('add customer requires create permission key', () {
      expect(
        PosPermissionAccess.grantsCanonicalPermission(
          {PosPermissionCodes.viewNewSaleCustomers},
          PosPermissionCodes.createNewSaleCustomer,
        ),
        isFalse,
      );
      expect(
        PosPermissionAccess.grantsCanonicalPermission(
          {PosPermissionCodes.createNewSaleCustomer},
          PosPermissionCodes.createNewSaleCustomer,
        ),
        isTrue,
      );
    });

    test('cash drawer view is separate from manage', () {
      expect(
        PosPermissionAccess.canViewCashDrawer(
            {PosPermissionCodes.viewCashDrawer}),
        isTrue,
      );
      expect(
        PosPermissionAccess.canViewCashDrawer({
          PosPermissionCodes.manageCashDrawer,
        }),
        isFalse,
      );
      expect(
        PosPermissionAccess.canCreateCashDrawerMovement({
          PosPermissionCodes.createCashDrawerMovement,
        }),
        isTrue,
      );
      expect(
        PosPermissionAccess.canCreateCashDrawerMovement({
          PosPermissionCodes.manageCashDrawer,
        }),
        isFalse,
      );
      expect(
        PosPermissionAccess.canCloseTill({
          PosPermissionCodes.manageCashDrawer,
        }),
        isFalse,
      );
      expect(
        PosPermissionAccess.canCloseTill({
          PosPermissionCodes.closeTill,
        }),
        isTrue,
      );
    });
  });

  group('POS payment permissions', () {
    test('payment method screen requires sales.checkout', () {
      expect(
        PosPermissionAccess.canCheckout({PosPermissionCodes.checkoutSale}),
        isTrue,
      );
      expect(
        PosPermissionAccess.canCheckout({PosPermissionCodes.acceptCashPayment}),
        isFalse,
      );
    });

    test('each payment method requires its own permission', () {
      expect(
        PosPermissionAccess.canContinueWithPaymentPermission(
          {
            PosPermissionCodes.checkoutSale,
            PosPermissionCodes.acceptCashPayment,
          },
          PosPermissionCodes.acceptCashPayment,
        ),
        isTrue,
      );
      expect(
        PosPermissionAccess.canContinueWithPaymentPermission(
          {
            PosPermissionCodes.checkoutSale,
            PosPermissionCodes.acceptCashPayment,
          },
          PosPermissionCodes.acceptCardPayment,
        ),
        isFalse,
      );
      expect(
        PosPermissionAccess.canContinueWithPaymentPermission(
          {
            PosPermissionCodes.checkoutSale,
            PosPermissionCodes.acceptQrPayment,
          },
          PosPermissionCodes.acceptQrPayment,
        ),
        isTrue,
      );
      expect(
        PosPermissionAccess.canContinueWithPaymentPermission(
          {
            PosPermissionCodes.checkoutSale,
            PosPermissionCodes.acceptSplitPayment,
          },
          PosPermissionCodes.acceptSplitPayment,
        ),
        isTrue,
      );
    });
  });

  group('POS payment success permissions', () {
    AuthSession sessionWith(Set<String> codes) => AuthSession(
          accessToken: 'token',
          userId: 'cashier',
          userDisplayName: 'Cashier',
          permissionCodes: codes.toList(growable: false),
        );

    test('success route allows sales.view, receipts.view, or receipts.print',
        () {
      expect(
        PosPermissionAccess.canViewPaymentSuccessSession(
          sessionWith({PosPermissionCodes.viewSales}),
        ),
        isTrue,
      );
      expect(
        PosPermissionAccess.canViewPaymentSuccessSession(
          sessionWith({PosPermissionCodes.viewReceipts}),
        ),
        isTrue,
      );
      expect(
        PosPermissionAccess.canViewPaymentSuccessSession(
          sessionWith({PosPermissionCodes.printReceipts}),
        ),
        isTrue,
      );
      expect(
        PosPermissionAccess.canViewPaymentSuccessSession(
          sessionWith({PosPermissionCodes.checkoutSale}),
        ),
        isFalse,
      );
    });
  });
}

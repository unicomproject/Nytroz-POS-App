import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/access/pos_permission_access.dart';
import '../auth/domain/entities/auth_session.dart';
import '../auth/presentation/providers/session_provider.dart';
import '../cash_drawer/presentation/screens/pos_cash_drawer_screen.dart';
import '../cash_drawer/presentation/screens/pos_cash_drop_screen.dart';
import '../cash_drawer/presentation/screens/pos_cash_in_screen.dart';
import '../cash_drawer/presentation/screens/pos_close_till_screen.dart';
import '../returns_refunds/presentation/screens/pos_return_create_credit_screen.dart';
import '../returns_refunds/presentation/screens/pos_return_receipt_screen.dart';
import '../returns_refunds/presentation/screens/pos_return_settlement_screen.dart';
import '../returns_refunds/presentation/screens/pos_return_eligibility_screen.dart';
import '../returns_refunds/presentation/screens/pos_return_reason_screen.dart';
import '../returns_refunds/presentation/screens/pos_return_search_sale_screen.dart';
import '../sale/presentation/screens/pos_cash_payment_success_screen.dart';
import '../sale/presentation/screens/pos_cash_payment_screen.dart';
import '../sale/presentation/screens/pos_email_receipt_screen.dart';
import '../sale/presentation/screens/pos_print_receipt_screen.dart';
import '../sale/presentation/screens/pos_new_sale_screen.dart';
import '../sale/presentation/screens/pos_payment_method_screen.dart';
import '../sale/presentation/screens/pos_payment_placeholder_screen.dart';
import '../tenant_admin/presentation/screens/tenant_admin_forbidden_screen.dart';
import 'presentation/screens/pos_home_screen.dart';
import 'presentation/screens/pos_placeholder_screen.dart';
import 'presentation/widgets/common/pos_shell_scaffold.dart';

List<RouteBase> posShellRoutes(Ref ref) {
  return [
    ShellRoute(
      builder: (context, state, child) {
        final header = _headerForPath(state.uri.path);
        return PosShellScaffold(
          title: header.title,
          subtitle: header.subtitle,
          showTopBar: shouldShowPosTopBar(state.uri.path),
          child: child,
        );
      },
      routes: [
        GoRoute(
          path: '/pos/home',
          builder: (context, state) =>
              _canViewPosHome(ref.read(authSessionProvider))
                  ? const PosHomeScreen()
                  : const TenantAdminForbiddenScreen(),
        ),
        GoRoute(
          path: '/pos/new-sale',
          builder: (context, state) =>
              _canStartNewSale(ref.read(authSessionProvider))
                  ? const PosNewSaleScreen()
                  : const TenantAdminForbiddenScreen(),
          routes: [
            GoRoute(
              path: 'payment',
              builder: (context, state) =>
                  _canProceedToPayment(ref.read(authSessionProvider))
                      ? const PosPaymentMethodScreen()
                      : const TenantAdminForbiddenScreen(),
              routes: [
                GoRoute(
                  path: 'cash',
                  builder: (context, state) =>
                      _canAcceptCashPayment(ref.read(authSessionProvider))
                          ? const PosCashPaymentScreen()
                          : const TenantAdminForbiddenScreen(),
                  routes: [
                    GoRoute(
                      path: 'success',
                      builder: (context, state) =>
                          _canViewPaymentSuccess(ref.read(authSessionProvider))
                              ? const PosCashPaymentSuccessScreen()
                              : const TenantAdminForbiddenScreen(),
                      routes: [
                        GoRoute(
                          path: 'print-receipt',
                          builder: (context, state) =>
                              _canPrintReceipt(ref.read(authSessionProvider))
                                  ? const PosPrintReceiptScreen()
                                  : const TenantAdminForbiddenScreen(),
                        ),
                        GoRoute(
                          path: 'email-receipt',
                          builder: (context, state) =>
                              _canViewReceipt(ref.read(authSessionProvider))
                                  ? const PosEmailReceiptScreen()
                                  : const TenantAdminForbiddenScreen(),
                        ),
                      ],
                    ),
                  ],
                ),
                GoRoute(
                  path: 'card',
                  builder: (context, state) =>
                      _canAcceptCardPayment(ref.read(authSessionProvider))
                          ? const PosPaymentPlaceholderScreen(
                              title: 'Card Payment',
                              subtitle: 'Accept card payment from customer',
                            )
                          : const TenantAdminForbiddenScreen(),
                ),
                GoRoute(
                  path: 'qr',
                  builder: (context, state) =>
                      _canAcceptQrPayment(ref.read(authSessionProvider))
                          ? const PosPaymentPlaceholderScreen(
                              title: 'QR / Mobile Payment',
                              subtitle:
                                  'Accept QR or mobile payment from customer',
                            )
                          : const TenantAdminForbiddenScreen(),
                ),
                GoRoute(
                  path: 'split',
                  builder: (context, state) =>
                      _canAcceptSplitPayment(ref.read(authSessionProvider))
                          ? const PosPaymentPlaceholderScreen(
                              title: 'Split Payment',
                              subtitle: 'Accept split payment from customer',
                            )
                          : const TenantAdminForbiddenScreen(),
                ),
              ],
            ),
          ],
        ),
        GoRoute(
          path: '/pos/customers',
          builder: (context, state) =>
              _canViewCustomers(ref.read(authSessionProvider))
                  ? const PosPlaceholderScreen(title: 'Customers')
                  : const TenantAdminForbiddenScreen(),
        ),
        GoRoute(
          path: '/pos/returns-refunds',
          builder: (context, state) =>
              _canViewReturnsRefunds(ref.read(authSessionProvider))
                  ? const PosReturnSearchSaleScreen()
                  : const TenantAdminForbiddenScreen(),
          routes: [
            GoRoute(
              path: 'eligibility',
              builder: (context, state) =>
                  _canViewReturnsRefunds(ref.read(authSessionProvider))
                      ? const PosReturnEligibilityScreen()
                      : const TenantAdminForbiddenScreen(),
            ),
            GoRoute(
              path: 'return-reason',
              builder: (context, state) =>
                  _canViewReturnsRefunds(ref.read(authSessionProvider))
                      ? const PosReturnReasonScreen()
                      : const TenantAdminForbiddenScreen(),
            ),
            GoRoute(
              path: 'create-credit',
              builder: (context, state) =>
                  _canViewReturnsRefunds(ref.read(authSessionProvider))
                      ? const PosReturnCreateCreditScreen()
                      : const TenantAdminForbiddenScreen(),
            ),
            GoRoute(
              path: 'settlement',
              builder: (context, state) =>
                  _canViewReturnsRefunds(ref.read(authSessionProvider))
                      ? const PosReturnSettlementScreen()
                      : const TenantAdminForbiddenScreen(),
            ),
            GoRoute(
              path: 'receipt',
              builder: (context, state) =>
                  _canViewReturnsRefunds(ref.read(authSessionProvider))
                      ? const PosReturnReceiptScreen()
                      : const TenantAdminForbiddenScreen(),
            ),
          ],
        ),
        GoRoute(
          path: '/pos/parked-sales',
          builder: (context, state) =>
              _canViewParkedSales(ref.read(authSessionProvider))
                  ? const PosPlaceholderScreen(title: 'Parked Sales')
                  : const TenantAdminForbiddenScreen(),
        ),
        GoRoute(
          path: '/pos/cash-drawer',
          builder: (context, state) =>
              _canViewCashDrawer(ref.read(authSessionProvider))
                  ? const PosCashDrawerScreen()
                  : const TenantAdminForbiddenScreen(),
          routes: [
            GoRoute(
              path: 'cash-in',
              builder: (context, state) =>
                  _canCreateCashDrawerMovement(ref.read(authSessionProvider))
                      ? const PosCashInScreen()
                      : const TenantAdminForbiddenScreen(),
            ),
            GoRoute(
              path: 'cash-drop',
              builder: (context, state) =>
                  _canCreateCashDrawerMovement(ref.read(authSessionProvider))
                      ? const PosCashDropScreen()
                      : const TenantAdminForbiddenScreen(),
            ),
            GoRoute(
              path: 'close-till',
              builder: (context, state) =>
                  _canCloseTill(ref.read(authSessionProvider))
                      ? const PosCloseTillScreen()
                      : const TenantAdminForbiddenScreen(),
            ),
          ],
        ),
        GoRoute(
          path: '/pos/profile',
          builder: (context, state) =>
              _isAuthenticated(ref.read(authSessionProvider))
                  ? const PosPlaceholderScreen(title: 'Profile')
                  : const TenantAdminForbiddenScreen(),
        ),
      ],
    ),
  ];
}

bool shouldShowPosTopBar(String path) {
  if (path == '/pos/home' || path.startsWith('/pos/home/')) {
    return false;
  }

  if (path == '/pos/new-sale/payment' ||
      path.startsWith('/pos/new-sale/payment/')) {
    return false;
  }

  return true;
}

_PosShellHeader _headerForPath(String path) {
  final title = switch (path) {
    '/pos/home' => 'Home',
    '/pos/new-sale' => 'New Sale',
    '/pos/new-sale/payment' => 'Payment Method',
    '/pos/new-sale/payment/cash' => 'Cash Payment',
    '/pos/new-sale/payment/cash/success' => 'Cash Payment',
    '/pos/new-sale/payment/cash/success/print-receipt' => 'Print Receipt',
    '/pos/new-sale/payment/cash/success/email-receipt' => 'Email Receipt',
    '/pos/new-sale/payment/card' => 'Card Payment',
    '/pos/new-sale/payment/qr' => 'QR / Mobile Payment',
    '/pos/new-sale/payment/split' => 'Split Payment',
    '/pos/orders' => 'Orders',
    '/pos/customers' => 'Customers',
    '/pos/returns-refunds' => 'Return & Refund',
    '/pos/returns-refunds/eligibility' => 'Eligibility & Select Items',
    '/pos/returns-refunds/return-reason' => 'Return Reason',
    '/pos/returns-refunds/create-credit' => 'Create Credit',
    '/pos/returns-refunds/settlement' => 'Settlement',
    '/pos/returns-refunds/receipt' => 'Receipt',
    '/pos/cash-drawer' => 'Cash Drawer',
    '/pos/cash-drawer/cash-in' => 'Cash In',
    '/pos/cash-drawer/cash-drop' => 'Cash Drop',
    '/pos/cash-drawer/close-till' => 'Close Till',
    '/pos/profile' => 'Profile',
    _ => 'Home',
  };

  final subtitle = switch (path) {
    '/pos/cash-drawer' =>
      'Monitor the till cash position and perform drawer actions.',
    '/pos/cash-drawer/cash-in' =>
      'Add extra cash or float to the current till drawer.',
    '/pos/cash-drawer/cash-drop' =>
      'Record a safe drop from the drawer and reduce the till cash balance.',
    '/pos/cash-drawer/close-till' =>
      'Count the cash in the drawer and close the till.',
    '/pos/returns-refunds' =>
      'Find and select the original sale to begin the return or refund.',
    '/pos/returns-refunds/eligibility' =>
      'Review return eligibility and select items to return.',
    '/pos/returns-refunds/return-reason' =>
      'Capture the reason for each item being returned.',
    '/pos/returns-refunds/create-credit' =>
      'Review credit amounts and confirm the return credit.',
    '/pos/returns-refunds/settlement' =>
      'Select how the customer credit should be settled.',
    '/pos/returns-refunds/receipt' => 'Review and print the return receipt.',
    _ => 'Ready for sales, service, and till operations.',
  };

  return _PosShellHeader(
    title: title,
    subtitle: subtitle,
  );
}

class _PosShellHeader {
  const _PosShellHeader({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;
}

bool _canViewPosHome(AuthSession? session) {
  return PosPermissionAccess.canViewHomeSession(session);
}

/// New Sale uses [PosPermissionAccess.canAccessNewSaleSession] only.
/// Parent POS home routes still require POS home/dashboard access.
bool _canStartNewSale(AuthSession? session) {
  return PosPermissionAccess.canAccessNewSaleSession(session);
}

bool _canProceedToPayment(AuthSession? session) {
  return _canStartNewSale(session) &&
      PosPermissionAccess.canCheckoutSession(session);
}

bool _canAcceptCashPayment(AuthSession? session) {
  return _canStartNewSale(session) &&
      PosPermissionAccess.canAccessCashPaymentScreenSession(session);
}

bool _canAcceptCardPayment(AuthSession? session) {
  return _canStartNewSale(session) &&
      PosPermissionAccess.canAccessCardPaymentScreenSession(session);
}

bool _canAcceptQrPayment(AuthSession? session) {
  return _canStartNewSale(session) &&
      PosPermissionAccess.canAccessQrPaymentScreenSession(session);
}

bool _canAcceptSplitPayment(AuthSession? session) {
  return _canStartNewSale(session) &&
      PosPermissionAccess.canAccessSplitPaymentScreenSession(session);
}

bool _canViewPaymentSuccess(AuthSession? session) {
  return PosPermissionAccess.canViewPaymentSuccessSession(session);
}

bool _canViewReceipt(AuthSession? session) {
  return PosPermissionAccess.canViewReceiptSession(session);
}

bool _canPrintReceipt(AuthSession? session) {
  return PosPermissionAccess.canPrintReceiptsSession(session);
}

bool _canViewCustomers(AuthSession? session) {
  return _canViewPosHome(session) &&
      PosPermissionAccess.canViewCustomers(
        session?.permissionCodes.toSet() ?? const {},
      );
}

bool _canViewReturnsRefunds(AuthSession? session) {
  return _canViewPosHome(session) &&
      PosPermissionAccess.canViewReturnsOrRefunds(
        session?.permissionCodes.toSet() ?? const {},
      );
}

bool _canViewCashDrawer(AuthSession? session) {
  return _canViewPosHome(session) &&
      PosPermissionAccess.canViewCashDrawer(
        session?.permissionCodes.toSet() ?? const {},
      );
}

bool _canCreateCashDrawerMovement(AuthSession? session) {
  return _canViewCashDrawer(session) &&
      PosPermissionAccess.canCreateCashDrawerMovement(
        session?.permissionCodes.toSet() ?? const {},
      );
}

bool _canCloseTill(AuthSession? session) {
  return _isAuthenticated(session) &&
      PosPermissionAccess.canCloseTill(
          session?.permissionCodes.toSet() ?? const {});
}

bool _canViewParkedSales(AuthSession? session) {
  return _canViewPosHome(session) &&
      PosPermissionAccess.canParkOrViewParkedSales(
        session?.permissionCodes.toSet() ?? const {},
      );
}

bool _isAuthenticated(AuthSession? session) {
  return session != null && session.isAuthenticated;
}

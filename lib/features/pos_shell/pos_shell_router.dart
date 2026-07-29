import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/access/pos_access_codes.dart';
import '../../core/access/pos_permission_access.dart';
import '../auth/domain/entities/auth_session.dart';
import '../auth/presentation/providers/session_provider.dart';
import '../cash_drawer/presentation/screens/pos_cash_drawer_screen.dart';
import '../cash_drawer/presentation/screens/pos_cash_drop_screen.dart';
import '../cash_drawer/presentation/screens/pos_cash_in_screen.dart';
import '../cash_drawer/presentation/screens/pos_close_till_screen.dart';
import '../customers/presentation/screens/pos_customers_screen.dart';
import '../hardware/receipt_printer/presentation/screens/pos_hardware_testing_screen.dart';
import '../returns_refunds/presentation/navigation/returns_route_guard.dart';
import '../receipts/presentation/screens/pos_receipt_history_screen.dart';
import '../returns_refunds/presentation/screens/pos_return_create_credit_screen.dart';
import '../returns_refunds/presentation/screens/pos_return_receipt_screen.dart';
import '../returns_refunds/presentation/screens/pos_return_sale_summary_screen.dart';
import '../returns_refunds/presentation/screens/pos_return_settlement_screen.dart';
import '../returns_refunds/presentation/screens/pos_return_check_eligibility_screen.dart';
import '../returns_refunds/presentation/screens/pos_return_eligibility_screen.dart';
import '../returns_refunds/presentation/screens/pos_return_refund_details_screen.dart';
import '../returns_refunds/presentation/screens/pos_return_choose_option_screen.dart';
import '../returns_refunds/presentation/screens/pos_return_exchange_flow_screen.dart';
import '../returns_refunds/presentation/screens/pos_return_inspect_items_screen.dart';
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
          showTopBarSearch: shouldShowPosTopBarSearch(state.uri.path),
          showSidebar: state.uri.path != '/pos/home' &&
              state.uri.path != '/pos/new-sale' &&
              !state.uri.path.startsWith('/pos/home/'),
          showBottomNavigation: shouldShowPosCashierBottomNavigation(
            state.uri.path,
            ref.read(authSessionProvider),
          ),
          isNewSale: state.uri.path == '/pos/new-sale',
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
                              unavailableMessage:
                                  'No supported card provider or terminal is configured. '
                                  'No charge was initiated. Choose another payment method '
                                  'or contact a manager.',
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
                  ? const PosCustomersScreen()
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
              path: 'summary',
              builder: (context, state) => _canAccessReturnsPath(
                ref.read(authSessionProvider),
                '/pos/returns-refunds/summary',
              )
                  ? const PosReturnSaleSummaryScreen()
                  : const TenantAdminForbiddenScreen(),
            ),
            GoRoute(
              path: 'eligibility',
              builder: (context, state) => _canAccessReturnsPath(
                ref.read(authSessionProvider),
                '/pos/returns-refunds/eligibility',
              )
                  ? const PosReturnEligibilityScreen()
                  : const TenantAdminForbiddenScreen(),
            ),
            GoRoute(
              path: 'check-eligibility',
              builder: (context, state) => _canAccessReturnsPath(
                ref.read(authSessionProvider),
                '/pos/returns-refunds/check-eligibility',
              )
                  ? const PosReturnCheckEligibilityScreen()
                  : const TenantAdminForbiddenScreen(),
            ),
            GoRoute(
              path: 'return-reason',
              builder: (context, state) => _canAccessReturnsPath(
                ref.read(authSessionProvider),
                '/pos/returns-refunds/return-reason',
              )
                  ? const PosReturnReasonScreen()
                  : const TenantAdminForbiddenScreen(),
            ),
            GoRoute(
              path: 'inspect-items',
              builder: (context, state) => _canAccessReturnsPath(
                ref.read(authSessionProvider),
                '/pos/returns-refunds/inspect-items',
              )
                  ? const PosReturnInspectItemsScreen()
                  : const TenantAdminForbiddenScreen(),
            ),
            GoRoute(
              path: 'choose-option',
              builder: (context, state) => _canAccessReturnsPath(
                ref.read(authSessionProvider),
                '/pos/returns-refunds/choose-option',
              )
                  ? const PosReturnChooseOptionScreen()
                  : const TenantAdminForbiddenScreen(),
            ),
            GoRoute(
              path: 'refund-details',
              builder: (context, state) => _canAccessReturnsPath(
                ref.read(authSessionProvider),
                '/pos/returns-refunds/refund-details',
              )
                  ? const PosReturnRefundDetailsScreen()
                  : const TenantAdminForbiddenScreen(),
            ),
            GoRoute(
              path: 'create-credit',
              builder: (context, state) => _canAccessReturnsPath(
                ref.read(authSessionProvider),
                '/pos/returns-refunds/create-credit',
              )
                  ? const PosReturnCreateCreditScreen()
                  : const TenantAdminForbiddenScreen(),
            ),
            GoRoute(
              path: 'exchange',
              builder: (context, state) => _canAccessReturnsPath(
                ref.read(authSessionProvider),
                '/pos/returns-refunds/exchange',
              )
                  ? const PosReturnExchangeFlowScreen()
                  : const TenantAdminForbiddenScreen(),
            ),
            GoRoute(
              path: 'settlement',
              builder: (context, state) => _canAccessReturnsPath(
                ref.read(authSessionProvider),
                '/pos/returns-refunds/settlement',
              )
                  ? const PosReturnSettlementScreen()
                  : const TenantAdminForbiddenScreen(),
            ),
            GoRoute(
              path: 'receipt',
              builder: (context, state) => _canAccessReturnsPath(
                ref.read(authSessionProvider),
                '/pos/returns-refunds/receipt',
              )
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
          path: '/pos/online-orders',
          builder: (context, state) =>
              _isAuthenticated(ref.read(authSessionProvider))
                  ? const PosPlaceholderScreen(title: 'Online Orders')
                  : const TenantAdminForbiddenScreen(),
        ),
        GoRoute(
          path: '/pos/orders',
          builder: (context, state) =>
              ref.read(authSessionProvider)?.hasPermission(
                            PosPermissionCodes.viewReceipts,
                          ) ==
                      true
                  ? const PosReceiptHistoryScreen()
                  : const TenantAdminForbiddenScreen(),
        ),
        GoRoute(
          path: '/pos/settings',
          builder: (context, state) => ref
                      .read(authSessionProvider)
                      ?.hasPermission(PosPermissionCodes.hardwareSettings) ==
                  true
              ? const PosHardwareTestingScreen()
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

  if (path == '/pos/customers') {
    return false;
  }

  if (path.startsWith('/pos/returns-refunds')) {
    return false;
  }

  if (path == '/pos/new-sale/payment' ||
      path.startsWith('/pos/new-sale/payment/')) {
    return false;
  }

  return true;
}

bool shouldShowPosTopBarSearch(String path) {
  return !path.startsWith('/pos/returns-refunds');
}

bool shouldShowPosCashierBottomNavigation(
  String path,
  AuthSession? session,
) {
  return switch (path) {
    '/pos/home' => _canViewPosHome(session),
    '/pos/new-sale' => _canStartNewSale(session),
    '/pos/customers' => _canViewCustomers(session),
    '/pos/orders' =>
      session?.hasPermission(PosPermissionCodes.viewReceipts) == true,
    _ => false,
  };
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
    '/pos/returns-refunds' => 'Returns & Exchanges',
    '/pos/returns-refunds/summary' => 'Original Sale Summary',
    '/pos/returns-refunds/eligibility' => 'Select Items',
    '/pos/returns-refunds/check-eligibility' => 'Check Eligibility',
    '/pos/returns-refunds/return-reason' => 'Return Reason',
    '/pos/returns-refunds/inspect-items' => 'Inspect Items',
    '/pos/returns-refunds/choose-option' => 'Choose Option',
    '/pos/returns-refunds/refund-details' => 'Refund Details',
    '/pos/returns-refunds/create-credit' => 'Refund Flow',
    '/pos/returns-refunds/exchange' => 'Exchange Flow',
    '/pos/returns-refunds/settlement' => 'Review & Confirm',
    '/pos/returns-refunds/receipt' => 'Receipt / Success',
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
      'Find and select the original sale to begin the return or exchange.',
    '/pos/returns-refunds/summary' =>
      'Review the original sale details and purchased items.',
    '/pos/returns-refunds/eligibility' =>
      'Choose the items and quantities to include in the return or exchange.',
    '/pos/returns-refunds/check-eligibility' =>
      'Validate return eligibility based on policy rules.',
    '/pos/returns-refunds/return-reason' =>
      'Choose the reason for the return or exchange and capture notes if needed.',
    '/pos/returns-refunds/inspect-items' =>
      'Inspect the condition of each selected item and add notes or photos if needed.',
    '/pos/returns-refunds/choose-option' =>
      'Choose whether the customer wants a Refund or Exchange.',
    '/pos/returns-refunds/refund-details' =>
      'Select the refund method and confirm the refund.',
    '/pos/returns-refunds/create-credit' =>
      'Review refund credit calculation and confirm the return credit.',
    '/pos/returns-refunds/exchange' =>
      'Select replacement products and complete the exchange.',
    '/pos/returns-refunds/settlement' =>
      'Review the return details and complete the process.',
    '/pos/returns-refunds/receipt' =>
      'Return or exchange completed successfully.',
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
  return ReturnsRouteGuard.canAccessPath(session, '/pos/returns-refunds');
}

bool _canAccessReturnsPath(AuthSession? session, String path) {
  return ReturnsRouteGuard.canAccessPath(session, path);
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

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/access/pos_access_codes.dart';
import '../auth/domain/entities/auth_session.dart';
import '../auth/presentation/providers/session_provider.dart';
import '../sale/presentation/screens/pos_new_sale_screen.dart';
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
                  ? const PosPlaceholderScreen(title: 'Return & Refund')
                  : const TenantAdminForbiddenScreen(),
        ),
        GoRoute(
          path: '/pos/parked-sales',
          builder: (context, state) =>
              _canViewPosHome(ref.read(authSessionProvider))
                  ? const PosPlaceholderScreen(title: 'Parked Sales')
                  : const TenantAdminForbiddenScreen(),
        ),
        GoRoute(
          path: '/pos/cash-drawer',
          builder: (context, state) =>
              _canViewCashDrawer(ref.read(authSessionProvider))
                  ? const PosPlaceholderScreen(title: 'Cash Drawer')
                  : const TenantAdminForbiddenScreen(),
        ),
        GoRoute(
          path: '/pos/profile',
          builder: (context, state) =>
              _canViewPosHome(ref.read(authSessionProvider))
                  ? const PosPlaceholderScreen(title: 'Profile')
                  : const TenantAdminForbiddenScreen(),
        ),
      ],
    ),
  ];
}

bool shouldShowPosTopBar(String path) {
  return !(path == '/pos/home' || path.startsWith('/pos/home/'));
}

_PosShellHeader _headerForPath(String path) {
  final title = switch (path) {
    '/pos/home' => 'Home',
    '/pos/new-sale' => 'New Sale',
    '/pos/orders' => 'Orders',
    '/pos/customers' => 'Customers',
    '/pos/returns-refunds' => 'Return & Refund',
    '/pos/cash-drawer' => 'Cash Drawer',
    '/pos/profile' => 'Profile',
    _ => 'Home',
  };

  return _PosShellHeader(
    title: title,
    subtitle: 'Ready for sales, service, and till operations.',
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
  return session?.hasPermission(PosPermissionCodes.viewHome) == true;
}

bool _canStartNewSale(AuthSession? session) {
  return _canViewPosHome(session) &&
      session?.hasPermission(PosPermissionCodes.viewNewSale) == true;
}

bool _canViewCustomers(AuthSession? session) {
  return _canViewPosHome(session) &&
      (session?.hasPermission(PosPermissionCodes.viewNewSaleCustomers) ==
              true ||
          session?.hasPermission(PosPermissionCodes.createNewSaleCustomer) ==
              true);
}

bool _canViewReturnsRefunds(AuthSession? session) {
  return _canViewPosHome(session) &&
      (session?.hasPermission(PosPermissionCodes.viewReturns) == true ||
          session?.hasPermission(PosPermissionCodes.viewRefunds) == true);
}

bool _canViewCashDrawer(AuthSession? session) {
  return _canViewPosHome(session) &&
      session?.hasPermission(PosPermissionCodes.viewCashDrawer) == true;
}

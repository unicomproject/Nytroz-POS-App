import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/access/pos_access_codes.dart';
import '../auth/domain/entities/auth_session.dart';
import '../auth/presentation/providers/session_provider.dart';
import '../tenant_admin/presentation/screens/tenant_admin_forbidden_screen.dart';
import 'presentation/screens/pos_home_screen.dart';
import 'presentation/screens/pos_placeholder_screen.dart';

List<RouteBase> posShellRoutes(Ref ref) {
  return [
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
          _canViewPosHome(ref.read(authSessionProvider))
              ? const PosPlaceholderScreen(title: 'New Sale')
              : const TenantAdminForbiddenScreen(),
    ),
    GoRoute(
      path: '/pos/customers',
      builder: (context, state) =>
          _canViewPosHome(ref.read(authSessionProvider))
              ? const PosPlaceholderScreen(title: 'Customers')
              : const TenantAdminForbiddenScreen(),
    ),
    GoRoute(
      path: '/pos/returns-refunds',
      builder: (context, state) =>
          _canViewPosHome(ref.read(authSessionProvider))
              ? const PosPlaceholderScreen(title: 'Returns & Refunds')
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
          _canViewPosHome(ref.read(authSessionProvider))
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
  ];
}

bool _canViewPosHome(AuthSession? session) {
  return session?.hasPermission(PosPermissionCodes.viewHome) == true;
}

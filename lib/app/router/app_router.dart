import 'package:go_router/go_router.dart';

import '../../features/pos_shell/pos_shell_router.dart';
import '../../features/tenant_admin/tenant_admin_router.dart';
import '../../features/auth/domain/entities/auth_session.dart';
import '../../features/auth/auth_router.dart';

GoRouter createAppRouter(AuthSession? session) {
  return GoRouter(
    initialLocation: '/pos/home',
    routes: [
      ...authRoutes(),
      ...posShellRoutes(),
      ...tenantAdminRoutes(),
    ],
    redirect: (context, state) {
      final path = state.uri.path;
      final isAuthRoute = path == '/tenant-admin/login' ||
          path.startsWith('/tenant-admin/payment') ||
          path.startsWith('/tenant-admin/setup');
      final isTenantAdminRoute = path.startsWith('/tenant-admin');

      if (isTenantAdminRoute && !isAuthRoute && session == null) {
        return '/tenant-admin/login';
      }

      if (path == '/tenant-admin/login' && session != null) {
        return '/tenant-admin/dashboard';
      }

      return null;
    },
  );
}

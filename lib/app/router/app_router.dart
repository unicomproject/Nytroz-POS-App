import 'package:go_router/go_router.dart';

import '../../features/pos_shell/pos_shell_router.dart';
import '../../features/device_activation/device_activation_router.dart';
import '../../features/till/till_router.dart';
import '../../features/tenant_admin/tenant_admin_router.dart';
import '../../features/auth/domain/entities/auth_session.dart';
import '../../features/auth/auth_router.dart';

GoRouter createAppRouter(
  AuthSession? session, {
  String authenticatedInitialRoute = '/pos/device-activation',
}) {
  return GoRouter(
    initialLocation: '/tenant-login',
    routes: [
      ...authRoutes(),
      ...deviceActivationRoutes(session),
      ...tillRoutes(session),
      ...posShellRoutes(session),
      ...tenantAdminRoutes(),
    ],
    redirect: (context, state) {
      final path = state.uri.path;
      final isAuthRoute = path == '/tenant-login' ||
          path.startsWith('/tenant-admin/payment') ||
          path.startsWith('/tenant-admin/setup');
      final isTenantAdminRoute = path.startsWith('/tenant-admin');
      final isProtectedPosRoute = path == '/device-activation' ||
          path == '/open-till' ||
          path == '/till-open' ||
          path.startsWith('/pos/');

      if (isTenantAdminRoute && !isAuthRoute && session == null) {
        return '/tenant-login';
      }

      if (isProtectedPosRoute && session == null) {
        return '/tenant-login';
      }

      if (path == '/tenant-login' && session != null) {
        return authenticatedInitialRoute;
      }

      return null;
    },
  );
}

import 'package:go_router/go_router.dart';

import '../auth/domain/entities/auth_session.dart';
import '../auth/presentation/providers/post_login_navigation_provider.dart';
import '../tenant_admin/presentation/screens/tenant_admin_forbidden_screen.dart';
import 'presentation/screens/device_activation_screen.dart';

List<RouteBase> deviceActivationRoutes(AuthSession? session) {
  return [
    GoRoute(
      path: '/device-activation',
      builder: (context, state) => _canActivateDevice(session)
          ? const DeviceActivationScreen()
          : const TenantAdminForbiddenScreen(),
    ),
    GoRoute(
      path: '/pos/device-activation',
      builder: (context, state) => _canActivateDevice(session)
          ? const DeviceActivationScreen()
          : const TenantAdminForbiddenScreen(),
    ),
  ];
}

bool _canActivateDevice(AuthSession? session) {
  return session?.hasPermission(activateDevicePermissionCode) == true;
}

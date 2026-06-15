import 'package:go_router/go_router.dart';

import '../../core/access/pos_access_codes.dart';
import '../auth/domain/entities/auth_session.dart';
import '../tenant_admin/presentation/screens/tenant_admin_forbidden_screen.dart';
import 'presentation/screens/pos_home_screen.dart';

List<RouteBase> posShellRoutes(AuthSession? session) {
  return [
    GoRoute(
      path: '/pos/home',
      builder: (context, state) => _canViewPosHome(session)
          ? const PosHomeScreen()
          : const TenantAdminForbiddenScreen(),
    ),
  ];
}

bool _canViewPosHome(AuthSession? session) {
  return session?.hasPermission(PosPermissionCodes.viewHome) == true;
}

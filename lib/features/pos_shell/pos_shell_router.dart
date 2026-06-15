import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/access/pos_access_codes.dart';
import '../auth/domain/entities/auth_session.dart';
import '../auth/presentation/providers/session_provider.dart';
import '../tenant_admin/presentation/screens/tenant_admin_forbidden_screen.dart';
import 'presentation/screens/pos_home_screen.dart';

List<RouteBase> posShellRoutes(Ref ref) {
  return [
    GoRoute(
      path: '/pos/home',
      builder: (context, state) => _canViewPosHome(ref.read(authSessionProvider))
          ? const PosHomeScreen()
          : const TenantAdminForbiddenScreen(),
    ),
  ];
}

bool _canViewPosHome(AuthSession? session) {
  return session?.hasPermission(PosPermissionCodes.viewHome) == true;
}

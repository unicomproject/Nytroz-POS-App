import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../auth/domain/entities/auth_session.dart';
import '../auth/presentation/providers/post_login_navigation_provider.dart';
import '../auth/presentation/providers/session_provider.dart';
import '../tenant_admin/presentation/screens/tenant_admin_forbidden_screen.dart';
import 'presentation/screens/till_open_screen.dart';

List<RouteBase> tillRoutes(Ref ref) {
  return [
    GoRoute(
      path: '/open-till',
      builder: (context, state) => _canOpenTill(ref.read(authSessionProvider))
          ? const TillOpenScreen()
          : const TenantAdminForbiddenScreen(),
    ),
    GoRoute(
      path: '/till-open',
      builder: (context, state) => _canOpenTill(ref.read(authSessionProvider))
          ? const TillOpenScreen()
          : const TenantAdminForbiddenScreen(),
    ),
    GoRoute(
      path: '/pos/open-till',
      builder: (context, state) => _canOpenTill(ref.read(authSessionProvider))
          ? const TillOpenScreen()
          : const TenantAdminForbiddenScreen(),
    ),
  ];
}

bool _canOpenTill(AuthSession? session) {
  return session?.hasPermission(openTillPermissionCode) == true;
}

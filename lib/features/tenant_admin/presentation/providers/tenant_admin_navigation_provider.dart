import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'tenant_admin_access_provider.dart';
import 'tenant_admin_menu_provider.dart';

final tenantAdminFirstPermittedRouteProvider = Provider<String?>((ref) {
  final menuState = ref.watch(tenantAdminMenuProvider);

  return menuState.maybeWhen(
    data: (items) => items.isEmpty ? null : items.first.route,
    orElse: () => null,
  );
});

final tenantAdminCanAccessDashboardProvider = Provider<bool>((ref) {
  final accessState = ref.watch(tenantAdminAccessCheckerProvider);

  return accessState.maybeWhen(
    data: (access) => access.canAccessDashboardRoute(),
    orElse: () => false,
  );
});

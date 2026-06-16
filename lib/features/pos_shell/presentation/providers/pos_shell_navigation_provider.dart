import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/session_provider.dart';
import 'pos_home_dashboard_provider.dart';

final posShellGrantedPermissionsProvider = Provider<Set<String>>((ref) {
  final homePermissions =
      ref.watch(posHomeDashboardProvider).valueOrNull?.grantedPermissionKeys;

  if (homePermissions != null) {
    return homePermissions;
  }

  final session = ref.watch(authSessionProvider);
  return session?.permissionCodes.toSet() ?? const {};
});

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/session_provider.dart';

final posShellGrantedPermissionsProvider = Provider<Set<String>>((ref) {
  final session = ref.watch(authSessionProvider);
  return session?.permissionCodes.toSet() ?? const {};
});

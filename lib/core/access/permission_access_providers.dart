import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/presentation/providers/session_provider.dart';
import 'effective_permission_set.dart';

/// Authoritative Flutter effective-permission state.
///
/// Source: [authSessionProvider] → `AuthSession.permissionCodes`
/// (backend Chunk 5 effective set). Fail-closed when session is null.
final effectivePermissionSetProvider = Provider<EffectivePermissionSet>((ref) {
  final session = ref.watch(authSessionProvider);
  if (session == null) {
    return EffectivePermissionSet.empty;
  }
  return EffectivePermissionSet.fromIterable(session.permissionCodes);
});

/// Convenience: exact membership against the current session set.
final permissionMembershipProvider =
    Provider.family<bool, String>((ref, code) {
  return ref.watch(effectivePermissionSetProvider).hasPermission(code);
});

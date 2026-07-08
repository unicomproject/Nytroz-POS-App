import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/services/tenant_admin_access_checker.dart';
import '../../../presentation/providers/tenant_admin_access_provider.dart';
import '../../domain/entities/tenant_user.dart';
import 'tenant_user_providers.dart';

final userListVisibilityProvider =
    Provider<AsyncValue<UserListVisibility>>((ref) {
  final accessState = ref.watch(tenantAdminAccessCheckerProvider);

  return accessState.when(
    loading: () => const AsyncLoading(),
    error: AsyncError.new,
    data: (accessChecker) => AsyncData(
      UserListVisibility.resolve(access: accessChecker),
    ),
  );
});

final userListProvider = FutureProvider.autoDispose<TenantUserListResult?>((
  ref,
) async {
  final accessChecker =
      await ref.watch(tenantAdminAccessCheckerProvider.future);

  if (!accessChecker.canFetchUserList()) {
    return null;
  }

  final query = ref.watch(userListQueryProvider);
  return ref.watch(getUsersProvider).call(query: query);
});

final userCreateAccessProvider = Provider<bool>((ref) {
  final accessState = ref.watch(tenantAdminAccessCheckerProvider);

  return accessState.maybeWhen(
    data: (accessChecker) => accessChecker.canAddUser(),
    orElse: () => false,
  );
});

final userInviteAccessProvider = Provider<bool>((ref) {
  final accessState = ref.watch(tenantAdminAccessCheckerProvider);

  return accessState.maybeWhen(
    data: (accessChecker) => accessChecker.canInviteUser(),
    orElse: () => false,
  );
});

final userPermissionOverrideAccessProvider = Provider<bool>((ref) {
  final accessState = ref.watch(tenantAdminAccessCheckerProvider);

  return accessState.maybeWhen(
    data: (accessChecker) => accessChecker.canOverrideUserPermissions(),
    orElse: () => false,
  );
});

final userUpdateAccessProvider = Provider<bool>((ref) {
  final accessState = ref.watch(tenantAdminAccessCheckerProvider);

  return accessState.maybeWhen(
    data: (accessChecker) => accessChecker.canUpdateUser(),
    orElse: () => false,
  );
});

final userDeleteAccessProvider = Provider<bool>((ref) {
  final accessState = ref.watch(tenantAdminAccessCheckerProvider);

  return accessState.maybeWhen(
    data: (accessChecker) => accessChecker.canDeleteUser(),
    orElse: () => false,
  );
});

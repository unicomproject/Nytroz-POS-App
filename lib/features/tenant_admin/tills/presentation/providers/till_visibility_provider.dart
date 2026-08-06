import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/services/tenant_admin_access_checker.dart';
import '../../../presentation/providers/tenant_admin_access_provider.dart';

final tillListVisibilityProvider =
    Provider<AsyncValue<TillListVisibility>>((ref) {
  final accessState = ref.watch(tenantAdminAccessCheckerProvider);

  return accessState.when(
    loading: () => const AsyncLoading(),
    error: AsyncError.new,
    data: (accessChecker) => AsyncData(
      TillListVisibility.resolve(access: accessChecker),
    ),
  );
});

final tillCreateAccessProvider = Provider<bool>((ref) {
  final accessState = ref.watch(tenantAdminAccessCheckerProvider);

  return accessState.maybeWhen(
    data: (accessChecker) => accessChecker.canCreateTill(),
    orElse: () => false,
  );
});

final tillHardwareViewAccessProvider = Provider<bool>((ref) {
  final accessState = ref.watch(tenantAdminAccessCheckerProvider);

  return accessState.maybeWhen(
    data: (accessChecker) => accessChecker.canViewTillHardware(),
    orElse: () => false,
  );
});

final tillHardwareManageAccessProvider = Provider<bool>((ref) {
  final accessState = ref.watch(tenantAdminAccessCheckerProvider);

  return accessState.maybeWhen(
    data: (accessChecker) => accessChecker.canManageTillHardware(),
    orElse: () => false,
  );
});

final tillUpdateAccessProvider = Provider<bool>((ref) {
  final accessState = ref.watch(tenantAdminAccessCheckerProvider);

  return accessState.maybeWhen(
    data: (accessChecker) => accessChecker.canUpdateTill(),
    orElse: () => false,
  );
});

final tillDeleteAccessProvider = Provider<bool>((ref) {
  final accessState = ref.watch(tenantAdminAccessCheckerProvider);

  return accessState.maybeWhen(
    data: (accessChecker) => accessChecker.canDeleteTill(),
    orElse: () => false,
  );
});

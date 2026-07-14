import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/services/tenant_admin_access_checker.dart';
import '../../../presentation/providers/tenant_admin_access_provider.dart';

final productListVisibilityProvider =
    Provider<AsyncValue<ProductListVisibility>>((ref) {
  final accessState = ref.watch(tenantAdminAccessCheckerProvider);

  return accessState.when(
    loading: () => const AsyncLoading(),
    error: AsyncError.new,
    data: (accessChecker) => AsyncData(
      ProductListVisibility.resolve(access: accessChecker),
    ),
  );
});

final productCreateAccessProvider = Provider<bool>((ref) {
  final accessState = ref.watch(tenantAdminAccessCheckerProvider);

  return accessState.maybeWhen(
    data: (accessChecker) => accessChecker.canCreateProduct(),
    orElse: () => false,
  );
});

final productAddPageAccessProvider = Provider<bool>((ref) {
  final accessState = ref.watch(tenantAdminAccessCheckerProvider);

  return accessState.maybeWhen(
    data: (accessChecker) => accessChecker.canAccessAddProductPage(),
    orElse: () => false,
  );
});

final productDetailPageAccessProvider = Provider<bool>((ref) {
  final accessState = ref.watch(tenantAdminAccessCheckerProvider);

  return accessState.maybeWhen(
    data: (accessChecker) => accessChecker.canAccessProductModule(),
    orElse: () => false,
  );
});

final productUpdateAccessProvider = Provider<bool>((ref) {
  final accessState = ref.watch(tenantAdminAccessCheckerProvider);

  return accessState.maybeWhen(
    data: (accessChecker) => accessChecker.canUpdateProduct(),
    orElse: () => false,
  );
});

final productDeleteAccessProvider = Provider<bool>((ref) {
  final accessState = ref.watch(tenantAdminAccessCheckerProvider);

  return accessState.maybeWhen(
    data: (accessChecker) => accessChecker.canDeleteProduct(),
    orElse: () => false,
  );
});

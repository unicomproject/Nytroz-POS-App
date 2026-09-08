import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/services/tenant_admin_access_checker.dart';
import '../../../presentation/providers/tenant_admin_access_provider.dart';
import '../../domain/entities/category.dart';
import 'category_providers.dart';

final categoryListVisibilityProvider =
    Provider<AsyncValue<CategoryListVisibility>>((ref) {
  final accessState = ref.watch(tenantAdminAccessCheckerProvider);

  return accessState.when(
    loading: () => const AsyncLoading(),
    error: AsyncError.new,
    data: (accessChecker) => AsyncData(
      CategoryListVisibility.resolve(access: accessChecker),
    ),
  );
});

final categoryAddPageAccessProvider = Provider<bool>((ref) {
  final access = ref.watch(tenantAdminAccessCheckerProvider).valueOrNull;
  return access?.canCreateCategory() ?? false;
});

final categoryDetailPageAccessProvider = Provider<bool>((ref) {
  final access = ref.watch(tenantAdminAccessCheckerProvider).valueOrNull;
  if (access == null) {
    return false;
  }

  return access.hasProductCatalogEntitlement() &&
      access.canFetchCategoryList();
});

final categoryUpdateAccessProvider = Provider<bool>((ref) {
  return ref
          .watch(tenantAdminAccessCheckerProvider)
          .valueOrNull
          ?.canUpdateCategory() ??
      false;
});

final categoryDeleteAccessProvider = Provider<bool>((ref) {
  return ref
          .watch(tenantAdminAccessCheckerProvider)
          .valueOrNull
          ?.canDeleteCategory() ??
      false;
});

final categoryListScreenProvider =
    FutureProvider.autoDispose<CategoryListResult?>((ref) async {
  final accessChecker =
      await ref.watch(tenantAdminAccessCheckerProvider.future);

  if (!accessChecker.canFetchCategoryList()) {
    return null;
  }

  return ref.watch(categoryListProvider.future);
});

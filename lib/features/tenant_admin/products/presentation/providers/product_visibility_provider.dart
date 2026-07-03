import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/services/tenant_admin_access_checker.dart';
import '../../../presentation/providers/tenant_admin_access_provider.dart';
import '../../domain/entities/product.dart';
import 'product_providers.dart';

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

final productListProvider = FutureProvider.autoDispose<ProductListResult?>((
  ref,
) async {
  final accessChecker =
      await ref.watch(tenantAdminAccessCheckerProvider.future);

  if (!accessChecker.canFetchProductList()) {
    return null;
  }

  final query = ref.watch(productListQueryProvider);
  return ref.watch(getProductsProvider).call(query: query);
});

final addProductFormVisibilityProvider =
    Provider<AsyncValue<AddProductFormVisibility>>((ref) {
  final accessState = ref.watch(tenantAdminAccessCheckerProvider);

  return accessState.when(
    loading: () => const AsyncLoading(),
    error: AsyncError.new,
    data: (accessChecker) => AsyncData(
      AddProductFormVisibility.resolve(access: accessChecker),
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

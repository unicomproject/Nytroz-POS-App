import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/network/dio_provider.dart';
import '../../../presentation/providers/tenant_admin_access_provider.dart';
import '../../application/usecases/create_product.dart';
import '../../application/usecases/delete_product.dart';
import '../../application/usecases/get_product_by_id.dart';
import '../../application/usecases/get_product_create_options.dart';
import '../../application/usecases/get_product_summary.dart';
import '../../application/usecases/get_products.dart';
import '../../application/usecases/update_product.dart';
import '../../application/usecases/update_product_status.dart';
import '../../data/datasources/tenant_product_remote_datasource.dart';
import '../../data/repositories/tenant_product_repository_impl.dart';
import '../../domain/entities/tenant_product.dart';
import '../../domain/entities/tenant_product_create_options.dart';
import '../../domain/entities/tenant_product_detail.dart';
import '../../domain/repositories/tenant_product_repository.dart';

final tenantProductRemoteDatasourceProvider =
    Provider<TenantProductRemoteDatasource>((ref) {
  return TenantProductRemoteDatasource(ref.watch(appDioProvider));
});

final tenantProductRepositoryProvider = Provider<TenantProductRepository>((ref) {
  return TenantProductRepositoryImpl(ref.watch(tenantProductRemoteDatasourceProvider));
});

final getProductsProvider = Provider<GetProducts>((ref) {
  return GetProducts(ref.watch(tenantProductRepositoryProvider));
});

final getProductSummaryProvider = Provider<GetProductSummary>((ref) {
  return GetProductSummary(ref.watch(tenantProductRepositoryProvider));
});

final getProductCreateOptionsProvider = Provider<GetProductCreateOptions>((ref) {
  return GetProductCreateOptions(ref.watch(tenantProductRepositoryProvider));
});

final createProductProvider = Provider<CreateProduct>((ref) {
  return CreateProduct(ref.watch(tenantProductRepositoryProvider));
});

final getProductByIdProvider = Provider<GetProductById>((ref) {
  return GetProductById(ref.watch(tenantProductRepositoryProvider));
});

final updateProductProvider = Provider<UpdateProduct>((ref) {
  return UpdateProduct(ref.watch(tenantProductRepositoryProvider));
});

final updateProductStatusProvider = Provider<UpdateProductStatus>((ref) {
  return UpdateProductStatus(ref.watch(tenantProductRepositoryProvider));
});

final deleteProductProvider = Provider<DeleteProduct>((ref) {
  return DeleteProduct(ref.watch(tenantProductRepositoryProvider));
});

final productDeletingIdsProvider =
    StateProvider<Set<String>>((ref) => const {});

final productSearchProvider = StateProvider<String>((ref) => '');

final productPageProvider = StateProvider<int>((ref) => 1);

final productPageSizeProvider = StateProvider<int>((ref) => 10);

final productListQueryProvider = Provider<TenantProductListQuery>((ref) {
  final search = ref.watch(productSearchProvider);
  final page = ref.watch(productPageProvider);
  final pageSize = ref.watch(productPageSizeProvider);

  return TenantProductListQuery(
    search: search,
    page: page,
    pageSize: pageSize,
  );
});

final productListProvider = FutureProvider.autoDispose<TenantProductListResult?>((
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

final productSummaryProvider =
    FutureProvider.autoDispose<TenantProductSummary?>((ref) async {
  final accessChecker =
      await ref.watch(tenantAdminAccessCheckerProvider.future);

  if (!accessChecker.canFetchProductSummary()) {
    return null;
  }

  return ref.watch(getProductSummaryProvider).call();
});

final productCreateOptionsProvider =
    FutureProvider.autoDispose<TenantProductCreateOptions?>((ref) async {
  final accessChecker =
      await ref.watch(tenantAdminAccessCheckerProvider.future);

  if (!accessChecker.canAccessAddProductPage()) {
    return null;
  }

  return ref.watch(getProductCreateOptionsProvider).call();
});

final productDetailProvider =
    FutureProvider.autoDispose.family<TenantProductDetail?, String>((
  ref,
  productId,
) async {
  final accessChecker =
      await ref.watch(tenantAdminAccessCheckerProvider.future);

  if (!accessChecker.canAccessProductModule()) {
    return null;
  }

  if (productId.trim().isEmpty) {
    throw StateError('Product id is required.');
  }

  return ref.watch(getProductByIdProvider).call(productId);
});

final productEditCreateOptionsProvider =
    FutureProvider.autoDispose<TenantProductCreateOptions?>((ref) async {
  final accessChecker =
      await ref.watch(tenantAdminAccessCheckerProvider.future);

  if (!accessChecker.canUpdateProduct()) {
    return null;
  }

  return ref.watch(getProductCreateOptionsProvider).call();
});

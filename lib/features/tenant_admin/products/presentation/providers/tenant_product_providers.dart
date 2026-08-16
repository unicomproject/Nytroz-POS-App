import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nytroz_pos/core/storage/secure_storage_provider.dart';

import '../../../../../core/network/dio_provider.dart';
import '../../../presentation/providers/tenant_admin_access_provider.dart';
import '../../application/usecases/create_product.dart';
import '../../application/usecases/delete_product.dart';
import '../../application/usecases/get_product_by_id.dart';
import '../../application/usecases/get_product_create_options.dart';
import '../../application/usecases/get_product_filter_options.dart';
import '../../application/usecases/get_product_summary.dart';
import '../../application/usecases/get_products.dart';
import '../../application/usecases/update_product.dart';
import '../../application/usecases/update_product_status.dart';
import '../../data/datasources/product_wizard_draft_local_datasource.dart';
import '../../data/datasources/tenant_product_remote_datasource.dart';
import '../../data/repositories/tenant_product_repository_impl.dart';
import '../../domain/entities/add_product_wizard_state.dart';
import '../../domain/entities/product_wizard_draft.dart';
import '../../domain/entities/tenant_product.dart';
import '../../domain/entities/tenant_product_create_options.dart';
import '../../domain/entities/tenant_product_detail.dart';
import '../../domain/entities/tenant_product_filter_options.dart';
import '../../domain/repositories/product_wizard_draft_local_repository.dart';
import '../../domain/repositories/tenant_product_repository.dart';
import '../../domain/services/product_list_local_draft_merger.dart';
import '../controllers/add_product_wizard_controller.dart';

final tenantProductRemoteDatasourceProvider =
    Provider<TenantProductRemoteDatasource>((ref) {
  return TenantProductRemoteDatasource(ref.watch(appDioProvider));
});

final tenantProductRepositoryProvider =
    Provider<TenantProductRepository>((ref) {
  return TenantProductRepositoryImpl(
      ref.watch(tenantProductRemoteDatasourceProvider));
});

final productWizardDraftLocalDataSourceProvider =
    Provider<ProductWizardDraftLocalDataSource>((ref) {
  return ProductWizardDraftLocalDataSourceImpl(
    ref.watch(secureStorageProvider),
  );
});

final productWizardDraftLocalRepositoryProvider =
    Provider<ProductWizardDraftLocalRepository>((ref) {
  return ProductWizardDraftLocalRepositoryImpl(
    ref.watch(productWizardDraftLocalDataSourceProvider),
  );
});

final localProductWizardDraftsProvider =
    FutureProvider.autoDispose<List<ProductWizardDraft>>((ref) async {
  return ref.watch(productWizardDraftLocalRepositoryProvider).getAllDrafts();
});

final getProductsProvider = Provider<GetProducts>((ref) {
  return GetProducts(ref.watch(tenantProductRepositoryProvider));
});

final getProductSummaryProvider = Provider<GetProductSummary>((ref) {
  return GetProductSummary(ref.watch(tenantProductRepositoryProvider));
});

final getProductCreateOptionsProvider =
    Provider<GetProductCreateOptions>((ref) {
  return GetProductCreateOptions(ref.watch(tenantProductRepositoryProvider));
});

final getProductFilterOptionsProvider =
    Provider<GetProductFilterOptions>((ref) {
  return GetProductFilterOptions(ref.watch(tenantProductRepositoryProvider));
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

class ProductListFilterState {
  const ProductListFilterState({
    this.search = '',
    this.categoryId,
    this.brandId,
    this.productStatus,
    this.stockStatus,
    this.sortBy = 'productName',
    this.sortDirection = 'asc',
    this.pageNumber = 1,
    this.pageSize = 6,
  });

  final String search;
  final String? categoryId;
  final String? brandId;
  final String? productStatus;
  final String? stockStatus;
  final String sortBy;
  final String sortDirection;
  final int pageNumber;
  final int pageSize;

  ProductListFilterState copyWith({
    String? search,
    String? categoryId,
    bool clearCategory = false,
    String? brandId,
    bool clearBrand = false,
    String? productStatus,
    bool clearProductStatus = false,
    String? stockStatus,
    bool clearStockStatus = false,
    String? sortBy,
    String? sortDirection,
    int? pageNumber,
    int? pageSize,
  }) {
    return ProductListFilterState(
      search: search ?? this.search,
      categoryId: clearCategory ? null : (categoryId ?? this.categoryId),
      brandId: clearBrand ? null : (brandId ?? this.brandId),
      productStatus:
          clearProductStatus ? null : (productStatus ?? this.productStatus),
      stockStatus: clearStockStatus ? null : (stockStatus ?? this.stockStatus),
      sortBy: sortBy ?? this.sortBy,
      sortDirection: sortDirection ?? this.sortDirection,
      pageNumber: pageNumber ?? this.pageNumber,
      pageSize: pageSize ?? this.pageSize,
    );
  }

  TenantProductListQuery toQuery() {
    return TenantProductListQuery(
      search: search,
      categoryId: categoryId,
      brandId: brandId,
      productStatus: productStatus,
      stockStatus: stockStatus,
      sortBy: sortBy,
      sortDirection: sortDirection,
      pageNumber: pageNumber,
      pageSize: pageSize,
    );
  }
}

class ProductListFilterStateNotifier
    extends StateNotifier<ProductListFilterState> {
  ProductListFilterStateNotifier() : super(const ProductListFilterState());

  void setSearch(String value) {
    state = state.copyWith(search: value, pageNumber: 1);
  }

  void setCategory(String? categoryId) {
    if (categoryId == null || categoryId.trim().isEmpty) {
      state = state.copyWith(clearCategory: true, pageNumber: 1);
    } else {
      state = state.copyWith(categoryId: categoryId, pageNumber: 1);
    }
  }

  void setBrand(String? brandId) {
    if (brandId == null || brandId.trim().isEmpty) {
      state = state.copyWith(clearBrand: true, pageNumber: 1);
    } else {
      state = state.copyWith(brandId: brandId, pageNumber: 1);
    }
  }

  void setProductStatus(String? productStatus) {
    if (productStatus == null || productStatus.trim().isEmpty) {
      state = state.copyWith(clearProductStatus: true, pageNumber: 1);
    } else {
      state = state.copyWith(productStatus: productStatus, pageNumber: 1);
    }
  }

  void setStockStatus(String? stockStatus) {
    if (stockStatus == null || stockStatus.trim().isEmpty) {
      state = state.copyWith(clearStockStatus: true, pageNumber: 1);
    } else {
      state = state.copyWith(stockStatus: stockStatus, pageNumber: 1);
    }
  }

  void setSort(String sortBy, String sortDirection) {
    state = state.copyWith(
        sortBy: sortBy, sortDirection: sortDirection, pageNumber: 1);
  }

  void setPage(int pageNumber) {
    state = state.copyWith(pageNumber: pageNumber);
  }

  void setPageSize(int pageSize) {
    state = state.copyWith(pageSize: pageSize, pageNumber: 1);
  }

  void resetFilters() {
    state = state.copyWith(
      search: '',
      clearCategory: true,
      clearBrand: true,
      clearProductStatus: true,
      clearStockStatus: true,
      sortBy: 'productName',
      sortDirection: 'asc',
      pageNumber: 1,
    );
  }
}

final productListFilterProvider = StateNotifierProvider<
    ProductListFilterStateNotifier, ProductListFilterState>((ref) {
  return ProductListFilterStateNotifier();
});

final productListQueryProvider = Provider<TenantProductListQuery>((ref) {
  final filterState = ref.watch(productListFilterProvider);
  return filterState.toQuery();
});

final productFilterOptionsProvider =
    FutureProvider.autoDispose<TenantProductFilterOptions?>((ref) async {
  final accessChecker =
      await ref.watch(tenantAdminAccessCheckerProvider.future);

  if (!accessChecker.canFetchProductList()) {
    return null;
  }

  return ref.watch(getProductFilterOptionsProvider).call();
});

final productListProvider =
    FutureProvider.autoDispose<TenantProductListResult?>((
  ref,
) async {
  final accessChecker =
      await ref.watch(tenantAdminAccessCheckerProvider.future);

  if (!accessChecker.canFetchProductList()) {
    return null;
  }

  final query = ref.watch(productListQueryProvider);
  final backend = await ref.watch(getProductsProvider).call(query: query);
  final drafts = await ref.watch(localProductWizardDraftsProvider.future);
  return ProductListLocalDraftMerger.merge(
    backend: backend,
    drafts: drafts,
    query: query,
  );
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

final addProductWizardControllerProvider = StateNotifierProvider.autoDispose<
    AddProductWizardController, AddProductWizardState>((ref) {
  final repo = ref.watch(tenantProductRepositoryProvider);
  final draftLocal = ref.watch(productWizardDraftLocalRepositoryProvider);
  return AddProductWizardController(repo, draftLocal: draftLocal);
});

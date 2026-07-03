import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/network/dio_provider.dart';
import '../../application/usecases/create_product.dart';
import '../../application/usecases/get_products.dart';
import '../../data/datasources/product_remote_datasource.dart';
import '../../data/repositories/product_repository_impl.dart';
import '../../domain/entities/product.dart';
import '../../domain/repositories/product_repository.dart';
import '../utils/product_list_filters.dart';

final productRemoteDatasourceProvider = Provider<ProductRemoteDatasource>((ref) {
  return ProductRemoteDatasource(ref.watch(appDioProvider));
});

final productRepositoryProvider = Provider<ProductRepository>((ref) {
  return ProductRepositoryImpl(ref.watch(productRemoteDatasourceProvider));
});

final getProductsProvider = Provider<GetProducts>((ref) {
  return GetProducts(ref.watch(productRepositoryProvider));
});

final createProductProvider = Provider<CreateProduct>((ref) {
  return CreateProduct(ref.watch(productRepositoryProvider));
});

final productSearchProvider = StateProvider<String>((ref) => '');

final productStatusFilterProvider =
    StateProvider<ProductStatusFilter>((ref) => ProductStatusFilter.all);

final productPageProvider = StateProvider<int>((ref) => 1);

final productPageSizeProvider = StateProvider<int>((ref) => 10);

final productListQueryProvider = Provider<ProductListQuery>((ref) {
  final search = ref.watch(productSearchProvider);
  final statusFilter = ref.watch(productStatusFilterProvider);
  final page = ref.watch(productPageProvider);
  final pageSize = ref.watch(productPageSizeProvider);

  return ProductListQuery(
    search: search,
    page: page,
    pageSize: pageSize,
    status: statusFilter.apiStatus,
  );
});

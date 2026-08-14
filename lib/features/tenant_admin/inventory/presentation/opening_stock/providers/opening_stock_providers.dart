import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nytroz_pos/core/network/dio_provider.dart';
import '../../../../products/domain/entities/tenant_product.dart';
import '../../../../products/presentation/providers/tenant_product_providers.dart';
import '../../../../outlets/domain/entities/outlet.dart';
import '../../../../outlets/domain/entities/outlet_list_query.dart';
import '../../../../outlets/presentation/providers/outlet_providers.dart';
import '../../../data/datasources/opening_stock_remote_datasource.dart';
import '../../../data/mock/inventory_frontend_mock.dart';
import '../../../data/repositories/opening_stock_repository_impl.dart';
import '../../../domain/repositories/opening_stock_repository.dart';
import 'opening_stock_state.dart';
import 'opening_stock_notifier.dart';

final openingStockRemoteDatasourceProvider =
    Provider<OpeningStockRemoteDatasource>((ref) {
  return OpeningStockRemoteDatasource(ref.watch(appDioProvider));
});

final openingStockRepositoryProvider = Provider<OpeningStockRepository>((ref) {
  if (ref.watch(inventoryFrontendMockEnabledProvider)) {
    return const InventoryOpeningStockMockRepository();
  }
  return OpeningStockRepositoryImpl(
      ref.watch(openingStockRemoteDatasourceProvider));
});

final openingStockProvider =
    StateNotifierProvider<OpeningStockNotifier, OpeningStockState>((ref) {
  final repository = ref.watch(openingStockRepositoryProvider);
  return OpeningStockNotifier(repository);
});

final openingStockProductSearchProvider = StateProvider<String>((ref) => '');

final openingStockProductsProvider =
    FutureProvider.autoDispose<List<TenantProduct>>((ref) async {
  final search = ref.watch(openingStockProductSearchProvider);
  if (ref.watch(inventoryFrontendMockEnabledProvider)) {
    final q = search.trim().toLowerCase();
    return InventoryFrontendMock.tenantProducts
        .where((p) =>
            q.isEmpty ||
            p.name.toLowerCase().contains(q) ||
            p.sku.toLowerCase().contains(q))
        .toList();
  }
  final getProducts = ref.watch(getProductsProvider);

  final query = TenantProductListQuery(
    search: search,
    pageSize: 50,
    pageNumber: 1,
    sortBy: 'productName',
    sortDirection: 'asc',
  );

  final result = await getProducts(query: query);
  return result.items;
});

final openingStockOutletSearchProvider = StateProvider<String>((ref) => '');

final openingStockOutletsProvider =
    FutureProvider.autoDispose<List<Outlet>>((ref) async {
  final search = ref.watch(openingStockOutletSearchProvider);
  if (ref.watch(inventoryFrontendMockEnabledProvider)) {
    final q = search.trim().toLowerCase();
    return InventoryFrontendMock.tenantOutlets
        .where((o) =>
            q.isEmpty ||
            o.name.toLowerCase().contains(q) ||
            o.code.toLowerCase().contains(q))
        .toList();
  }
  final getOutlets = ref.watch(getOutletsProvider);

  final query = OutletListQuery(
    search: search,
    pageSize: 50,
    page: 1,
    sortBy: 'name',
    sortDirection: 'asc',
  );

  final result = await getOutlets(query: query);
  return result.items;
});

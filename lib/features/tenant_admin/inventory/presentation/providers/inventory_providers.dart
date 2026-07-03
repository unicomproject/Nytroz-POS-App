import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/network/dio_provider.dart';
import '../../../products/domain/entities/product.dart';
import '../../../products/presentation/providers/product_providers.dart';
import '../../data/datasources/inventory_remote_datasource.dart';
import '../../data/repositories/inventory_repository_impl.dart';
import '../../domain/entities/inventory.dart';
import '../../domain/repositories/inventory_repository.dart';
import '../config/inventory_api_capabilities.dart';

final inventoryRemoteDatasourceProvider =
    Provider<InventoryRemoteDatasource>((ref) {
  return InventoryRemoteDatasource(ref.watch(appDioProvider));
});

final inventoryRepositoryProvider = Provider<InventoryRepository>((ref) {
  return InventoryRepositoryImpl(ref.watch(inventoryRemoteDatasourceProvider));
});

final inventoryLocationsProvider =
    FutureProvider.autoDispose<List<InventoryLocation>>((ref) async {
  if (!InventoryApiCapabilities.listLocations) {
    return const [];
  }

  return ref.watch(inventoryRepositoryProvider).getLocations();
});

final inventorySelectedLocationProvider = StateProvider<String?>((ref) => null);

final inventorySearchProvider = StateProvider<String>((ref) => '');

final inventoryLowStockFilterProvider = StateProvider<bool>((ref) => false);

final inventoryPageProvider = StateProvider<int>((ref) => 1);

final inventoryPageSizeProvider = StateProvider<int>((ref) => 10);

final inventoryBalanceQueryProvider = Provider<InventoryBalanceQuery>((ref) {
  return InventoryBalanceQuery(
    locationId: ref.watch(inventorySelectedLocationProvider),
    search: ref.watch(inventorySearchProvider),
    page: ref.watch(inventoryPageProvider),
    pageSize: ref.watch(inventoryPageSizeProvider),
    lowStockOnly: ref.watch(inventoryLowStockFilterProvider),
  );
});

final inventoryBalancesProvider =
    FutureProvider.autoDispose<InventoryBalanceListResult?>((ref) async {
  if (!InventoryApiCapabilities.listBalances) {
    throw const InventoryApiUnavailable('GET /api/v1/inventory/balances');
  }

  final query = ref.watch(inventoryBalanceQueryProvider);
  return ref.watch(inventoryRepositoryProvider).getBalances(query);
});

final stockInProductSearchProvider = StateProvider<String>((ref) => '');

final stockInProductsProvider =
    FutureProvider.autoDispose<List<StockProductOption>>((ref) async {
  if (!InventoryApiCapabilities.listProductsReference) {
    return const [];
  }

  final search = ref.watch(stockInProductSearchProvider);
  final result = await ref.watch(getProductsProvider).call(
        query: ProductListQuery(
          search: search,
          page: 1,
          pageSize: 100,
        ),
      );

  return _groupProducts(result.items);
});

final stockInSelectedProductIdProvider = StateProvider<String?>((ref) => null);

final stockInSelectedVariantIdProvider = StateProvider<String?>((ref) => null);

final stockInSelectedLocationIdProvider = StateProvider<String?>((ref) => null);

List<StockProductOption> _groupProducts(List<Product> items) {
  final grouped = <String, List<Product>>{};

  for (final item in items) {
    grouped.putIfAbsent(item.id, () => []).add(item);
  }

  return grouped.entries
      .map(
        (entry) => StockProductOption(
          productId: entry.key,
          name: entry.value.first.name,
          primarySku: entry.value.first.sku,
          variants: entry.value
              .map(
                (product) => StockVariantOption(
                  variantId: product.variantId,
                  label: product.sku,
                  sku: product.sku,
                ),
              )
              .toList(growable: false),
        ),
      )
      .toList(growable: false)
    ..sort((a, b) => a.name.compareTo(b.name));
}

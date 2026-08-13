import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../../core/network/dio_provider.dart';
import '../../../data/models/current_stock_dtos.dart';
import '../../../domain/entities/current_stock_entities.dart';
import '../../dashboard/providers/inventory_dashboard_providers.dart';

final currentStockSearchProvider = StateProvider<String>((ref) => '');
final currentStockStatusFilterProvider = StateProvider<String?>((ref) => null);
final currentStockOutletFilterProvider = StateProvider<String?>((ref) => null);
final currentStockPageProvider = StateProvider<int>((ref) => 1);
final currentStockPageSizeProvider = StateProvider<int>((ref) => 10);

class InventoryOutletOption {
  final String id;
  final String name;
  InventoryOutletOption({required this.id, required this.name});
}

final inventoryOutletsProvider =
    FutureProvider.autoDispose<List<InventoryOutletOption>>((ref) async {
  final dio = ref.watch(appDioProvider);
  final response = await dio.get('/api/v1/tenant-admin/outlets/options');
  final data = response.data['data'] as List;
  return data
      .map((json) => InventoryOutletOption(
            id: json['outletId'] as String,
            name: json['outletName'] as String,
          ))
      .toList();
});

final currentStockSummaryProvider =
    FutureProvider.autoDispose<CurrentStockSummary>((ref) async {
  final outletId = ref.watch(currentStockOutletFilterProvider);
  final repository = ref.watch(inventoryRepositoryProvider);

  return repository.getCurrentStockSummary(outletId: outletId);
});

final currentStockListProvider =
    FutureProvider.autoDispose<CurrentStockPage>((ref) async {
  final search = ref.watch(currentStockSearchProvider);
  final stockStatus = ref.watch(currentStockStatusFilterProvider);
  final outletId = ref.watch(currentStockOutletFilterProvider);
  final page = ref.watch(currentStockPageProvider);
  final pageSize = ref.watch(currentStockPageSizeProvider);
  final repository = ref.watch(inventoryRepositoryProvider);

  final query = CurrentStockQueryDto(
    outletId: outletId,
    search: search.trim().isEmpty ? null : search.trim(),
    stockStatus: stockStatus,
    page: page,
    pageSize: pageSize,
  );

  return repository.getCurrentStock(query);
});

final productStockDetailProvider = FutureProvider.autoDispose
    .family<ProductStockDetail, String>((ref, variantId) async {
  final outletId = ref.watch(currentStockOutletFilterProvider);
  final repository = ref.watch(inventoryRepositoryProvider);

  return repository.getProductStockDetail(variantId, outletId: outletId);
});

final stockMovementHistoryPageProvider = StateProvider<int>((ref) => 1);
final stockMovementHistoryPageSizeProvider = StateProvider<int>((ref) => 10);

final stockMovementHistoryProvider = FutureProvider.autoDispose
    .family<StockMovementHistoryPage, String>((ref, variantId) async {
  final outletId = ref.watch(currentStockOutletFilterProvider);
  final page = ref.watch(stockMovementHistoryPageProvider);
  final pageSize = ref.watch(stockMovementHistoryPageSizeProvider);
  final repository = ref.watch(inventoryRepositoryProvider);

  final query = StockMovementHistoryQueryDto(
    outletId: outletId,
    page: page,
    pageSize: pageSize,
  );

  return repository.getStockMovementHistory(variantId, query);
});

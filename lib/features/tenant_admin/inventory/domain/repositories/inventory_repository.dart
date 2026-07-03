import '../entities/inventory.dart';

class InventoryApiUnavailable implements Exception {
  const InventoryApiUnavailable(this.endpoint);

  final String endpoint;

  @override
  String toString() => 'Inventory API unavailable: $endpoint';
}

abstract class InventoryRepository {
  Future<List<InventoryLocation>> getLocations();

  Future<InventoryBalanceListResult> getBalances(InventoryBalanceQuery query);

  Future<void> submitStockIn(StockInFormData data);
}

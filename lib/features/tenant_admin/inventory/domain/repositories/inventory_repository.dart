import '../entities/inventory_entities.dart';

abstract class InventoryRepository {
  Future<CurrentStockPage> getCurrentStock(CurrentStockQuery query);

  Future<CurrentStockSummary> getCurrentStockSummary({String? outletId});

  Future<StockInResult> receiveStock(StockInFormInput input,
      {String? idempotencyKey});

  Future<VariantLookup> getProductVariants(String productId);
}

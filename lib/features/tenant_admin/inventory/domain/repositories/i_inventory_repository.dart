import '../../data/models/current_stock_dtos.dart';
import '../../data/models/inventory_dashboard_models.dart';
import '../../data/models/opening_stock_dtos.dart';
import '../entities/current_stock_entities.dart';

abstract class IInventoryRepository {
  Future<InventoryDashboardMetricsDto> getDashboardMetrics({String? outletId});
  
  Future<InventoryDashboardAlertsResponseDto> getDashboardAlerts({
    String? outletId,
    int page = 1,
    int pageSize = 10,
  });
  
  Future<InventoryDashboardActivitiesResponseDto> getDashboardActivities({
    String? outletId,
    int page = 1,
    int pageSize = 10,
  });

  Future<CurrentStockSummary> getCurrentStockSummary({String? outletId});

  Future<CurrentStockPage> getCurrentStock(CurrentStockQueryDto query);

  Future<ProductStockDetail> getProductStockDetail(String variantId, {String? outletId});
  
  Future<StockMovementHistoryPage> getStockMovementHistory(String variantId, StockMovementHistoryQueryDto query);

  Future<void> createOpeningStock(OpeningStockRequestDto request);
}

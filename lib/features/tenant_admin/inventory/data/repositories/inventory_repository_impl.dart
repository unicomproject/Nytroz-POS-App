import '../../domain/repositories/i_inventory_repository.dart';
import '../../domain/entities/current_stock_entities.dart';
import '../datasources/inventory_remote_datasource.dart';
import '../models/current_stock_dtos.dart';
import '../models/inventory_dashboard_models.dart';

class InventoryRepositoryImpl implements IInventoryRepository {
  const InventoryRepositoryImpl(this._remoteDatasource);

  final InventoryRemoteDatasource _remoteDatasource;

  @override
  Future<InventoryDashboardMetricsDto> getDashboardMetrics({String? outletId}) {
    return _remoteDatasource.getDashboardMetrics(outletId: outletId);
  }

  @override
  Future<InventoryDashboardAlertsResponseDto> getDashboardAlerts({
    String? outletId,
    int page = 1,
    int pageSize = 10,
  }) {
    return _remoteDatasource.getDashboardAlerts(
      outletId: outletId,
      page: page,
      pageSize: pageSize,
    );
  }

  @override
  Future<InventoryDashboardActivitiesResponseDto> getDashboardActivities({
    String? outletId,
    int page = 1,
    int pageSize = 10,
  }) {
    return _remoteDatasource.getDashboardActivities(
      outletId: outletId,
      page: page,
      pageSize: pageSize,
    );
  }

  @override
  Future<CurrentStockSummary> getCurrentStockSummary({String? outletId}) async {
    final dto = await _remoteDatasource.getCurrentStockSummary(outletId: outletId);
    return dto.toDomain();
  }

  @override
  Future<CurrentStockPage> getCurrentStock(CurrentStockQueryDto query) async {
    final dto = await _remoteDatasource.getCurrentStock(query);
    return dto.toDomain();
  }

  @override
  Future<ProductStockDetail> getProductStockDetail(String variantId, {String? outletId}) async {
    final dto = await _remoteDatasource.getProductStockDetail(variantId, outletId: outletId);
    return dto.toDomain();
  }

  @override
  Future<StockMovementHistoryPage> getStockMovementHistory(String variantId, StockMovementHistoryQueryDto query) async {
    final dto = await _remoteDatasource.getStockMovementHistory(variantId, query);
    return dto.toDomain();
  }
}

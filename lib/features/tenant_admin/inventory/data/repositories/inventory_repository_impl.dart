import '../../domain/entities/inventory.dart';
import '../../domain/repositories/inventory_repository.dart';
import '../datasources/inventory_remote_datasource.dart';
import '../mappers/inventory_mapper.dart';
import '../models/inventory_dto.dart';
import '../../presentation/config/inventory_api_capabilities.dart';

class InventoryRepositoryImpl implements InventoryRepository {
  const InventoryRepositoryImpl(this._remoteDatasource);

  final InventoryRemoteDatasource _remoteDatasource;

  @override
  Future<List<InventoryLocation>> getLocations() async {
    if (!InventoryApiCapabilities.listLocations) {
      throw const InventoryApiUnavailable(_locationsEndpoint);
    }

    final result = await _remoteDatasource.getLocations();
    return result.map(InventoryMapper.toLocationEntity).toList(growable: false);
  }

  @override
  Future<InventoryBalanceListResult> getBalances(
    InventoryBalanceQuery query,
  ) async {
    if (!InventoryApiCapabilities.listBalances) {
      throw const InventoryApiUnavailable(_balancesEndpoint);
    }

    final result = await _remoteDatasource.getBalances(
      locationId: query.locationId,
      search: query.search,
      page: query.page,
      pageSize: query.pageSize,
      lowStockOnly: query.lowStockOnly,
    );

    return InventoryMapper.toBalanceListResult(result);
  }

  @override
  Future<void> submitStockIn(StockInFormData data) async {
    if (!InventoryApiCapabilities.stockIn) {
      throw const InventoryApiUnavailable(_stockInEndpoint);
    }

    await _remoteDatasource.submitStockIn(StockInRequestDto.fromEntity(data));
  }
}

const _locationsEndpoint = 'GET /api/v1/inventory/locations';
const _balancesEndpoint = 'GET /api/v1/inventory/balances';
const _stockInEndpoint = 'POST /api/v1/inventory/stock-movements';

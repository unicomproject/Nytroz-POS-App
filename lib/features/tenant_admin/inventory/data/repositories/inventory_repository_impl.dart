import '../../domain/entities/inventory_entities.dart';
import '../../domain/repositories/inventory_repository.dart';
import '../datasources/inventory_remote_datasource.dart';
import '../mappers/inventory_mapper.dart';

class InventoryRepositoryImpl implements InventoryRepository {
  const InventoryRepositoryImpl(this._remoteDatasource);

  final InventoryRemoteDatasource _remoteDatasource;

  @override
  Future<CurrentStockPage> getCurrentStock(CurrentStockQuery query) async {
    final dto = await _remoteDatasource.getCurrentStock(
      InventoryMapper.toQueryDto(query),
    );
    return InventoryMapper.toPage(dto);
  }

  @override
  Future<CurrentStockSummary> getCurrentStockSummary({String? outletId}) async {
    final dto = await _remoteDatasource.getCurrentStockSummary(
      outletId: outletId,
    );
    return InventoryMapper.toSummary(dto);
  }

  @override
  Future<StockInResult> receiveStock(
    StockInFormInput input, {
    String? idempotencyKey,
  }) async {
    final dto = await _remoteDatasource.receiveStock(
      InventoryMapper.toStockInRequest(input, idempotencyKey: idempotencyKey),
    );
    return InventoryMapper.toStockInResult(dto);
  }

  @override
  Future<VariantLookup> getProductVariants(String productId) async {
    final dto = await _remoteDatasource.getProductVariants(productId);
    return InventoryMapper.toVariantLookup(dto);
  }
}

import '../../data/datasources/opening_stock_remote_datasource.dart';
import '../../data/models/opening_stock_dto.dart';
import '../../domain/entities/opening_stock_param.dart';
import '../../domain/repositories/opening_stock_repository.dart';

class OpeningStockRepositoryImpl implements OpeningStockRepository {
  const OpeningStockRepositoryImpl(this._remoteDatasource);

  final OpeningStockRemoteDatasource _remoteDatasource;

  @override
  Future<OpeningStockResult> submitOpeningStock(OpeningStockParam param) async {
    final requestDto = OpeningStockRequestDto(
      outletId: param.outletId,
      notes: param.notes,
      items: param.items
          .map(
            (item) => OpeningStockLineRequestDto(
              productId: item.productId,
              variantId: item.variantId,
              quantity: item.quantity,
              unitCost: item.unitCost,
              batchNumber: item.batchNumber,
              expiryDate: item.expiryDate,
            ),
          )
          .toList(),
    );

    final responseDto = await _remoteDatasource.addOpeningStock(requestDto);

    return OpeningStockResult(
      stockMovementId: responseDto.stockMovementId,
      outletId: responseDto.outletId,
      itemCount: responseDto.itemCount,
      createdAt: responseDto.createdAt,
    );
  }
}

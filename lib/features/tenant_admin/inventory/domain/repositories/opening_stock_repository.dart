import '../entities/opening_stock_param.dart';

abstract class OpeningStockRepository {
  Future<OpeningStockResult> submitOpeningStock(OpeningStockParam param);
}

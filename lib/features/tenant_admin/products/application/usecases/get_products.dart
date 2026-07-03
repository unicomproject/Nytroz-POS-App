import '../../domain/entities/product.dart';
import '../../domain/repositories/product_repository.dart';

class GetProducts {
  const GetProducts(this._repository);

  final ProductRepository _repository;

  Future<ProductListResult> call({required ProductListQuery query}) {
    return _repository.getProducts(query);
  }
}

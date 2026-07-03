import '../../domain/entities/product.dart';
import '../../domain/repositories/product_repository.dart';

class CreateProduct {
  const CreateProduct(this._repository);

  final ProductRepository _repository;

  Future<CreatedProduct> call(ProductFormData data) {
    return _repository.createProduct(data);
  }
}

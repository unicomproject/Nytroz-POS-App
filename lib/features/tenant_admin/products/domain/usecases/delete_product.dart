import '../entities/product_delete_result.dart';
import '../repositories/tenant_product_repository.dart';

class DeleteProduct {
  const DeleteProduct(this._repository);

  final TenantProductRepository _repository;

  Future<ProductDeleteResult> call(String productId) {
    return _repository.deleteProduct(productId);
  }
}

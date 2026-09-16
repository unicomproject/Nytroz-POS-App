import '../entities/tenant_product_detail.dart';
import '../repositories/tenant_product_repository.dart';

class GetProductById {
  const GetProductById(this._repository);

  final TenantProductRepository _repository;

  Future<TenantProductDetail> call(String productId) {
    return _repository.getProductById(productId);
  }
}

import '../../domain/entities/tenant_product_detail.dart';
import '../../domain/repositories/tenant_product_repository.dart';

class GetProductById {
  const GetProductById(this._repository);

  final TenantProductRepository _repository;

  Future<TenantProductDetail> call(String productId) {
    return _repository.getProductById(productId);
  }
}

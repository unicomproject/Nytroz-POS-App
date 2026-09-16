import '../entities/tenant_product.dart';
import '../repositories/tenant_product_repository.dart';

class GetProductSummary {
  const GetProductSummary(this._repository);

  final TenantProductRepository _repository;

  Future<TenantProductSummary> call() {
    return _repository.getProductSummary();
  }
}

import '../../domain/entities/tenant_product.dart';
import '../../domain/repositories/tenant_product_repository.dart';

class GetProducts {
  const GetProducts(this._repository);

  final TenantProductRepository _repository;

  Future<TenantProductListResult> call({required TenantProductListQuery query}) {
    return _repository.getProducts(query: query);
  }
}

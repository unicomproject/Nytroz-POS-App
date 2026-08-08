import '../../domain/entities/tenant_product_filter_options.dart';
import '../../domain/repositories/tenant_product_repository.dart';

class GetProductFilterOptions {
  const GetProductFilterOptions(this._repository);

  final TenantProductRepository _repository;

  Future<TenantProductFilterOptions> call() {
    return _repository.getProductFilterOptions();
  }
}

import '../../domain/entities/tenant_product_create_options.dart';
import '../../domain/repositories/tenant_product_repository.dart';

class GetProductCreateOptions {
  const GetProductCreateOptions(this._repository);

  final TenantProductRepository _repository;

  Future<TenantProductCreateOptions> call() {
    return _repository.getCreateOptions();
  }
}

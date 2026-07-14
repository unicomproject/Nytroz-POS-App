import '../../domain/entities/product_form_data.dart';
import '../../domain/repositories/tenant_product_repository.dart';

class CreateProduct {
  const CreateProduct(this._repository);

  final TenantProductRepository _repository;

  Future<ProductCreateResult> call({required ProductFormData request}) {
    return _repository.createProduct(request);
  }
}

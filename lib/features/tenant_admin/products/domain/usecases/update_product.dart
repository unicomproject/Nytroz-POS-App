import '../entities/product_form_data.dart';
import '../entities/tenant_product_detail.dart';
import '../repositories/tenant_product_repository.dart';

class UpdateProduct {
  const UpdateProduct(this._repository);

  final TenantProductRepository _repository;

  Future<TenantProductDetail> call({
    required String productId,
    required ProductFormData request,
  }) {
    return _repository.updateProduct(productId, request);
  }
}

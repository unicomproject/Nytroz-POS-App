import '../../domain/entities/product_form_data.dart';
import '../../domain/entities/tenant_product_detail.dart';
import '../../domain/repositories/tenant_product_repository.dart';

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

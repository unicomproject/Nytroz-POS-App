import '../../domain/entities/product_status_update_result.dart';
import '../../domain/repositories/tenant_product_repository.dart';

class UpdateProductStatus {
  const UpdateProductStatus(this._repository);

  final TenantProductRepository _repository;

  Future<ProductStatusUpdateResult> call({
    required String productId,
    required String status,
  }) {
    return _repository.updateProductStatus(productId, status);
  }
}

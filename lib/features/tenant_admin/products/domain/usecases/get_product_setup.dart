import '../../data/dtos/product_draft_response_dto.dart';
import '../repositories/tenant_product_repository.dart';

class GetProductSetup {
  const GetProductSetup(this._repository);

  final TenantProductRepository _repository;

  Future<ProductDraftResponseDto> call(String productId) {
    return _repository.getSetup(productId);
  }
}

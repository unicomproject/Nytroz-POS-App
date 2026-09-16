import '../../data/dtos/product_draft_response_dto.dart';
import '../../data/dtos/save_product_draft_request_dto.dart';
import '../repositories/tenant_product_repository.dart';

class SaveProductDraft {
  const SaveProductDraft(this._repository);

  final TenantProductRepository _repository;

  Future<ProductDraftResponseDto> call(
    SaveProductDraftRequestDto request, {
    String? productId,
  }) {
    if (productId == null || productId.isEmpty) {
      return _repository.saveDraft(request);
    }
    return _repository.updateDraft(productId, request);
  }
}

import '../../data/dtos/product_draft_response_dto.dart';
import '../../data/dtos/product_create_request_dto.dart';
import '../../data/dtos/product_setup_scan_dtos.dart';
import '../../data/dtos/save_product_draft_request_dto.dart';
import '../../data/dtos/staged_image_response_dto.dart';
import '../../domain/entities/product_delete_result.dart';
import '../../domain/entities/product_form_data.dart';
import '../../domain/entities/product_status_update_result.dart';
import '../../domain/entities/tenant_product.dart';
import '../../domain/entities/tenant_product_create_options.dart';
import '../../domain/entities/tenant_product_detail.dart';
import '../../domain/entities/tenant_product_filter_options.dart';

abstract class TenantProductRepository {
  Future<TenantProductListResult> getProducts({
    required TenantProductListQuery query,
  });

  Future<TenantProductSummary> getProductSummary();
  Future<TenantProductCreateOptions> getCreateOptions();
  Future<TenantProductDetail> getProductById(String productId);
  Future<ProductCreateResult> createProduct(ProductFormData request);
  Future<ProductCreateResult> createProductFromWizard(
    Map<String, dynamic> wizardCreatePayload,
  );
  Future<TenantProductDetail> updateProduct(
    String productId,
    ProductFormData request,
  );
  Future<ProductStatusUpdateResult> updateProductStatus(
    String productId,
    String status,
  );
  Future<ProductDeleteResult> deleteProduct(String productId);
  Future<TenantProductFilterOptions> getProductFilterOptions();

  Future<ResolveProductBarcodeResponseDto> resolveBarcode(
    ResolveProductBarcodeRequestDto request,
  );
  Future<ExternalLookupProductBarcodeResponseDto> externalLookupBarcode({
    required String barcode,
    String? identifierStandard,
  });
  Future<SkuCandidateResponseDto> generateSkuCandidate(
    GenerateSkuCandidateRequestDto request,
  );

  /// Creates a NEW DRAFT from an existing product (clears SKU/barcode; no stock).
  Future<ProductCreateResponseDto> duplicateProduct(String productId);

  Future<ProductDraftResponseDto> saveDraft(SaveProductDraftRequestDto request);
  Future<ProductDraftResponseDto> updateDraft(
      String productId, SaveProductDraftRequestDto request);
  Future<ProductDraftResponseDto> getSetup(String productId);
  Future<StagedImageResponseDto> stageImage(
      List<int> bytes, String fileName, String mimeType);

  /// Server-side fetch + stage of an external imageCandidate URL.
  Future<StagedImageResponseDto> stageImageFromUrl(String imageUrl);

  Future<ProductImageResponseDto> uploadProductImage(
      String productId, List<int> bytes, String fileName, String mimeType);
  Future<ProductDraftResponseDto> reorderProductImages(
      String productId,
      int expectedRowVersion,
      String? primaryProductImageId,
      List<Map<String, dynamic>> items);
  Future<ProductDraftResponseDto> deleteProductImage(
      String productId, String productImageId);
  Future<ProductDraftResponseDto> replaceProductImages(String productId,
      int expectedRowVersion, List<String> stagedMediaAssetIds);
}

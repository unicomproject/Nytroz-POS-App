import '../../domain/entities/product_form_data.dart';
import '../../domain/entities/tenant_product.dart';
import '../../domain/entities/tenant_product_create_options.dart';
import '../../domain/entities/tenant_product_filter_options.dart';
import '../../domain/entities/product_delete_result.dart';
import '../../domain/entities/product_status_update_result.dart';
import '../../domain/entities/tenant_product_detail.dart';
import '../../domain/repositories/tenant_product_repository.dart';
import '../datasources/tenant_product_remote_datasource.dart';
import '../mappers/tenant_product_mapper.dart';
import '../models/product_create_request_dto.dart';
import '../models/product_draft_response_dto.dart';
import '../models/product_status_update_dto.dart';
import '../models/save_product_draft_request_dto.dart';
import '../models/staged_image_response_dto.dart';

class TenantProductRepositoryImpl implements TenantProductRepository {
  const TenantProductRepositoryImpl(this._remoteDatasource);

  final TenantProductRemoteDatasource _remoteDatasource;

  @override
  Future<TenantProductListResult> getProducts({
    required TenantProductListQuery query,
  }) async {
    final dto = await _remoteDatasource.getProducts(query);
    return TenantProductMapper.toListResult(dto);
  }

  @override
  Future<TenantProductSummary> getProductSummary() async {
    final dto = await _remoteDatasource.getProductSummary();
    return TenantProductMapper.toSummaryEntity(dto);
  }

  @override
  Future<TenantProductCreateOptions> getCreateOptions() async {
    final dto = await _remoteDatasource.getCreateOptions();
    return TenantProductMapper.toCreateOptions(dto);
  }

  @override
  Future<TenantProductDetail> getProductById(String productId) async {
    final dto = await _remoteDatasource.getProductById(productId);
    return TenantProductMapper.toDetailEntity(dto);
  }

  @override
  Future<ProductCreateResult> createProduct(ProductFormData request) async {
    final dto = await _remoteDatasource.createProduct(_toRequestDto(request));
    return TenantProductMapper.toCreateResult(dto);
  }

  @override
  Future<TenantProductDetail> updateProduct(
    String productId,
    ProductFormData request,
  ) async {
    final dto = await _remoteDatasource.updateProduct(
      productId,
      _toRequestDto(request),
    );
    return TenantProductMapper.toDetailEntity(dto);
  }

  @override
  Future<ProductStatusUpdateResult> updateProductStatus(
    String productId,
    String status,
  ) async {
    final dto = await _remoteDatasource.updateProductStatus(
      productId,
      ProductStatusUpdateRequestDto(status: status),
    );
    return TenantProductMapper.toStatusUpdateResult(dto);
  }

  @override
  Future<ProductDeleteResult> deleteProduct(String productId) async {
    final dto = await _remoteDatasource.deleteProduct(productId);
    return TenantProductMapper.toDeleteResult(dto);
  }

  ProductCreateRequestDto _toRequestDto(ProductFormData request) {
    return ProductCreateRequestDto(
      productName: request.productName,
      sku: request.sku,
      barcode: request.barcode,
      categoryId: request.categoryId,
      subCategoryId: request.subCategoryId,
      brandId: request.brandId,
      unitType: request.unitType,
      shortDescription: request.shortDescription,
      longDescription: request.longDescription,
      costPrice: request.costPrice,
      sellingPrice: request.sellingPrice,
      discountPrice: request.discountPrice,
      taxId: request.taxId,
      trackInventory: request.trackInventory,
      openingStockQuantity: request.openingStockQuantity,
      minimumStockAlertQuantity: request.minimumStockAlertQuantity,
      maximumStockQuantity: request.maximumStockQuantity,
      stockUnit: request.stockUnit,
      outletIds: request.outletIds,
      hasVariants: request.hasVariants,
      variants: request.variants
          .map(
            (variant) => ProductVariantRequestDto(
              variantName: variant.variantName,
              sku: variant.sku,
              barcode: variant.barcode,
              sellingPrice: variant.sellingPrice,
              discountPrice: variant.discountPrice,
              status: variant.status,
            ),
          )
          .toList(),
      hasExpiryDate: request.hasExpiryDate,
      batchNumber: request.batchNumber,
      manufactureDate: _formatDateOnly(request.manufactureDate),
      expiryDate: _formatDateOnly(request.expiryDate),
      expiryAlertDays: request.expiryAlertDays,
      status: request.status,
      saveAsDraft: request.saveAsDraft,
    );
  }

  String? _formatDateOnly(DateTime? value) {
    if (value == null) {
      return null;
    }

    final year = value.year.toString().padLeft(4, '0');
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  @override
  Future<TenantProductFilterOptions> getProductFilterOptions() async {
    final dto = await _remoteDatasource.getProductFilterOptions();
    return TenantProductMapper.toFilterOptions(dto);
  }

  @override
  Future<ProductDraftResponseDto> saveDraft(
    SaveProductDraftRequestDto request,
  ) {
    return _remoteDatasource.saveDraft(request);
  }

  @override
  Future<ProductDraftResponseDto> updateDraft(
    String productId,
    SaveProductDraftRequestDto request,
  ) {
    return _remoteDatasource.updateDraft(productId, request);
  }

  @override
  Future<ProductDraftResponseDto> getSetup(String productId) {
    return _remoteDatasource.getSetup(productId);
  }

  @override
  Future<StagedImageResponseDto> stageImage(
    List<int> bytes,
    String fileName,
    String mimeType,
  ) {
    return _remoteDatasource.stageImage(bytes, fileName, mimeType);
  }

  @override
  Future<ProductImageResponseDto> uploadProductImage(
    String productId,
    List<int> bytes,
    String fileName,
    String mimeType,
  ) {
    return _remoteDatasource.uploadProductImage(
        productId, bytes, fileName, mimeType);
  }

  @override
  Future<ProductDraftResponseDto> reorderProductImages(
    String productId,
    int expectedRowVersion,
    String? primaryProductImageId,
    List<Map<String, dynamic>> items,
  ) {
    return _remoteDatasource.reorderProductImages(
      productId,
      expectedRowVersion,
      primaryProductImageId,
      items,
    );
  }

  @override
  Future<ProductDraftResponseDto> deleteProductImage(
    String productId,
    String productImageId,
  ) {
    return _remoteDatasource.deleteProductImage(productId, productImageId);
  }

  @override
  Future<ProductDraftResponseDto> replaceProductImages(
    String productId,
    int expectedRowVersion,
    List<String> stagedMediaAssetIds,
  ) {
    return _remoteDatasource.replaceProductImages(
      productId,
      expectedRowVersion,
      stagedMediaAssetIds,
    );
  }
}

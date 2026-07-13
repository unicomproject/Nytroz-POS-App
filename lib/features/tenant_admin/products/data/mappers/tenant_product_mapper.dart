import '../../domain/entities/product_form_data.dart';
import '../../domain/entities/product_delete_result.dart';
import '../../domain/entities/product_status_update_result.dart';
import '../../domain/entities/tenant_product.dart';
import '../../domain/entities/tenant_product_create_options.dart';
import '../../domain/entities/tenant_product_detail.dart';
import '../models/product_create_request_dto.dart';
import '../models/product_delete_response_dto.dart';
import '../models/product_status_update_dto.dart';
import '../models/tenant_product_create_options_dto.dart';
import '../models/tenant_product_detail_dto.dart';
import '../models/tenant_product_dto.dart';

class TenantProductMapper {
  const TenantProductMapper._();

  static TenantProductListResult toListResult(TenantProductListResultDto dto) {
    return TenantProductListResult(
      items: dto.items.map(toEntity).toList(),
      page: dto.page,
      pageSize: dto.pageSize,
      totalCount: dto.totalCount,
    );
  }

  static TenantProduct toEntity(TenantProductListItemDto dto) {
    return TenantProduct(
      id: dto.id,
      name: dto.name,
      sku: dto.sku,
      barcode: dto.barcode,
      categoryName: dto.categoryName,
      sellingPrice: dto.sellingPrice,
      currencyCode: dto.currencyCode ?? 'LKR',
      stockQuantity: dto.stockQuantity,
      status: dto.status,
      imageUrl: dto.imageUrl,
    );
  }

  static TenantProductSummary toSummaryEntity(TenantProductSummaryDto dto) {
    return TenantProductSummary(
      totalProducts: dto.totalProducts,
      activeProducts: dto.activeProducts,
      inactiveProducts: dto.inactiveProducts,
      categoryCount: dto.categoryCount,
    );
  }

  static TenantProductCreateOptions toCreateOptions(
    TenantProductCreateOptionsDto dto,
  ) {
    return TenantProductCreateOptions(
      categories: dto.categories
          .map(
            (item) => ProductCategoryOption(
              id: item.id,
              name: item.name,
              code: item.code,
            ),
          )
          .toList(),
      subCategories: dto.subCategories
          .map(
            (item) => ProductSubCategoryOption(
              id: item.id,
              name: item.name,
              code: item.code,
              parentCategoryId: item.parentCategoryId,
            ),
          )
          .toList(),
      brands: dto.brands
          .map(
            (item) => ProductBrandOption(
              id: item.id,
              name: item.name,
              code: item.code,
            ),
          )
          .toList(),
      units: dto.units
          .map(
            (item) => ProductUnitOption(
              id: item.id,
              code: item.code,
              name: item.name,
            ),
          )
          .toList(),
      taxes: dto.taxes
          .map(
            (item) => ProductTaxOption(
              id: item.id,
              code: item.code,
              name: item.name,
            ),
          )
          .toList(),
      outlets: dto.outlets
          .map(
            (item) => ProductOutletOption(
              id: item.id,
              name: item.name,
              code: item.code,
            ),
          )
          .toList(),
      variantOptionTemplates: dto.variantOptionTemplates
          .map(
            (item) => ProductVariantOptionTemplate(
              id: item.id,
              code: item.code,
              name: item.name,
              optionType: item.optionType,
            ),
          )
          .toList(),
    );
  }

  static ProductCreateResult toCreateResult(ProductCreateResponseDto dto) {
    return ProductCreateResult(
      id: dto.id,
      productName: dto.productName,
      sku: dto.sku,
      status: dto.status,
    );
  }

  static TenantProductDetail toDetailEntity(TenantProductDetailDto dto) {
    return TenantProductDetail(
      productId: dto.productId,
      productName: dto.productName,
      sku: dto.sku,
      barcode: dto.barcode,
      categoryId: dto.categoryId,
      categoryName: dto.categoryName,
      subCategoryId: dto.subCategoryId,
      brandId: dto.brandId,
      unitType: dto.unitType,
      shortDescription: dto.shortDescription,
      imageUrl: dto.imageUrl,
      costPrice: dto.costPrice,
      sellingPrice: dto.sellingPrice,
      discountPrice: dto.discountPrice,
      taxId: dto.taxId,
      taxName: dto.taxName,
      status: dto.status,
      trackInventory: dto.trackInventory,
      stock: dto.stock == null ? null : toStockDetailEntity(dto.stock!),
      outlets: dto.outlets.map(toOutletDetailEntity).toList(),
      variants: dto.variants.map(toVariantDetailEntity).toList(),
      batchDetails:
          dto.batchDetails == null ? null : toBatchDetailEntity(dto.batchDetails!),
      createdAt: dto.createdAt,
      updatedAt: dto.updatedAt,
    );
  }

  static TenantProductStockDetail toStockDetailEntity(
    TenantProductStockDetailDto dto,
  ) {
    return TenantProductStockDetail(
      openingStockQuantity: dto.openingStockQuantity,
      minimumStockAlertQuantity: dto.minimumStockAlertQuantity,
      maximumStockQuantity: dto.maximumStockQuantity,
      stockUnit: dto.stockUnit,
      onHandQuantity: dto.onHandQuantity,
      availableQuantity: dto.availableQuantity,
    );
  }

  static TenantProductOutletDetail toOutletDetailEntity(
    TenantProductOutletDetailDto dto,
  ) {
    return TenantProductOutletDetail(
      outletId: dto.outletId,
      outletName: dto.outletName,
      outletCode: dto.outletCode,
      onHandQuantity: dto.onHandQuantity,
      availableQuantity: dto.availableQuantity,
    );
  }

  static TenantProductVariantDetail toVariantDetailEntity(
    TenantProductVariantDetailDto dto,
  ) {
    return TenantProductVariantDetail(
      variantId: dto.variantId,
      variantName: dto.variantName,
      sku: dto.sku,
      barcode: dto.barcode,
      sellingPrice: dto.sellingPrice,
      discountPrice: dto.discountPrice,
      status: dto.status,
    );
  }

  static TenantProductBatchDetail toBatchDetailEntity(
    TenantProductBatchDetailDto dto,
  ) {
    return TenantProductBatchDetail(
      batchNumber: dto.batchNumber,
      manufactureDate: dto.manufactureDate,
      expiryDate: dto.expiryDate,
      expiryAlertDays: dto.expiryAlertDays,
    );
  }

  static ProductStatusUpdateResult toStatusUpdateResult(
    ProductStatusUpdateResponseDto dto,
  ) {
    return ProductStatusUpdateResult(
      productId: dto.productId,
      status: dto.status,
    );
  }

  static ProductDeleteResult toDeleteResult(ProductDeleteResponseDto dto) {
    return ProductDeleteResult(
      productId: dto.productId,
      outcome: dto.outcome,
      status: dto.status,
    );
  }
}

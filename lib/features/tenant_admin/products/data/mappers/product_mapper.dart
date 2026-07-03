import '../../domain/entities/product.dart';
import '../models/product_dto.dart';

class ProductMapper {
  const ProductMapper._();

  static Product toEntity(ProductDto dto) {
    return Product(
      id: dto.id,
      variantId: dto.variantId,
      name: dto.name,
      sku: dto.sku,
      status: dto.status,
      categoryName: dto.categoryName,
      barcode: dto.barcode,
      sellingPrice: dto.sellingPrice,
      outletCount: dto.outletCount,
      createdAt: dto.createdAt,
      imageStorageKey: dto.imageStorageKey,
    );
  }

  static ProductListSummary toSummaryEntity(ProductListSummaryDto dto) {
    return ProductListSummary(
      totalProducts: dto.totalProducts,
      activeProducts: dto.activeProducts,
      inactiveProducts: dto.inactiveProducts,
      productCategories: dto.productCategories,
    );
  }

  static ProductListResult toListResult(ProductListResultDto dto) {
    return ProductListResult(
      summary: toSummaryEntity(dto.summary),
      items: dto.items.map(toEntity).toList(growable: false),
      page: dto.page,
      pageSize: dto.pageSize,
      totalCount: dto.totalCount,
    );
  }

  static CreatedProduct toCreatedEntity(CreatedProductDto dto) {
    return CreatedProduct(
      id: dto.id,
      variantId: dto.variantId,
      name: dto.name,
      sku: dto.sku,
      status: dto.status,
      barcode: dto.barcode,
      sellingPrice: dto.sellingPrice,
    );
  }
}

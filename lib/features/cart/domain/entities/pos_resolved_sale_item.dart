import 'pos_catalog_models.dart';

class PosResolvedSaleItem {
  const PosResolvedSaleItem({
    required this.productId,
    required this.name,
    required this.category,
    required this.unitPrice,
    required this.stockStatus,
    this.variantId,
    this.variantName,
    this.sku,
    this.imageUrl,
    this.availableQuantity,
    this.selectedAttributes = const {},
    this.hasVariants = false,
  });

  factory PosResolvedSaleItem.fromCatalog({
    required PosCatalogProductSummary summary,
    PosCatalogVariant? variant,
  }) {
    return PosResolvedSaleItem(
      productId: summary.productId,
      variantId: variant?.variantId ?? summary.variantId,
      name: summary.name,
      variantName: summary.variantName,
      category: summary.categoryName,
      unitPrice: variant?.price ?? summary.basePrice,
      sku: variant?.sku ?? summary.sku,
      imageUrl: summary.imageUrl,
      stockStatus: variant?.stockStatus ?? summary.stockStatus,
      availableQuantity: variant?.stockQty ?? summary.availableQty,
      selectedAttributes: variant?.attributes ?? const {},
      hasVariants: summary.hasVariants,
    );
  }

  final String productId;
  final String? variantId;
  final String name;
  final String? variantName;
  final String category;
  final int unitPrice;
  final String? sku;
  final String? imageUrl;
  final String stockStatus;
  final double? availableQuantity;
  final Map<String, String> selectedAttributes;
  final bool hasVariants;
}

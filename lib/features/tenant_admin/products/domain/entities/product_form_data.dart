class ProductVariantFormData {
  const ProductVariantFormData({
    this.variantName,
    required this.sku,
    this.barcode,
    required this.sellingPrice,
    this.discountPrice,
    required this.status,
  });

  final String? variantName;
  final String sku;
  final String? barcode;
  final double sellingPrice;
  final double? discountPrice;
  final String status;
}

class ProductFormData {
  const ProductFormData({
    required this.productName,
    required this.sku,
    required this.categoryId,
    required this.unitType,
    required this.sellingPrice,
    required this.trackInventory,
    required this.status,
    this.barcode,
    this.subCategoryId,
    this.brandId,
    this.shortDescription,
    this.longDescription,
    this.taxId,
    this.costPrice,
    this.discountPrice,
    this.openingStockQuantity,
    this.minimumStockAlertQuantity,
    this.maximumStockQuantity,
    this.stockUnit,
    this.outletIds = const [],
    this.hasVariants = false,
    this.variants = const [],
    this.hasExpiryDate = false,
    this.batchNumber,
    this.manufactureDate,
    this.expiryDate,
    this.expiryAlertDays,
    this.saveAsDraft = false,
  });

  final String productName;
  final String sku;
  final String? barcode;
  final String categoryId;
  final String? subCategoryId;
  final String? brandId;
  final String unitType;
  final String? shortDescription;
  final String? longDescription;
  final double sellingPrice;
  final String? taxId;
  final double? costPrice;
  final double? discountPrice;
  final bool trackInventory;
  final double? openingStockQuantity;
  final double? minimumStockAlertQuantity;
  final double? maximumStockQuantity;
  final String? stockUnit;
  final List<String> outletIds;
  final bool hasVariants;
  final List<ProductVariantFormData> variants;
  final bool hasExpiryDate;
  final String? batchNumber;
  final DateTime? manufactureDate;
  final DateTime? expiryDate;
  final int? expiryAlertDays;
  final String status;
  final bool saveAsDraft;
}

class ProductCreateResult {
  const ProductCreateResult({
    required this.id,
    required this.productName,
    required this.sku,
    required this.status,
  });

  final String id;
  final String productName;
  final String sku;
  final String status;
}

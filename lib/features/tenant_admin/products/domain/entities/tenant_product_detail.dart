class TenantProductStockDetail {
  const TenantProductStockDetail({
    this.openingStockQuantity,
    this.minimumStockAlertQuantity,
    this.maximumStockQuantity,
    this.stockUnit,
    required this.onHandQuantity,
    required this.availableQuantity,
  });

  final double? openingStockQuantity;
  final double? minimumStockAlertQuantity;
  final double? maximumStockQuantity;
  final String? stockUnit;
  final double onHandQuantity;
  final double availableQuantity;
}

class TenantProductOutletDetail {
  const TenantProductOutletDetail({
    required this.outletId,
    required this.outletName,
    required this.outletCode,
    required this.onHandQuantity,
    required this.availableQuantity,
  });

  final String outletId;
  final String outletName;
  final String outletCode;
  final double onHandQuantity;
  final double availableQuantity;
}

class TenantProductVariantDetail {
  const TenantProductVariantDetail({
    required this.variantId,
    this.variantName,
    required this.sku,
    this.barcode,
    required this.sellingPrice,
    this.discountPrice,
    required this.status,
  });

  final String variantId;
  final String? variantName;
  final String sku;
  final String? barcode;
  final double sellingPrice;
  final double? discountPrice;
  final String status;
}

class TenantProductBatchDetail {
  const TenantProductBatchDetail({
    required this.batchNumber,
    this.manufactureDate,
    this.expiryDate,
    this.expiryAlertDays,
  });

  final String batchNumber;
  final DateTime? manufactureDate;
  final DateTime? expiryDate;
  final int? expiryAlertDays;
}

class TenantProductDetail {
  const TenantProductDetail({
    required this.productId,
    required this.productName,
    required this.sku,
    required this.categoryId,
    required this.categoryName,
    required this.unitType,
    required this.sellingPrice,
    required this.status,
    required this.trackInventory,
    required this.outlets,
    required this.variants,
    required this.createdAt,
    required this.updatedAt,
    this.barcode,
    this.subCategoryId,
    this.brandId,
    this.shortDescription,
    this.imageUrl,
    this.costPrice,
    this.discountPrice,
    this.taxId,
    this.taxName,
    this.stock,
    this.batchDetails,
  });

  final String productId;
  final String productName;
  final String sku;
  final String? barcode;
  final String categoryId;
  final String categoryName;
  final String? subCategoryId;
  final String? brandId;
  final String unitType;
  final String? shortDescription;
  final String? imageUrl;
  final double? costPrice;
  final double sellingPrice;
  final double? discountPrice;
  final String? taxId;
  final String? taxName;
  final String status;
  final bool trackInventory;
  final TenantProductStockDetail? stock;
  final List<TenantProductOutletDetail> outlets;
  final List<TenantProductVariantDetail> variants;
  final TenantProductBatchDetail? batchDetails;
  final DateTime createdAt;
  final DateTime updatedAt;
}

class ProductVariantRequestDto {
  const ProductVariantRequestDto({
    this.variantName,
    required this.sku,
    this.barcode,
    required this.sellingPrice,
    this.discountPrice,
    this.status,
  });

  final String? variantName;
  final String sku;
  final String? barcode;
  final double sellingPrice;
  final double? discountPrice;
  final String? status;

  Map<String, dynamic> toJson() {
    return {
      if (variantName != null && variantName!.trim().isNotEmpty)
        'variantName': variantName!.trim(),
      'sku': sku.trim(),
      if (barcode != null && barcode!.trim().isNotEmpty)
        'barcode': barcode!.trim(),
      'sellingPrice': sellingPrice,
      if (discountPrice != null) 'discountPrice': discountPrice,
      if (status != null && status!.trim().isNotEmpty) 'status': status!.trim(),
    };
  }
}

class ProductCreateRequestDto {
  const ProductCreateRequestDto({
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
  final List<ProductVariantRequestDto> variants;
  final bool hasExpiryDate;
  final String? batchNumber;
  final String? manufactureDate;
  final String? expiryDate;
  final int? expiryAlertDays;
  final String status;
  final bool saveAsDraft;

  Map<String, dynamic> toJson() {
    return {
      'productName': productName.trim(),
      'sku': sku.trim(),
      if (barcode != null && barcode!.trim().isNotEmpty)
        'barcode': barcode!.trim(),
      'categoryId': categoryId,
      if (subCategoryId != null && subCategoryId!.trim().isNotEmpty)
        'subCategoryId': subCategoryId,
      if (brandId != null && brandId!.trim().isNotEmpty) 'brandId': brandId,
      'unitType': unitType.trim(),
      if (shortDescription != null && shortDescription!.trim().isNotEmpty)
        'shortDescription': shortDescription!.trim(),
      if (costPrice != null) 'costPrice': costPrice,
      'sellingPrice': sellingPrice,
      if (discountPrice != null) 'discountPrice': discountPrice,
      if (taxId != null && taxId!.trim().isNotEmpty) 'taxId': taxId,
      'trackInventory': trackInventory,
      if (trackInventory && openingStockQuantity != null)
        'openingStockQuantity': openingStockQuantity,
      if (trackInventory && minimumStockAlertQuantity != null)
        'minimumStockAlertQuantity': minimumStockAlertQuantity,
      if (trackInventory && maximumStockQuantity != null)
        'maximumStockQuantity': maximumStockQuantity,
      if (trackInventory && stockUnit != null && stockUnit!.trim().isNotEmpty)
        'stockUnit': stockUnit!.trim(),
      if (trackInventory && outletIds.isNotEmpty) 'outletIds': outletIds,
      'hasVariants': hasVariants,
      if (hasVariants && variants.isNotEmpty)
        'variants': variants.map((item) => item.toJson()).toList(),
      'hasExpiryDate': hasExpiryDate,
      if (hasExpiryDate && batchNumber != null && batchNumber!.trim().isNotEmpty)
        'batchNumber': batchNumber!.trim(),
      if (hasExpiryDate && manufactureDate != null)
        'manufactureDate': manufactureDate,
      if (hasExpiryDate && expiryDate != null) 'expiryDate': expiryDate,
      if (hasExpiryDate && expiryAlertDays != null)
        'expiryAlertDays': expiryAlertDays,
      'status': status,
      'saveAsDraft': saveAsDraft,
    };
  }
}

class ProductCreateResponseDto {
  const ProductCreateResponseDto({
    required this.id,
    required this.productName,
    required this.sku,
    required this.status,
  });

  factory ProductCreateResponseDto.fromJson(Map<String, dynamic> json) {
    return ProductCreateResponseDto(
      id: json['productId']?.toString() ?? json['id']?.toString() ?? '',
      productName:
          json['productName'] as String? ?? json['name'] as String? ?? '',
      sku: json['sku'] as String? ?? '',
      status: json['status'] as String? ?? '',
    );
  }

  final String id;
  final String productName;
  final String sku;
  final String status;
}

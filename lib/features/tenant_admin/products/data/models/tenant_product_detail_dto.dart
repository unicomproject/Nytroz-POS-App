class TenantProductDetailDto {
  const TenantProductDetailDto({
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
    this.longDescription,
    this.imageUrl,
    this.costPrice,
    this.discountPrice,
    this.taxId,
    this.taxName,
    this.stock,
    this.batchDetails,
  });

  factory TenantProductDetailDto.fromJson(Map<String, dynamic> json) {
    return TenantProductDetailDto(
      productId: json['productId']?.toString() ?? json['id']?.toString() ?? '',
      productName:
          json['productName'] as String? ?? json['name'] as String? ?? '',
      sku: json['sku'] as String? ?? '',
      barcode: _nullableString(json['barcode']),
      categoryId: json['categoryId']?.toString() ?? '',
      categoryName: json['categoryName'] as String? ?? '',
      subCategoryId: _nullableString(json['subCategoryId']),
      brandId: _nullableString(json['brandId']),
      unitType: json['unitType'] as String? ?? '',
      shortDescription: _nullableString(json['shortDescription']),
      longDescription: _nullableString(json['longDescription']),
      imageUrl: _nullableString(json['imageUrl']),
      costPrice: _doubleValue(json['costPrice']),
      sellingPrice: _doubleValue(json['sellingPrice']) ?? 0,
      discountPrice: _doubleValue(json['discountPrice']),
      taxId: _nullableString(json['taxId']),
      taxName: _nullableString(json['taxName']),
      status: json['status'] as String? ?? '',
      trackInventory: json['trackInventory'] as bool? ?? false,
      stock: json['stock'] is Map
          ? TenantProductStockDetailDto.fromJson(
              Map<String, dynamic>.from(json['stock'] as Map),
            )
          : null,
      outlets: _mapList(
        json['outlets'],
        TenantProductOutletDetailDto.fromJson,
      ),
      variants: _mapList(
        json['variants'],
        TenantProductVariantDetailDto.fromJson,
      ),
      batchDetails: json['batchDetails'] is Map
          ? TenantProductBatchDetailDto.fromJson(
              Map<String, dynamic>.from(json['batchDetails'] as Map),
            )
          : null,
      createdAt: _dateTimeValue(json['createdAt']) ??
          DateTime.fromMillisecondsSinceEpoch(0),
      updatedAt: _dateTimeValue(json['updatedAt']) ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

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
  final String? longDescription;
  final String? imageUrl;
  final double? costPrice;
  final double sellingPrice;
  final double? discountPrice;
  final String? taxId;
  final String? taxName;
  final String status;
  final bool trackInventory;
  final TenantProductStockDetailDto? stock;
  final List<TenantProductOutletDetailDto> outlets;
  final List<TenantProductVariantDetailDto> variants;
  final TenantProductBatchDetailDto? batchDetails;
  final DateTime createdAt;
  final DateTime updatedAt;
}

class TenantProductStockDetailDto {
  const TenantProductStockDetailDto({
    this.openingStockQuantity,
    this.minimumStockAlertQuantity,
    this.maximumStockQuantity,
    this.stockUnit,
    required this.onHandQuantity,
    required this.availableQuantity,
  });

  factory TenantProductStockDetailDto.fromJson(Map<String, dynamic> json) {
    return TenantProductStockDetailDto(
      openingStockQuantity: _doubleValue(json['openingStockQuantity']),
      minimumStockAlertQuantity:
          _doubleValue(json['minimumStockAlertQuantity']),
      maximumStockQuantity: _doubleValue(json['maximumStockQuantity']),
      stockUnit: _nullableString(json['stockUnit']),
      onHandQuantity: _doubleValue(json['onHandQuantity']) ?? 0,
      availableQuantity: _doubleValue(json['availableQuantity']) ?? 0,
    );
  }

  final double? openingStockQuantity;
  final double? minimumStockAlertQuantity;
  final double? maximumStockQuantity;
  final String? stockUnit;
  final double onHandQuantity;
  final double availableQuantity;
}

class TenantProductOutletDetailDto {
  const TenantProductOutletDetailDto({
    required this.outletId,
    required this.outletName,
    required this.outletCode,
    required this.onHandQuantity,
    required this.availableQuantity,
  });

  factory TenantProductOutletDetailDto.fromJson(Map<String, dynamic> json) {
    return TenantProductOutletDetailDto(
      outletId: json['outletId']?.toString() ?? '',
      outletName: json['outletName'] as String? ?? '',
      outletCode: json['outletCode'] as String? ?? '',
      onHandQuantity: _doubleValue(json['onHandQuantity']) ?? 0,
      availableQuantity: _doubleValue(json['availableQuantity']) ?? 0,
    );
  }

  final String outletId;
  final String outletName;
  final String outletCode;
  final double onHandQuantity;
  final double availableQuantity;
}

class TenantProductVariantDetailDto {
  const TenantProductVariantDetailDto({
    required this.variantId,
    this.variantName,
    required this.sku,
    this.barcode,
    required this.sellingPrice,
    this.discountPrice,
    required this.status,
  });

  factory TenantProductVariantDetailDto.fromJson(Map<String, dynamic> json) {
    return TenantProductVariantDetailDto(
      variantId: json['variantId']?.toString() ?? '',
      variantName: _nullableString(json['variantName']),
      sku: json['sku'] as String? ?? '',
      barcode: _nullableString(json['barcode']),
      sellingPrice: _doubleValue(json['sellingPrice']) ?? 0,
      discountPrice: _doubleValue(json['discountPrice']),
      status: json['status'] as String? ?? '',
    );
  }

  final String variantId;
  final String? variantName;
  final String sku;
  final String? barcode;
  final double sellingPrice;
  final double? discountPrice;
  final String status;
}

class TenantProductBatchDetailDto {
  const TenantProductBatchDetailDto({
    required this.batchNumber,
    this.manufactureDate,
    this.expiryDate,
    this.expiryAlertDays,
  });

  factory TenantProductBatchDetailDto.fromJson(Map<String, dynamic> json) {
    return TenantProductBatchDetailDto(
      batchNumber: json['batchNumber'] as String? ?? '',
      manufactureDate: _dateOnlyValue(json['manufactureDate']),
      expiryDate: _dateOnlyValue(json['expiryDate']),
      expiryAlertDays: _intValue(json['expiryAlertDays']),
    );
  }

  final String batchNumber;
  final DateTime? manufactureDate;
  final DateTime? expiryDate;
  final int? expiryAlertDays;
}

List<T> _mapList<T>(
  Object? value,
  T Function(Map<String, dynamic> json) mapper,
) {
  if (value is! List) {
    return const [];
  }

  return value
      .whereType<Map>()
      .map((item) => mapper(Map<String, dynamic>.from(item)))
      .toList();
}

int _intValue(Object? value, {int fallback = 0}) {
  if (value is int) {
    return value;
  }

  if (value is num) {
    return value.toInt();
  }

  return int.tryParse(value?.toString() ?? '') ?? fallback;
}

double? _doubleValue(Object? value) {
  if (value == null) {
    return null;
  }

  if (value is num) {
    return value.toDouble();
  }

  return double.tryParse(value.toString());
}

String? _nullableString(Object? value) {
  final text = value?.toString().trim() ?? '';
  return text.isEmpty ? null : text;
}

DateTime? _dateTimeValue(Object? value) {
  if (value == null) {
    return null;
  }

  if (value is DateTime) {
    return value;
  }

  return DateTime.tryParse(value.toString());
}

DateTime? _dateOnlyValue(Object? value) {
  if (value == null) {
    return null;
  }

  final text = value.toString().trim();
  if (text.isEmpty) {
    return null;
  }

  return DateTime.tryParse(text);
}

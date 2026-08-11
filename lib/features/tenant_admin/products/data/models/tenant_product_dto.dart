class TenantProductListItemDto {
  const TenantProductListItemDto({
    required this.id,
    required this.productCode,
    required this.name,
    required this.sku,
    required this.status,
    this.categoryName,
    this.categoryId,
    this.brandId,
    this.brandName,
    this.variantCount = 1,
    this.priceFrom,
    this.priceTo,
    this.primaryBarcode,
    this.currencyCode,
    this.stockQuantity,
    this.stockStatus,
    this.imageUrl,
    this.rowVersion = 1,
  });

  factory TenantProductListItemDto.fromJson(Map<String, dynamic> json) {
    return TenantProductListItemDto(
      id: json['id']?.toString() ?? '',
      productCode: json['productCode']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      sku: json['sku']?.toString() ?? '',
      status:
          json['productStatus']?.toString() ?? json['status']?.toString() ?? '',
      categoryName: _nullableString(json['categoryName']),
      categoryId: _nullableString(json['categoryId']),
      brandId: _nullableString(json['brandId']),
      brandName: _nullableString(json['brandName']),
      variantCount: _intValue(json['variantCount'], fallback: 1),
      priceFrom: _doubleValue(json['priceFrom']),
      priceTo: _doubleValue(json['priceTo']),
      primaryBarcode: _nullableString(json['primaryBarcode']),
      currencyCode: _nullableString(json['currencyCode']),
      stockQuantity: json['stockQuantity'] != null
          ? _intValue(json['stockQuantity'])
          : null,
      stockStatus: _nullableString(json['stockStatus']),
      imageUrl: _nullableString(json['imageUrl']),
      rowVersion: _intValue(json['rowVersion'], fallback: 1),
    );
  }

  final String id;
  final String productCode;
  final String name;
  final String? categoryName;
  final String? categoryId;
  final String? brandId;
  final String? brandName;
  final int variantCount;
  final double? priceFrom;
  final double? priceTo;
  final String sku;
  final String? primaryBarcode;
  final String? currencyCode;
  final int? stockQuantity;
  final String status;
  final String? stockStatus;
  final String? imageUrl;
  final int rowVersion;
}

class TenantProductListResultDto {
  const TenantProductListResultDto({
    required this.items,
    this.page = 1,
    this.pageSize = 10,
    this.totalCount = 0,
    this.catalogTotalCount = 0,
  });

  factory TenantProductListResultDto.fromJson(Map<String, dynamic> json) {
    final items = _mapList(json['items'], TenantProductListItemDto.fromJson);
    final page = _intValue(json['pageNumber'] ?? json['page'], fallback: 1);
    final pageSize = _intValue(json['pageSize'], fallback: 10);
    final totalCount = _intValue(
      json['totalCount'] ?? json['totalItems'],
      fallback: items.length,
    );
    final catalogTotalCount = _intValue(
      json['catalogTotalCount'] ??
          json['summary']?['catalogTotalCount'] ??
          json['summary']?['totalProducts'] ??
          totalCount,
      fallback: totalCount,
    );

    return TenantProductListResultDto(
      items: items,
      page: page,
      pageSize: pageSize,
      totalCount: totalCount,
      catalogTotalCount: catalogTotalCount,
    );
  }

  final List<TenantProductListItemDto> items;
  final int page;
  final int pageSize;
  final int totalCount;
  final int catalogTotalCount;
}

class TenantProductSummaryDto {
  const TenantProductSummaryDto({
    required this.totalProducts,
    required this.activeProducts,
    required this.inactiveProducts,
    required this.categoryCount,
  });

  factory TenantProductSummaryDto.fromJson(Map<String, dynamic> json) {
    return TenantProductSummaryDto(
      totalProducts: _intValue(json['totalProducts']),
      activeProducts: _intValue(json['activeProducts']),
      inactiveProducts: _intValue(json['inactiveProducts']),
      categoryCount: _intValue(
        json['categoryCount'] ?? json['productCategories'],
      ),
    );
  }

  final int totalProducts;
  final int activeProducts;
  final int inactiveProducts;
  final int categoryCount;
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

class TenantProductListItemDto {
  const TenantProductListItemDto({
    required this.id,
    required this.name,
    required this.sku,
    required this.status,
    required this.stockQuantity,
    this.categoryName,
    this.barcode,
    this.sellingPrice,
    this.currencyCode,
    this.imageUrl,
  });

  factory TenantProductListItemDto.fromJson(Map<String, dynamic> json) {
    return TenantProductListItemDto(
      id: json['productId']?.toString() ?? json['id']?.toString() ?? '',
      name: json['productName'] as String? ?? json['name'] as String? ?? '',
      categoryName: _nullableString(json['categoryName']),
      sku: json['sku'] as String? ?? '',
      barcode: _nullableString(json['barcode']),
      sellingPrice: _doubleValue(json['sellingPrice'] ?? json['price']),
      currencyCode: _nullableString(json['currencyCode']),
      stockQuantity: _intValue(json['stockQuantity']),
      status: json['status'] as String? ?? '',
      imageUrl: _nullableString(json['imageUrl']),
    );
  }

  final String id;
  final String name;
  final String? categoryName;
  final String sku;
  final String? barcode;
  final double? sellingPrice;
  final String? currencyCode;
  final int stockQuantity;
  final String status;
  final String? imageUrl;
}

class TenantProductListResultDto {
  const TenantProductListResultDto({
    required this.items,
    this.page = 1,
    this.pageSize = 10,
    this.totalCount = 0,
  });

  factory TenantProductListResultDto.fromJson(Map<String, dynamic> json) {
    final items = _mapList(json['items'], TenantProductListItemDto.fromJson);
    final page = _intValue(json['page'], fallback: 1);
    final pageSize = _intValue(json['pageSize'], fallback: 10);
    final totalCount = _intValue(
      json['totalItems'] ?? json['totalCount'],
      fallback: items.length,
    );

    return TenantProductListResultDto(
      items: items,
      page: page,
      pageSize: pageSize,
      totalCount: totalCount,
    );
  }

  final List<TenantProductListItemDto> items;
  final int page;
  final int pageSize;
  final int totalCount;
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

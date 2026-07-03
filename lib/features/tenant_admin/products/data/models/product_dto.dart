class ProductDto {
  const ProductDto({
    required this.id,
    required this.variantId,
    required this.name,
    required this.sku,
    required this.status,
    this.categoryName,
    this.barcode,
    this.sellingPrice,
    this.outletCount = 0,
    this.createdAt,
    this.imageStorageKey,
  });

  factory ProductDto.fromJson(Map<String, dynamic> json) {
    return ProductDto(
      id: json['id']?.toString() ?? '',
      variantId: json['variantId']?.toString() ?? '',
      name: json['name'] as String? ?? '',
      sku: json['sku'] as String? ?? '',
      status: json['status'] as String? ?? '',
      categoryName: json['categoryName'] as String?,
      barcode: json['barcode'] as String?,
      sellingPrice: _doubleValue(json['sellingPrice']),
      outletCount: _intValue(json['outletCount']),
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
      imageStorageKey: json['imageStorageKey'] as String?,
    );
  }

  final String id;
  final String variantId;
  final String name;
  final String sku;
  final String status;
  final String? categoryName;
  final String? barcode;
  final double? sellingPrice;
  final int outletCount;
  final DateTime? createdAt;
  final String? imageStorageKey;
}

class ProductListSummaryDto {
  const ProductListSummaryDto({
    required this.totalProducts,
    required this.activeProducts,
    required this.inactiveProducts,
    required this.productCategories,
  });

  factory ProductListSummaryDto.fromJson(Map<String, dynamic> json) {
    return ProductListSummaryDto(
      totalProducts: _intValue(json['totalProducts']),
      activeProducts: _intValue(json['activeProducts']),
      inactiveProducts: _intValue(json['inactiveProducts']),
      productCategories: _intValue(json['productCategories']),
    );
  }

  final int totalProducts;
  final int activeProducts;
  final int inactiveProducts;
  final int productCategories;
}

class ProductListResultDto {
  const ProductListResultDto({
    required this.summary,
    required this.items,
    this.page = 1,
    this.pageSize = 10,
    this.totalCount = 0,
  });

  factory ProductListResultDto.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'];
    final items = rawItems is List
        ? rawItems
            .whereType<Map>()
            .map(
              (item) => ProductDto.fromJson(Map<String, dynamic>.from(item)),
            )
            .toList(growable: false)
        : const <ProductDto>[];

    return ProductListResultDto(
      summary: json['summary'] is Map
          ? ProductListSummaryDto.fromJson(
              Map<String, dynamic>.from(json['summary'] as Map),
            )
          : const ProductListSummaryDto(
              totalProducts: 0,
              activeProducts: 0,
              inactiveProducts: 0,
              productCategories: 0,
            ),
      items: items,
      page: _intValue(json['page'], fallback: 1),
      pageSize: _intValue(json['pageSize'], fallback: 10),
      totalCount: _intValue(json['totalCount'], fallback: items.length),
    );
  }

  final ProductListSummaryDto summary;
  final List<ProductDto> items;
  final int page;
  final int pageSize;
  final int totalCount;
}

class CreatedProductDto {
  const CreatedProductDto({
    required this.id,
    required this.variantId,
    required this.name,
    required this.sku,
    required this.status,
    this.barcode,
    this.sellingPrice,
  });

  factory CreatedProductDto.fromJson(Map<String, dynamic> json) {
    return CreatedProductDto(
      id: json['id']?.toString() ?? '',
      variantId: json['variantId']?.toString() ?? '',
      name: json['name'] as String? ?? '',
      sku: json['sku'] as String? ?? '',
      status: json['status'] as String? ?? '',
      barcode: json['barcode'] as String?,
      sellingPrice: _doubleValue(json['sellingPrice']),
    );
  }

  final String id;
  final String variantId;
  final String name;
  final String sku;
  final String status;
  final String? barcode;
  final double? sellingPrice;
}

int _intValue(Object? value, {int fallback = 0}) {
  if (value is int) {
    return value;
  }

  return int.tryParse(value?.toString() ?? '') ?? fallback;
}

double? _doubleValue(Object? value) {
  if (value is num) {
    return value.toDouble();
  }

  return double.tryParse(value?.toString() ?? '');
}

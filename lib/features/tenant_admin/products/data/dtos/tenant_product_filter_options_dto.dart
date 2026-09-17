import 'tenant_product_create_options_dto.dart';

class TenantProductFilterOptionsDto {
  const TenantProductFilterOptionsDto({
    required this.categories,
    required this.brands,
    required this.productStatuses,
    required this.stockStatuses,
  });

  factory TenantProductFilterOptionsDto.fromJson(Map<String, dynamic> json) {
    return TenantProductFilterOptionsDto(
      categories:
          _mapList(json['categories'], ProductCategoryOptionDto.fromJson),
      brands: _mapList(json['brands'], ProductBrandOptionDto.fromJson),
      productStatuses: _mapStringList(json['productStatuses']),
      stockStatuses: _mapStringList(json['stockStatuses']),
    );
  }

  final List<ProductCategoryOptionDto> categories;
  final List<ProductBrandOptionDto> brands;
  final List<String> productStatuses;
  final List<String> stockStatuses;
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

List<String> _mapStringList(Object? value) {
  if (value is! List) {
    return const [];
  }

  return value
      .map((item) => item?.toString() ?? '')
      .where((item) => item.isNotEmpty)
      .toList();
}

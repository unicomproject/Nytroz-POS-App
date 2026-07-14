class ProductCategoryOptionDto {
  const ProductCategoryOptionDto({
    required this.id,
    required this.name,
    required this.code,
  });

  factory ProductCategoryOptionDto.fromJson(Map<String, dynamic> json) {
    return ProductCategoryOptionDto(
      id: json['categoryId']?.toString() ?? json['id']?.toString() ?? '',
      name: json['categoryName'] as String? ?? json['name'] as String? ?? '',
      code: json['categoryCode'] as String? ?? json['code'] as String? ?? '',
    );
  }

  final String id;
  final String name;
  final String code;
}

class ProductSubCategoryOptionDto {
  const ProductSubCategoryOptionDto({
    required this.id,
    required this.name,
    required this.code,
    required this.parentCategoryId,
  });

  factory ProductSubCategoryOptionDto.fromJson(Map<String, dynamic> json) {
    return ProductSubCategoryOptionDto(
      id: json['subCategoryId']?.toString() ?? json['id']?.toString() ?? '',
      name:
          json['subCategoryName'] as String? ?? json['name'] as String? ?? '',
      code:
          json['subCategoryCode'] as String? ?? json['code'] as String? ?? '',
      parentCategoryId: json['parentCategoryId']?.toString() ?? '',
    );
  }

  final String id;
  final String name;
  final String code;
  final String parentCategoryId;
}

class ProductBrandOptionDto {
  const ProductBrandOptionDto({
    required this.id,
    required this.name,
    required this.code,
  });

  factory ProductBrandOptionDto.fromJson(Map<String, dynamic> json) {
    return ProductBrandOptionDto(
      id: json['brandId']?.toString() ?? json['id']?.toString() ?? '',
      name: json['brandName'] as String? ?? json['name'] as String? ?? '',
      code: json['brandCode'] as String? ?? json['code'] as String? ?? '',
    );
  }

  final String id;
  final String name;
  final String code;
}

class ProductUnitOptionDto {
  const ProductUnitOptionDto({
    required this.id,
    required this.code,
    required this.name,
  });

  factory ProductUnitOptionDto.fromJson(Map<String, dynamic> json) {
    return ProductUnitOptionDto(
      id: json['unitId']?.toString() ?? json['id']?.toString() ?? '',
      code: json['unitCode'] as String? ?? json['code'] as String? ?? '',
      name: json['unitName'] as String? ?? json['name'] as String? ?? '',
    );
  }

  final String id;
  final String code;
  final String name;
}

class ProductTaxOptionDto {
  const ProductTaxOptionDto({
    required this.id,
    required this.code,
    required this.name,
  });

  factory ProductTaxOptionDto.fromJson(Map<String, dynamic> json) {
    return ProductTaxOptionDto(
      id: json['taxId']?.toString() ?? json['id']?.toString() ?? '',
      code: json['taxCode'] as String? ?? json['code'] as String? ?? '',
      name: json['taxName'] as String? ?? json['name'] as String? ?? '',
    );
  }

  final String id;
  final String code;
  final String name;
}

class ProductOutletOptionDto {
  const ProductOutletOptionDto({
    required this.id,
    required this.name,
    required this.code,
  });

  factory ProductOutletOptionDto.fromJson(Map<String, dynamic> json) {
    return ProductOutletOptionDto(
      id: json['outletId']?.toString() ?? json['id']?.toString() ?? '',
      name: json['outletName'] as String? ?? json['name'] as String? ?? '',
      code: json['outletCode'] as String? ?? json['code'] as String? ?? '',
    );
  }

  final String id;
  final String name;
  final String code;
}

class ProductVariantOptionTemplateDto {
  const ProductVariantOptionTemplateDto({
    required this.id,
    required this.code,
    required this.name,
    required this.optionType,
  });

  factory ProductVariantOptionTemplateDto.fromJson(Map<String, dynamic> json) {
    return ProductVariantOptionTemplateDto(
      id: json['templateId']?.toString() ?? json['id']?.toString() ?? '',
      code: json['templateCode'] as String? ?? json['code'] as String? ?? '',
      name: json['templateName'] as String? ?? json['name'] as String? ?? '',
      optionType: json['optionType'] as String? ?? '',
    );
  }

  final String id;
  final String code;
  final String name;
  final String optionType;
}

class TenantProductCreateOptionsDto {
  const TenantProductCreateOptionsDto({
    required this.categories,
    required this.subCategories,
    required this.brands,
    required this.units,
    required this.taxes,
    required this.outlets,
    required this.variantOptionTemplates,
  });

  factory TenantProductCreateOptionsDto.fromJson(Map<String, dynamic> json) {
    return TenantProductCreateOptionsDto(
      categories: _mapList(json['categories'], ProductCategoryOptionDto.fromJson),
      subCategories:
          _mapList(json['subCategories'], ProductSubCategoryOptionDto.fromJson),
      brands: _mapList(json['brands'], ProductBrandOptionDto.fromJson),
      units: _mapList(json['units'], ProductUnitOptionDto.fromJson),
      taxes: _mapList(json['taxes'], ProductTaxOptionDto.fromJson),
      outlets: _mapList(json['outlets'], ProductOutletOptionDto.fromJson),
      variantOptionTemplates: _mapList(
        json['variantOptionTemplates'],
        ProductVariantOptionTemplateDto.fromJson,
      ),
    );
  }

  final List<ProductCategoryOptionDto> categories;
  final List<ProductSubCategoryOptionDto> subCategories;
  final List<ProductBrandOptionDto> brands;
  final List<ProductUnitOptionDto> units;
  final List<ProductTaxOptionDto> taxes;
  final List<ProductOutletOptionDto> outlets;
  final List<ProductVariantOptionTemplateDto> variantOptionTemplates;
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

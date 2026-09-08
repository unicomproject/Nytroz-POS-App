class ProductCategoryOption {
  const ProductCategoryOption({
    required this.id,
    required this.name,
    required this.code,
  });

  final String id;
  final String name;
  final String code;
}

class ProductSubCategoryOption {
  const ProductSubCategoryOption({
    required this.id,
    required this.name,
    required this.code,
    required this.parentCategoryId,
  });

  final String id;
  final String name;
  final String code;
  final String parentCategoryId;
}

class ProductBrandOption {
  const ProductBrandOption({
    required this.id,
    required this.name,
    required this.code,
  });

  final String id;
  final String name;
  final String code;
}

class ProductUnitOption {
  const ProductUnitOption({
    required this.id,
    required this.code,
    required this.name,
    this.unitType,
    this.symbol,
    this.recommendedAllowDecimalQuantity,
  });

  final String id;
  final String code;
  final String name;
  final String? unitType;
  final String? symbol;
  final bool? recommendedAllowDecimalQuantity;
}

class ProductTaxOption {
  const ProductTaxOption({
    required this.id,
    required this.code,
    required this.name,
    this.taxTreatment = 'TAXABLE',
    this.currentRate,
  });

  final String id;
  final String code;
  final String name;
  final String taxTreatment;
  final double? currentRate;

  bool get isExempt => taxTreatment.toUpperCase() == 'EXEMPT';
  bool get isZeroRated => taxTreatment.toUpperCase() == 'ZERO_RATED';

  String get dropdownLabel {
    final treatment = taxTreatment.toUpperCase();
    if (treatment == 'EXEMPT') {
      return '$name — Exempt';
    }
    if (treatment == 'ZERO_RATED') {
      return '$name — 0%';
    }
    final rate = currentRate;
    if (rate == null) return name;
    final rateText = rate.truncateToDouble() == rate
        ? rate.toStringAsFixed(0)
        : rate.toString();
    return '$name — $rateText%';
  }
}

class ProductOutletOption {
  const ProductOutletOption({
    required this.id,
    required this.name,
    required this.code,
  });

  final String id;
  final String name;
  final String code;
}

class ProductVariantOptionTemplate {
  const ProductVariantOptionTemplate({
    required this.id,
    required this.code,
    required this.name,
    required this.optionType,
  });

  final String id;
  final String code;
  final String name;
  final String optionType;
}

class TenantProductCreateOptions {
  const TenantProductCreateOptions({
    required this.categories,
    required this.subCategories,
    required this.brands,
    required this.units,
    required this.taxes,
    required this.outlets,
    required this.variantOptionTemplates,
    this.currencyCode = '',
  });

  final List<ProductCategoryOption> categories;
  final List<ProductSubCategoryOption> subCategories;
  final List<ProductBrandOption> brands;
  final List<ProductUnitOption> units;
  final List<ProductTaxOption> taxes;
  final List<ProductOutletOption> outlets;
  final List<ProductVariantOptionTemplate> variantOptionTemplates;
  final String currencyCode;

  List<ProductSubCategoryOption> subCategoriesForCategory(String? categoryId) {
    if (categoryId == null || categoryId.trim().isEmpty) {
      return const [];
    }

    return subCategories
        .where((item) => item.parentCategoryId == categoryId)
        .toList();
  }
}

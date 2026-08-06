import 'package:nytroz_pos/features/cart/presentation/providers/pos_new_sale_cart_provider.dart';

class PosCatalogCategory {
  const PosCatalogCategory({
    required this.id,
    required this.name,
  });

  final String id;
  final String name;
}

class PosCatalogCategoryOption {
  const PosCatalogCategoryOption({
    required this.name,
    this.id,
  });

  final String? id;
  final String name;

  bool get isAll => id == null;
}

class PosCatalogProductSummary {
  const PosCatalogProductSummary({
    required this.productId,
    required this.name,
    required this.categoryName,
    required this.basePrice,
    required this.hasVariants,
    this.categoryId,
    this.variantId,
    this.sku,
    this.barcode,
    this.variantName,
    this.description,
    this.imageUrl,
    this.stockStatus = 'Unknown',
    this.availableQty,
    this.stockLabel = 'Unavailable',
    this.hasOffer = false,
    this.offerType,
    this.offerPolicyId,
    this.offerName,
    this.originalPrice,
    this.sellingPrice,
    this.offerPrice,
    this.discountLabel,
    this.requiresCartValidation = false,
    this.requiresManagerApproval = false,
  });

  final String productId;
  final String? categoryId;
  final String? variantId;
  final String? sku;
  final String? barcode;
  final String? variantName;
  final String name;
  final String? description;
  final String? imageUrl;
  final String categoryName;
  final int basePrice;
  final bool hasVariants;
  final String stockStatus;
  final double? availableQty;
  final String stockLabel;
  final bool hasOffer;
  final String? offerType;
  final String? offerPolicyId;
  final String? offerName;
  final int? originalPrice;
  final int? sellingPrice;
  final int? offerPrice;
  final String? discountLabel;
  final bool requiresCartValidation;
  final bool requiresManagerApproval;

  bool get isOutOfStock =>
      stockStatus != 'InStock' && stockStatus != 'LowStock';

  bool matches(String query) {
    return productId.toLowerCase().contains(query) ||
        (sku?.toLowerCase().contains(query) ?? false) ||
        (barcode?.toLowerCase().contains(query) ?? false) ||
        name.toLowerCase().contains(query) ||
        categoryName.toLowerCase().contains(query);
  }
}

class PosCatalogVariantGroup {
  const PosCatalogVariantGroup({
    required this.name,
    required this.options,
    this.optionId = '',
    this.code = '',
    this.inputType = 'CHIP',
    this.isRequired = true,
    this.sortOrder = 0,
    this.values = const [],
  });

  final String name;
  final List<String> options;
  final String optionId;
  final String code;
  final String inputType;
  final bool isRequired;
  final int sortOrder;
  final List<PosCatalogOptionValue> values;
}

class PosCatalogOptionValue {
  const PosCatalogOptionValue({
    required this.optionValueId,
    required this.code,
    required this.displayName,
    this.colorHex,
    this.sortOrder = 0,
  });

  final String optionValueId;
  final String code;
  final String displayName;
  final String? colorHex;
  final int sortOrder;
}

class PosCatalogVariant {
  const PosCatalogVariant({
    required this.variantId,
    required this.sku,
    required this.price,
    required this.stockStatus,
    required this.attributes,
    this.stockQty,
    this.variantCode = '',
    this.variantName = '',
    this.selectedOptionValueIds = const [],
    this.isDefault = false,
    this.isSelectable = true,
    this.unavailableReason,
    this.salesUomId = '',
    this.salesUomCode = '',
    this.allowFractionalQuantity = false,
    this.authoritativePrice,
    this.currency = 'LKR',
    this.isStockTracked = true,
    this.imageUrl,
  });

  final String variantId;
  final String sku;
  final int price;
  final double? stockQty;
  final String stockStatus;
  final Map<String, String> attributes;
  final String variantCode;
  final String variantName;
  final List<String> selectedOptionValueIds;
  final bool isDefault;
  final bool isSelectable;
  final String? unavailableReason;
  final String salesUomId;
  final String salesUomCode;
  final bool allowFractionalQuantity;
  final double? authoritativePrice;
  final String currency;
  final bool isStockTracked;
  final String? imageUrl;

  bool get isOutOfStock =>
      stockStatus != 'InStock' && stockStatus != 'LowStock';

  bool get isLowStock => stockStatus == 'LowStock';
}

class PosCatalogProductDetail {
  const PosCatalogProductDetail({
    required this.summary,
    required this.variantGroups,
    required this.variants,
    this.productCode = '',
    this.currency = 'LKR',
    this.requiresConfiguration = false,
  });

  final PosCatalogProductSummary summary;
  final List<PosCatalogVariantGroup> variantGroups;
  final List<PosCatalogVariant> variants;
  final String productCode;
  final String currency;
  final bool requiresConfiguration;

  PosCatalogVariant? matchVariantIds(Set<String> selectedValueIds) {
    final requiredCount =
        variantGroups.where((group) => group.isRequired).length;
    if (selectedValueIds.length < requiredCount) return null;
    final matches = variants
        .where((variant) =>
            variant.isSelectable &&
            variant.selectedOptionValueIds.length == selectedValueIds.length &&
            variant.selectedOptionValueIds
                .toSet()
                .containsAll(selectedValueIds))
        .toList();
    return matches.length == 1 ? matches.single : null;
  }

  PosCatalogVariant? matchVariant(Map<String, String> selectedAttributes) {
    if (selectedAttributes.length != variantGroups.length) {
      return null;
    }

    for (final variant in variants) {
      var matches = true;
      for (final entry in selectedAttributes.entries) {
        if (variant.attributes[entry.key] != entry.value) {
          matches = false;
          break;
        }
      }
      if (matches) {
        return variant;
      }
    }

    return null;
  }
}

class PosProductRecommendation {
  const PosProductRecommendation({
    required this.relationshipId,
    required this.productId,
    required this.productName,
    this.categoryName,
    required this.hasVariants,
    required this.requiresConfiguration,
    required this.stockStatus,
    required this.isSelectable,
    this.variantId,
    this.variantName,
    this.imageUrl,
    this.price,
    this.currency = '',
    this.availableQuantity,
    this.unavailableReason,
  });
  final String relationshipId, productId, productName, stockStatus, currency;
  final String? categoryName,
      variantId,
      variantName,
      imageUrl,
      unavailableReason;
  final bool hasVariants, requiresConfiguration, isSelectable;
  final double? price, availableQuantity;
}

PosNewSaleProduct toCartProduct({
  required PosCatalogProductSummary summary,
  required PosCatalogVariant? variant,
  required int quantity,
  String? lineNote,
  String source = 'product_popup',
  String? recommendationParentProductId,
  String? recommendationRelationshipId,
}) {
  final unitPrice = variant?.price ?? summary.basePrice;
  final attributes = variant?.attributes ?? const <String, String>{};
  final variantId = variant?.variantId ?? summary.variantId;
  final cartKey = variantId ?? summary.productId;

  return PosNewSaleProduct(
    id: cartKey,
    productId: summary.productId,
    variantId: variantId,
    name: summary.name,
    category: summary.categoryName,
    price: unitPrice,
    stockLabel: _stockLabelForVariant(variant, summary.stockLabel),
    stockStatus: variant?.stockStatus ?? summary.stockStatus,
    hasVariants: summary.hasVariants,
    sku: variant?.sku ?? summary.sku,
    imageUrl: summary.imageUrl,
    selectedAttributes: attributes,
    maxQuantity: variant?.stockQty?.floor() ?? summary.availableQty?.floor(),
    uomId: variant?.salesUomId,
    lineNote: lineNote,
    source: source,
    recommendationParentProductId: recommendationParentProductId,
    recommendationRelationshipId: recommendationRelationshipId,
    authoritativePrice: variant?.authoritativePrice,
  );
}

double parseDecimal(dynamic value) => value is num
    ? value.toDouble()
    : double.tryParse(value?.toString() ?? '') ?? 0;

String _stockLabelForVariant(PosCatalogVariant? variant, String fallback) {
  if (variant == null) {
    return fallback;
  }

  return switch (variant.stockStatus) {
    'OutOfStock' => 'Out of Stock',
    'LowStock' => 'Low Stock',
    'InStock' => 'In Stock',
    _ => 'Unavailable',
  };
}

String formatVariantSummary(Map<String, String> attributes) {
  if (attributes.isEmpty) {
    return '';
  }

  return attributes.values.join(' / ');
}

int parsePriceToInt(dynamic value) {
  if (value is int) {
    return value;
  }

  if (value is num) {
    return value.round();
  }

  if (value is String) {
    return double.tryParse(value)?.round() ?? 0;
  }

  return 0;
}

String stockStatusFromApi(String? value) {
  return switch (value) {
    'out_of_stock' || 'OutOfStock' => 'OutOfStock',
    'low_stock' || 'LowStock' => 'LowStock',
    'in_stock' || 'InStock' => 'InStock',
    _ => 'Unknown',
  };
}

String stockLabelFromApi(String? stockStatus, num? availableQty) {
  final normalized = stockStatusFromApi(stockStatus);

  return switch (normalized) {
    'OutOfStock' => 'Out of Stock',
    'LowStock' =>
      availableQty != null ? '${availableQty.floor()} in stock' : 'Low Stock',
    'InStock' => availableQty != null && availableQty > 0
        ? '${availableQty.floor()} in stock'
        : 'In Stock',
    _ => 'Unavailable',
  };
}

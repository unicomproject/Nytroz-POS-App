import 'package:nytroz_pos/features/cart/presentation/providers/pos_new_sale_cart_provider.dart';

class PosCatalogProductSummary {
  const PosCatalogProductSummary({
    required this.productId,
    required this.name,
    required this.categoryName,
    required this.basePrice,
    required this.hasVariants,
    this.variantId,
    this.description,
    this.imageUrl,
    this.stockLabel = 'In Stock',
  });

  final String productId;
  final String? variantId;
  final String name;
  final String? description;
  final String? imageUrl;
  final String categoryName;
  final int basePrice;
  final bool hasVariants;
  final String stockLabel;

  bool matches(String query) {
    return productId.toLowerCase().contains(query) ||
        name.toLowerCase().contains(query) ||
        categoryName.toLowerCase().contains(query);
  }
}

class PosCatalogVariantGroup {
  const PosCatalogVariantGroup({
    required this.name,
    required this.options,
  });

  final String name;
  final List<String> options;
}

class PosCatalogVariant {
  const PosCatalogVariant({
    required this.variantId,
    required this.sku,
    required this.price,
    required this.stockStatus,
    required this.attributes,
    this.stockQty,
  });

  final String variantId;
  final String sku;
  final int price;
  final double? stockQty;
  final String stockStatus;
  final Map<String, String> attributes;

  bool get isOutOfStock => stockStatus == 'OutOfStock';

  bool get isLowStock => stockStatus == 'LowStock';
}

class PosCatalogProductDetail {
  const PosCatalogProductDetail({
    required this.summary,
    required this.variantGroups,
    required this.variants,
  });

  final PosCatalogProductSummary summary;
  final List<PosCatalogVariantGroup> variantGroups;
  final List<PosCatalogVariant> variants;

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

PosNewSaleProduct toCartProduct({
  required PosCatalogProductSummary summary,
  required PosCatalogVariant? variant,
  required int quantity,
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
    hasVariants: summary.hasVariants,
    sku: variant?.sku,
    selectedAttributes: attributes,
    maxQuantity: variant?.stockQty?.floor(),
  );
}

String _stockLabelForVariant(PosCatalogVariant? variant, String fallback) {
  if (variant == null) {
    return fallback;
  }

  return switch (variant.stockStatus) {
    'OutOfStock' => 'Out of Stock',
    'LowStock' => 'Low Stock',
    _ => 'In Stock',
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
    _ => 'InStock',
  };
}

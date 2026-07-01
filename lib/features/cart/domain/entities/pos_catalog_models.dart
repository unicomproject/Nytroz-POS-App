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
    this.stockLabel = 'In Stock',
    this.variantSearchTerms = const [],
    this.directSearchTerms = const [],
    this.imageUrl,
  });

  final String productId;
  final String? variantId;
  final String name;
  final String? description;
  final String categoryName;
  final int basePrice;
  final bool hasVariants;
  final String stockLabel;
  final List<String> variantSearchTerms;
  final List<String> directSearchTerms;
  final String? imageUrl;

  bool matches(String query) {
    final normalizedQuery = normalizeSearchQuery(query);
    if (normalizedQuery.isEmpty) {
      return true;
    }

    if (_containsExactTerm(directSearchTerms, normalizedQuery)) {
      return true;
    }

    final terms = searchTerms(normalizedQuery);
    if (terms.isEmpty) {
      return true;
    }

    final productName = name.toLowerCase();
    if (productName.contains(normalizedQuery)) {
      return true;
    }

    final productNameTerms =
        terms.where((term) => productName.contains(term)).toSet();
    if (productNameTerms.isEmpty) {
      return false;
    }

    final remainingTerms =
        terms.where((term) => !productNameTerms.contains(term)).toList();
    if (remainingTerms.isEmpty) {
      return true;
    }

    final normalizedVariantTerms =
        variantSearchTerms.map((term) => term.toLowerCase()).toList();
    return remainingTerms.every(
      (term) => normalizedVariantTerms.any(
        (variantTerm) => variantTerm.contains(term),
      ),
    );
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

  Map<String, String> matchingVariantAttributesForSearchQuery(String query) {
    final normalizedQuery = normalizeSearchQuery(query);
    if (normalizedQuery.isEmpty) {
      return const {};
    }

    final terms = searchTerms(normalizedQuery);
    final productName = summary.name.toLowerCase();
    if (productName.contains(normalizedQuery)) {
      return const {};
    }

    final productNameTerms = terms
        .where((term) => productName.contains(term))
        .toList(growable: false);
    if (productNameTerms.isEmpty) {
      return const {};
    }

    final remainingTerms = terms
        .where((term) => !productNameTerms.contains(term))
        .toList(growable: false);

    if (remainingTerms.isEmpty) {
      return const {};
    }

    for (final variant in variants) {
      final variantTerms = [
        variant.sku,
        ...variant.attributes.values,
      ].map((term) => term.toLowerCase()).toList();

      final matches = remainingTerms.every(
        (term) => variantTerms.any((variantTerm) => variantTerm.contains(term)),
      );

      if (matches) {
        return variant.attributes;
      }
    }

    return const {};
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
    imageUrl: summary.imageUrl,
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

String normalizeSearchQuery(String query) {
  return query.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
}

List<String> searchTerms(String query) {
  final normalized = normalizeSearchQuery(query);
  if (normalized.isEmpty) {
    return const [];
  }

  return normalized
      .split(' ')
      .where((term) => term.isNotEmpty)
      .toSet()
      .toList(growable: false);
}

bool _containsExactTerm(List<String> terms, String query) {
  return terms.any((term) => normalizeSearchQuery(term) == query);
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

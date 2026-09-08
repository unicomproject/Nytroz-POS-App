/// Per-variant selling price for VARIANT Product Setup Step 6.
///
/// Wire JSON keys match backend `VariantPriceConfigurationDto` /
/// `VariantPriceResponseDto` (camelCase).
class VariantPriceDto {
  final String? productVariantId;
  final String? clientCombinationKey;
  final num? sellingPrice;
  final String? displayName;
  final String? sku;

  const VariantPriceDto({
    this.productVariantId,
    this.clientCombinationKey,
    this.sellingPrice,
    this.displayName,
    this.sku,
  });

  factory VariantPriceDto.fromJson(Map<String, dynamic> json) {
    return VariantPriceDto(
      productVariantId: json['productVariantId']?.toString(),
      clientCombinationKey: json['clientCombinationKey']?.toString(),
      sellingPrice: json['sellingPrice'] as num?,
      displayName: json['displayName']?.toString(),
      sku: json['sku']?.toString(),
    );
  }

  /// Always includes [sellingPrice] even when null so backend full-snapshot
  /// can clear a row to PENDING.
  Map<String, dynamic> toSnapshotJson() {
    return {
      if (productVariantId != null && productVariantId!.trim().isNotEmpty)
        'productVariantId': productVariantId,
      if (clientCombinationKey != null &&
          clientCombinationKey!.trim().isNotEmpty)
        'clientCombinationKey': clientCombinationKey,
      'sellingPrice': sellingPrice,
    };
  }

  Map<String, dynamic> toJson() => toSnapshotJson();

  String get identityKey {
    final id = productVariantId?.trim();
    if (id != null && id.isNotEmpty) return 'id:$id';
    final key = clientCombinationKey?.trim();
    if (key != null && key.isNotEmpty) return 'key:$key';
    return 'unknown';
  }

  bool get isPriced => sellingPrice != null && sellingPrice! > 0;

  VariantPriceDto copyWith({
    String? productVariantId,
    String? clientCombinationKey,
    num? sellingPrice,
    bool clearSellingPrice = false,
    String? displayName,
    String? sku,
  }) {
    return VariantPriceDto(
      productVariantId: productVariantId ?? this.productVariantId,
      clientCombinationKey: clientCombinationKey ?? this.clientCombinationKey,
      sellingPrice:
          clearSellingPrice ? null : (sellingPrice ?? this.sellingPrice),
      displayName: displayName ?? this.displayName,
      sku: sku ?? this.sku,
    );
  }
}

class PricingTaxConfigurationDto {
  final num? costPrice;
  final num? standardSellingPrice;
  final num? discountPrice;
  final String? taxId;
  final num? taxRate;
  final bool taxExclusive;

  /// When non-null, VARIANT full-snapshot pricing graph.
  final List<VariantPriceDto>? variantPrices;

  const PricingTaxConfigurationDto({
    this.costPrice,
    this.standardSellingPrice,
    this.discountPrice,
    this.taxId,
    this.taxRate,
    this.taxExclusive = true,
    this.variantPrices,
  });

  factory PricingTaxConfigurationDto.fromJson(Map<String, dynamic> json) {
    final rawVariants = json['variantPrices'];
    return PricingTaxConfigurationDto(
      costPrice: json['costPrice'] as num?,
      standardSellingPrice: json['standardSellingPrice'] as num?,
      discountPrice: json['discountPrice'] as num?,
      taxId: json['taxId']?.toString() ?? json['taxClassId']?.toString(),
      taxRate: json['taxRate'] as num? ?? json['taxRatePercentage'] as num?,
      taxExclusive: json['taxExclusive'] as bool? ?? true,
      variantPrices: rawVariants is List
          ? rawVariants
              .whereType<Map>()
              .map(
                  (e) => VariantPriceDto.fromJson(Map<String, dynamic>.from(e)))
              .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (costPrice != null) 'costPrice': costPrice,
      if (standardSellingPrice != null)
        'standardSellingPrice': standardSellingPrice,
      if (discountPrice != null) 'discountPrice': discountPrice,
      if (taxId != null) 'taxId': taxId,
      if (taxId != null) 'taxClassId': taxId,
      if (taxRate != null) 'taxRate': taxRate,
      'taxExclusive': taxExclusive,
      if (variantPrices != null)
        'variantPrices': variantPrices!.map((e) => e.toSnapshotJson()).toList(),
    };
  }
}

class PricingTaxConfigurationResponseDto {
  final num? costPrice;
  final num? standardSellingPrice;
  final num? discountPrice;
  final String? taxId;
  final String? taxName;
  final num? taxRate;
  final bool taxExclusive;
  final List<VariantPriceDto>? variantPrices;
  final int? pricedVariantCount;
  final int? pendingVariantCount;
  final num? priceFrom;
  final num? priceTo;

  const PricingTaxConfigurationResponseDto({
    this.costPrice,
    this.standardSellingPrice,
    this.discountPrice,
    this.taxId,
    this.taxName,
    this.taxRate,
    this.taxExclusive = true,
    this.variantPrices,
    this.pricedVariantCount,
    this.pendingVariantCount,
    this.priceFrom,
    this.priceTo,
  });

  factory PricingTaxConfigurationResponseDto.fromJson(
    Map<String, dynamic> json,
  ) {
    final rawVariants = json['variantPrices'];
    return PricingTaxConfigurationResponseDto(
      costPrice: json['costPrice'] as num?,
      standardSellingPrice: json['standardSellingPrice'] as num?,
      discountPrice: json['discountPrice'] as num?,
      taxId: json['taxId']?.toString() ?? json['taxClassId']?.toString(),
      taxName: json['taxName']?.toString(),
      taxRate: json['taxRate'] as num? ?? json['taxRatePercentage'] as num?,
      taxExclusive: json['taxExclusive'] as bool? ?? true,
      variantPrices: rawVariants is List
          ? rawVariants
              .whereType<Map>()
              .map(
                  (e) => VariantPriceDto.fromJson(Map<String, dynamic>.from(e)))
              .toList()
          : null,
      pricedVariantCount: (json['pricedVariantCount'] as num?)?.toInt(),
      pendingVariantCount: (json['pendingVariantCount'] as num?)?.toInt(),
      priceFrom: json['priceFrom'] as num?,
      priceTo: json['priceTo'] as num?,
    );
  }
}

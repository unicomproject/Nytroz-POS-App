class PricingTaxConfigurationDto {
  final num? costPrice;
  final num? standardSellingPrice;
  final num? discountPrice;
  final String? taxId;
  final num? taxRate;
  final bool taxExclusive;

  const PricingTaxConfigurationDto({
    this.costPrice,
    this.standardSellingPrice,
    this.discountPrice,
    this.taxId,
    this.taxRate,
    this.taxExclusive = true,
  });

  factory PricingTaxConfigurationDto.fromJson(Map<String, dynamic> json) {
    return PricingTaxConfigurationDto(
      costPrice: json['costPrice'] as num?,
      standardSellingPrice: json['standardSellingPrice'] as num?,
      discountPrice: json['discountPrice'] as num?,
      taxId: json['taxId']?.toString(),
      taxRate: json['taxRate'] as num?,
      taxExclusive: json['taxExclusive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (costPrice != null) 'costPrice': costPrice,
      if (standardSellingPrice != null) 'standardSellingPrice': standardSellingPrice,
      if (discountPrice != null) 'discountPrice': discountPrice,
      if (taxId != null) 'taxId': taxId,
      if (taxRate != null) 'taxRate': taxRate,
      'taxExclusive': taxExclusive,
    };
  }
}

class PricingTaxConfigurationResponseDto {
  final num? costPrice;
  final num? standardSellingPrice;
  final num? discountPrice;
  final String? taxId;
  final num? taxRate;
  final bool taxExclusive;

  const PricingTaxConfigurationResponseDto({
    this.costPrice,
    this.standardSellingPrice,
    this.discountPrice,
    this.taxId,
    this.taxRate,
    this.taxExclusive = true,
  });

  factory PricingTaxConfigurationResponseDto.fromJson(Map<String, dynamic> json) {
    return PricingTaxConfigurationResponseDto(
      costPrice: json['costPrice'] as num?,
      standardSellingPrice: json['standardSellingPrice'] as num?,
      discountPrice: json['discountPrice'] as num?,
      taxId: json['taxId']?.toString(),
      taxRate: json['taxRate'] as num?,
      taxExclusive: json['taxExclusive'] as bool? ?? true,
    );
  }
}

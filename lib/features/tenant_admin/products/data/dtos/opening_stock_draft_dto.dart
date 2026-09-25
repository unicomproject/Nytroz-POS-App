class OpeningStockDraftDto {
  final List<OpeningStockOwnerDraftDto> stockOwners;

  const OpeningStockDraftDto({
    required this.stockOwners,
  });

  Map<String, dynamic> toJson() {
    return {
      'stockOwners': stockOwners.map((e) => e.toJson()).toList(),
    };
  }

  factory OpeningStockDraftDto.fromJson(Map<String, dynamic> json) {
    return OpeningStockDraftDto(
      stockOwners: (json['stockOwners'] as List?)
              ?.map((e) => OpeningStockOwnerDraftDto.fromJson(
                  e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class OpeningStockOwnerDraftDto {
  final String? variantId;
  final num openingQuantity;
  final List<OutletAllocationDraftDto> allocations;

  const OpeningStockOwnerDraftDto({
    this.variantId,
    required this.openingQuantity,
    required this.allocations,
  });

  Map<String, dynamic> toJson() {
    return {
      if (variantId != null && variantId!.isNotEmpty) 'variantId': variantId,
      'openingQuantity': openingQuantity,
      'allocations': allocations.map((e) => e.toJson()).toList(),
    };
  }

  factory OpeningStockOwnerDraftDto.fromJson(Map<String, dynamic> json) {
    return OpeningStockOwnerDraftDto(
      variantId: json['variantId'] as String?,
      openingQuantity: json['openingQuantity'] as num? ?? 0,
      allocations: (json['allocations'] as List?)
              ?.map((e) => OutletAllocationDraftDto.fromJson(
                  e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class OutletAllocationDraftDto {
  final String outletId;
  final num quantity;

  const OutletAllocationDraftDto({
    required this.outletId,
    required this.quantity,
  });

  Map<String, dynamic> toJson() {
    return {
      'outletId': outletId,
      'quantity': quantity,
    };
  }

  factory OutletAllocationDraftDto.fromJson(Map<String, dynamic> json) {
    return OutletAllocationDraftDto(
      outletId: json['outletId'] as String? ?? '',
      quantity: json['quantity'] as num? ?? 0,
    );
  }
}

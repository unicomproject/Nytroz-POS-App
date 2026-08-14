class OpeningStockLineRequestDto {
  const OpeningStockLineRequestDto({
    required this.productId,
    this.variantId,
    required this.quantity,
    required this.unitCost,
    this.batchNumber,
    this.expiryDate,
  });

  final String productId;
  final String? variantId;
  final double quantity;
  final double unitCost;
  final String? batchNumber;
  final String? expiryDate;

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      if (variantId != null) 'variantId': variantId,
      'quantity': quantity,
      'unitCost': unitCost,
      if (batchNumber != null && batchNumber!.isNotEmpty)
        'batchNumber': batchNumber,
      if (expiryDate != null && expiryDate!.isNotEmpty)
        'expiryDate': expiryDate,
    };
  }
}

class OpeningStockRequestDto {
  const OpeningStockRequestDto({
    required this.outletId,
    this.notes,
    required this.items,
    this.idempotencyKey,
  });

  final String outletId;
  final String? notes;
  final List<OpeningStockLineRequestDto> items;
  final String? idempotencyKey;

  Map<String, dynamic> toJson() {
    return {
      'outletId': outletId,
      if (notes != null && notes!.isNotEmpty) 'notes': notes,
      'items': items.map((x) => x.toJson()).toList(),
      if (idempotencyKey != null) 'idempotencyKey': idempotencyKey,
    };
  }
}

class OpeningStockResponseDto {
  const OpeningStockResponseDto({
    required this.stockMovementId,
    required this.outletId,
    required this.movementType,
    required this.itemCount,
    required this.createdAt,
  });

  final String stockMovementId;
  final String outletId;
  final String movementType;
  final int itemCount;
  final String createdAt;

  factory OpeningStockResponseDto.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? json;

    return OpeningStockResponseDto(
      stockMovementId: data['stockMovementId']?.toString() ?? '',
      outletId: data['outletId']?.toString() ?? '',
      movementType: data['movementType']?.toString() ?? 'OpeningStock',
      itemCount: (data['itemCount'] as num?)?.toInt() ?? 0,
      createdAt:
          data['createdAt']?.toString() ?? DateTime.now().toIso8601String(),
    );
  }
}

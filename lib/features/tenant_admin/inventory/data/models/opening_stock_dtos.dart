class OpeningStockRequestDto {
  const OpeningStockRequestDto({
    required this.outletId,
    this.notes,
    required this.lines,
  });

  final String outletId;
  final String? notes;
  final List<OpeningStockLineRequestDto> lines;

  Map<String, dynamic> toJson() {
    return {
      'outletId': outletId,
      'notes': notes,
      'lines': lines.map((line) => line.toJson()).toList(),
    };
  }
}

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
  final num quantity;
  final num unitCost;
  final String? batchNumber;
  final String? expiryDate;

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'variantId': variantId,
      'quantity': quantity,
      'unitCost': unitCost,
      'batchNumber': batchNumber,
      'expiryDate': expiryDate,
    };
  }
}

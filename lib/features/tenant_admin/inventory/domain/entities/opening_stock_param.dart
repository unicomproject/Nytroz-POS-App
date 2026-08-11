class OpeningStockLineParam {
  const OpeningStockLineParam({
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
}

class OpeningStockParam {
  const OpeningStockParam({
    required this.outletId,
    this.notes,
    required this.items,
  });

  final String outletId;
  final String? notes;
  final List<OpeningStockLineParam> items;
}

class OpeningStockResult {
  const OpeningStockResult({
    required this.stockMovementId,
    required this.outletId,
    required this.itemCount,
    required this.createdAt,
  });

  final String stockMovementId;
  final String outletId;
  final int itemCount;
  final String createdAt;
}

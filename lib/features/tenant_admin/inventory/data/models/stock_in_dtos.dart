class CreateStockInRequestDto {
  const CreateStockInRequestDto({
    this.outletId,
    this.referenceNumber,
    this.receivedAt,
    this.notes,
    this.idempotencyKey,
    this.items = const [],
  });

  final String? outletId;
  final String? referenceNumber;
  final String? receivedAt;
  final String? notes;
  final String? idempotencyKey;
  final List<StockInLineRequestDto> items;

  Map<String, dynamic> toJson() {
    return {
      if (outletId != null) 'outletId': outletId,
      if (referenceNumber != null) 'referenceNumber': referenceNumber,
      if (receivedAt != null) 'receivedAt': receivedAt,
      if (notes != null) 'notes': notes,
      if (idempotencyKey != null) 'idempotencyKey': idempotencyKey,
      'items': items.map((i) => i.toJson()).toList(),
    };
  }
}

class StockInLineRequestDto {
  const StockInLineRequestDto({
    this.productVariantId,
    this.barcode,
    this.batchNumber,
    this.manufacturedDate,
    this.expiryDate,
    this.quantity,
    this.unitCost,
  });

  final String? productVariantId;
  final String? barcode;
  final String? batchNumber;
  final String? manufacturedDate;
  final String? expiryDate;
  final int? quantity;
  final double? unitCost;

  Map<String, dynamic> toJson() {
    return {
      if (productVariantId != null) 'productVariantId': productVariantId,
      if (barcode != null) 'barcode': barcode,
      if (batchNumber != null) 'batchNumber': batchNumber,
      if (manufacturedDate != null) 'manufacturedDate': manufacturedDate,
      if (expiryDate != null) 'expiryDate': expiryDate,
      if (quantity != null) 'quantity': quantity,
      if (unitCost != null) 'unitCost': unitCost,
    };
  }
}

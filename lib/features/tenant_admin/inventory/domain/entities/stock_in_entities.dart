class StockInFormInput {
  const StockInFormInput({
    this.outletId,
    this.referenceNumber,
    this.notes,
    this.receivedAt,
    this.items = const [],
  });

  final String? outletId;
  final String? referenceNumber;
  final String? notes;
  final DateTime? receivedAt;
  final List<StockInLineInput> items;
}

class StockInLineInput {
  const StockInLineInput({
    this.productVariantId,
    this.quantity,
    this.batchNumber,
    this.manufacturedDate,
    this.expiryDate,
  });

  final String? productVariantId;
  final int? quantity;
  final String? batchNumber;
  final DateTime? manufacturedDate;
  final DateTime? expiryDate;
}

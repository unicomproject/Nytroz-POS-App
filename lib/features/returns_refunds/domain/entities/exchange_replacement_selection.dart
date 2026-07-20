class ExchangeReplacementSelection {
  const ExchangeReplacementSelection({
    required this.productId,
    required this.productVariantId,
    required this.productName,
    required this.variantDisplayName,
    required this.quantity,
    required this.unitPrice,
    required this.currencyCode,
    this.imageUrl,
    this.sku,
    this.stockStatus = 'InStock',
    this.availableQty,
  });

  final String productId;
  final String productVariantId;
  final String productName;
  final String? imageUrl;
  final String variantDisplayName;
  final String? sku;
  final int quantity;
  final double unitPrice;
  final String currencyCode;
  final String stockStatus;
  final double? availableQty;

  double get lineTotal => unitPrice * quantity;

  bool get isSelectable =>
      stockStatus != 'OutOfStock' &&
      (availableQty == null || availableQty! > 0);

  String get selectionKey => '$productId::$productVariantId';

  ExchangeReplacementSelection copyWith({
    int? quantity,
  }) {
    return ExchangeReplacementSelection(
      productId: productId,
      productVariantId: productVariantId,
      productName: productName,
      imageUrl: imageUrl,
      variantDisplayName: variantDisplayName,
      sku: sku,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice,
      currencyCode: currencyCode,
      stockStatus: stockStatus,
      availableQty: availableQty,
    );
  }
}

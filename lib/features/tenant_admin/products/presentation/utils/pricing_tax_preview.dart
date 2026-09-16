class Step6TaxPreview {
  const Step6TaxPreview({
    required this.netPrice,
    required this.taxAmount,
    required this.finalPrice,
    required this.ratePercent,
    required this.taxExclusive,
  });

  final double netPrice;
  final double taxAmount;
  final double finalPrice;
  final double ratePercent;
  final bool taxExclusive;
}

/// Client-side Tax Preview for SIMPLE Step 6.
/// Server remains authoritative for persisted tax amounts at sale time.
Step6TaxPreview computeStep6TaxPreview({
  required double sellingPrice,
  required double ratePercent,
  required bool taxExclusive,
  bool isExempt = false,
}) {
  final price = sellingPrice.isFinite && sellingPrice > 0 ? sellingPrice : 0.0;
  if (isExempt || ratePercent <= 0) {
    return Step6TaxPreview(
      netPrice: price,
      taxAmount: 0,
      finalPrice: price,
      ratePercent: isExempt ? 0 : ratePercent,
      taxExclusive: taxExclusive,
    );
  }

  if (taxExclusive) {
    final tax = price * ratePercent / 100;
    return Step6TaxPreview(
      netPrice: price,
      taxAmount: tax,
      finalPrice: price + tax,
      ratePercent: ratePercent,
      taxExclusive: true,
    );
  }

  final net = price / (1 + ratePercent / 100);
  return Step6TaxPreview(
    netPrice: net,
    taxAmount: price - net,
    finalPrice: price,
    ratePercent: ratePercent,
    taxExclusive: false,
  );
}

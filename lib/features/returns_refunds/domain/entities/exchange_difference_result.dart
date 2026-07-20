enum ExchangeDifferenceType {
  customerPays,
  customerRefund,
  evenExchange,
}

class ExchangeDifferencePresentation {
  const ExchangeDifferencePresentation({
    required this.type,
    required this.amount,
    required this.currencyCode,
  });

  final ExchangeDifferenceType type;
  final double amount;
  final String currencyCode;
}

/// Test-only helper for local difference math. Step 9 production UI must use
/// [exchangeDifferenceFromPreview] with backend exchange-preview values only.
ExchangeDifferencePresentation calculateExchangeDifference({
  required double returnItemValue,
  required double newItemValue,
  required String currencyCode,
}) {
  final difference = newItemValue - returnItemValue;
  if (difference > 0) {
    return ExchangeDifferencePresentation(
      type: ExchangeDifferenceType.customerPays,
      amount: difference,
      currencyCode: currencyCode,
    );
  }
  if (difference < 0) {
    return ExchangeDifferencePresentation(
      type: ExchangeDifferenceType.customerRefund,
      amount: difference.abs(),
      currencyCode: currencyCode,
    );
  }
  return ExchangeDifferencePresentation(
    type: ExchangeDifferenceType.evenExchange,
    amount: 0,
    currencyCode: currencyCode,
  );
}

ExchangeDifferencePresentation exchangeDifferenceFromPreview({
  required String differenceDirection,
  required double differenceAmount,
  required String currencyCode,
}) {
  final direction = differenceDirection.trim().toUpperCase();
  if (direction == 'CUSTOMER_PAYS') {
    return ExchangeDifferencePresentation(
      type: ExchangeDifferenceType.customerPays,
      amount: differenceAmount,
      currencyCode: currencyCode,
    );
  }
  if (direction == 'CUSTOMER_RECEIVES') {
    return ExchangeDifferencePresentation(
      type: ExchangeDifferenceType.customerRefund,
      amount: differenceAmount,
      currencyCode: currencyCode,
    );
  }
  return ExchangeDifferencePresentation(
    type: ExchangeDifferenceType.evenExchange,
    amount: 0,
    currencyCode: currencyCode,
  );
}

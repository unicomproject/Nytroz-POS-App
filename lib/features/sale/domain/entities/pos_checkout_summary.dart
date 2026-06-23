
class PosCheckoutSummaryPayload {
  const PosCheckoutSummaryPayload({
    required this.billingSummary,
    required this.saleDetails,
    required this.paymentMethods,
    required this.validationMessages,
  });

  final PosCheckoutBillingSummaryPayload billingSummary;
  final PosCheckoutSaleDetailsPayload saleDetails;
  final List<String> paymentMethods;
  final List<String> validationMessages;

  factory PosCheckoutSummaryPayload.fromJson(Map<String, dynamic> json) {
    final billing = _map(json['billingSummary'] ?? json['BillingSummary']);
    final saleDetails = _map(json['saleDetails'] ?? json['SaleDetails']);

    return PosCheckoutSummaryPayload(
      billingSummary: PosCheckoutBillingSummaryPayload.fromJson(billing),
      saleDetails: PosCheckoutSaleDetailsPayload.fromJson(saleDetails),
      paymentMethods: _stringList(json['paymentMethods'] ?? json['PaymentMethods']),
      validationMessages:
          _stringList(json['validationMessages'] ?? json['ValidationMessages']),
    );
  }

  static Map<String, dynamic> _map(Object? value) {
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }

    return const {};
  }

  static List<String> _stringList(Object? value) {
    if (value is Iterable) {
      return value
          .map((item) => item.toString())
          .where((item) => item.isNotEmpty)
          .toList(growable: false);
    }

    return const [];
  }
}

class PosCheckoutBillingSummaryPayload {
  const PosCheckoutBillingSummaryPayload({
    required this.itemCount,
    required this.subtotal,
    required this.discount,
    required this.tax,
    required this.totalPayable,
    required this.currency,
  });

  final int itemCount;
  final int subtotal;
  final int discount;
  final int tax;
  final int totalPayable;
  final String currency;

  factory PosCheckoutBillingSummaryPayload.fromJson(Map<String, dynamic> json) {
    return PosCheckoutBillingSummaryPayload(
      itemCount: _toInt(json['itemCount'] ?? json['ItemCount']),
      subtotal: _toMoney(json['subtotal'] ?? json['Subtotal']),
      discount: _toMoney(json['discount'] ?? json['Discount']),
      tax: _toMoney(json['tax'] ?? json['Tax']),
      totalPayable: _toMoney(json['totalPayable'] ?? json['TotalPayable']),
      currency: json['currency']?.toString() ?? json['Currency']?.toString() ?? '',
    );
  }
}

class PosCheckoutSaleDetailsPayload {
  const PosCheckoutSaleDetailsPayload({
    required this.saleType,
    required this.itemsInCart,
    required this.saleDate,
    required this.cashierName,
  });

  final String saleType;
  final int itemsInCart;
  final DateTime saleDate;
  final String cashierName;

  factory PosCheckoutSaleDetailsPayload.fromJson(Map<String, dynamic> json) {
    return PosCheckoutSaleDetailsPayload(
      saleType: json['saleType']?.toString() ?? json['SaleType']?.toString() ?? 'New Sale',
      itemsInCart: _toInt(json['itemsInCart'] ?? json['ItemsInCart']),
      saleDate: DateTime.tryParse(
            json['saleDate']?.toString() ?? json['SaleDate']?.toString() ?? '',
          ) ??
          DateTime.now(),
      cashierName:
          json['cashierName']?.toString() ?? json['CashierName']?.toString() ?? 'Cashier',
    );
  }
}

class PosCheckoutLineRequest {
  const PosCheckoutLineRequest({
    required this.variantId,
    required this.quantity,
  });

  final String variantId;
  final int quantity;

  Map<String, dynamic> toJson() {
    return {
      'variantId': variantId,
      'qty': quantity,
    };
  }
}

class PosCheckoutStartPaymentPayload {
  const PosCheckoutStartPaymentPayload({
    required this.checkoutSessionId,
    required this.saleId,
    required this.saleNumber,
    required this.paymentMethod,
    required this.grandTotal,
    required this.currency,
    required this.saleStatus,
    required this.nextAction,
    this.paymentId,
  });

  final String checkoutSessionId;
  final String saleId;
  final String saleNumber;
  final String paymentMethod;
  final int grandTotal;
  final String currency;
  final String saleStatus;
  final String nextAction;
  final String? paymentId;

  factory PosCheckoutStartPaymentPayload.fromJson(Map<String, dynamic> json) {
    return PosCheckoutStartPaymentPayload(
      checkoutSessionId: json['checkoutSessionId']?.toString() ??
          json['CheckoutSessionId']?.toString() ??
          json['saleId']?.toString() ??
          '',
      saleId: json['saleId']?.toString() ?? json['SaleId']?.toString() ?? '',
      saleNumber:
          json['saleNumber']?.toString() ?? json['SaleNumber']?.toString() ?? '',
      paymentMethod: json['paymentMethod']?.toString() ??
          json['PaymentMethod']?.toString() ??
          '',
      grandTotal: _toMoney(json['grandTotal'] ?? json['GrandTotal']),
      currency: json['currency']?.toString() ?? json['Currency']?.toString() ?? '',
      saleStatus:
          json['saleStatus']?.toString() ?? json['SaleStatus']?.toString() ?? '',
      nextAction:
          json['nextAction']?.toString() ?? json['NextAction']?.toString() ?? '',
      paymentId: json['paymentId']?.toString() ?? json['PaymentId']?.toString(),
    );
  }
}

int _toInt(Object? value) {
  if (value is int) {
    return value;
  }

  if (value is num) {
    return value.round();
  }

  return int.tryParse(value?.toString() ?? '') ?? 0;
}

int _toMoney(Object? value) {
  if (value is int) {
    return value;
  }

  if (value is num) {
    return value.round();
  }

  if (value is String) {
    return double.tryParse(value)?.round() ?? 0;
  }

  return 0;
}

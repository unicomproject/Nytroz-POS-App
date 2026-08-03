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
      paymentMethods:
          _stringList(json['paymentMethods'] ?? json['PaymentMethods']),
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
      currency:
          json['currency']?.toString() ?? json['Currency']?.toString() ?? '',
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
      saleType: json['saleType']?.toString() ??
          json['SaleType']?.toString() ??
          'New Sale',
      itemsInCart: _toInt(json['itemsInCart'] ?? json['ItemsInCart']),
      saleDate: DateTime.tryParse(
            json['saleDate']?.toString() ?? json['SaleDate']?.toString() ?? '',
          ) ??
          DateTime.now(),
      cashierName: json['cashierName']?.toString() ??
          json['CashierName']?.toString() ??
          'Cashier',
    );
  }
}

class PosCheckoutLineRequest {
  const PosCheckoutLineRequest({
    required this.variantId,
    required this.quantity,
    this.clientLineId,
    this.uomId,
    this.lineNote,
    this.source,
    this.recommendationParentProductId,
    this.recommendationRelationshipId,
  });

  final String variantId;
  final int quantity;
  final String? clientLineId, uomId, lineNote, source;
  final String? recommendationParentProductId, recommendationRelationshipId;

  Map<String, dynamic> toJson() {
    return {
      'variantId': variantId,
      'qty': quantity,
      if (clientLineId?.isNotEmpty == true) 'clientLineId': clientLineId,
      if (uomId?.isNotEmpty == true) 'uomId': uomId,
      if (lineNote?.trim().isNotEmpty == true) 'lineNote': lineNote!.trim(),
      if (source?.isNotEmpty == true) 'source': source,
      if (recommendationParentProductId?.isNotEmpty == true)
        'recommendationParentProductId': recommendationParentProductId,
      if (recommendationRelationshipId?.isNotEmpty == true)
        'recommendationRelationshipId': recommendationRelationshipId,
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
    required this.receiptNumber,
    required this.barcodeValue,
    required this.completedAt,
    required this.subtotal,
    required this.discount,
    required this.tax,
    required this.cashReceived,
    required this.changeDue,
    required this.items,
    this.paymentId,
    this.receiptId,
    this.merchantName,
    this.outletName,
    this.tillId,
    this.tillName,
    this.cashierId,
    this.cashierName,
    this.tenders = const [],
    this.discountLines = const [],
    this.taxLines = const [],
    this.copyPolicy = const PosReceiptCopyPolicyPayload(),
    this.taxRegistrationNumber,
    this.taxInvoiceLabel,
    this.drawerOperationId,
    this.cashDrawerSettings,
  });

  final String checkoutSessionId;
  final String saleId;
  final String saleNumber;
  final String paymentMethod;
  final int grandTotal;
  final String currency;
  final String saleStatus;
  final String nextAction;
  final String receiptNumber;
  final String barcodeValue;
  final DateTime? completedAt;
  final int subtotal;
  final int discount;
  final int tax;
  final int cashReceived;
  final int changeDue;
  final List<PosCheckoutCompletedLinePayload> items;
  final String? paymentId;
  final String? receiptId;
  final String? merchantName;
  final String? outletName;
  final String? tillId;
  final String? tillName;
  final String? cashierId;
  final String? cashierName;
  final List<PosReceiptTenderPayload> tenders;
  final List<PosReceiptDiscountPayload> discountLines;
  final List<PosReceiptTaxPayload> taxLines;
  final PosReceiptCopyPolicyPayload copyPolicy;
  final String? taxRegistrationNumber;
  final String? taxInvoiceLabel;
  final String? drawerOperationId;
  final Map<String, dynamic>? cashDrawerSettings;

  factory PosCheckoutStartPaymentPayload.fromJson(Map<String, dynamic> json) {
    return PosCheckoutStartPaymentPayload(
      checkoutSessionId: json['checkoutSessionId']?.toString() ??
          json['CheckoutSessionId']?.toString() ??
          json['saleId']?.toString() ??
          '',
      saleId: json['saleId']?.toString() ?? json['SaleId']?.toString() ?? '',
      saleNumber: json['saleNumber']?.toString() ??
          json['SaleNumber']?.toString() ??
          '',
      paymentMethod: json['paymentMethod']?.toString() ??
          json['PaymentMethod']?.toString() ??
          '',
      grandTotal: _toMoney(json['grandTotal'] ?? json['GrandTotal']),
      currency:
          json['currency']?.toString() ?? json['Currency']?.toString() ?? '',
      saleStatus: json['saleStatus']?.toString() ??
          json['SaleStatus']?.toString() ??
          '',
      nextAction: json['nextAction']?.toString() ??
          json['NextAction']?.toString() ??
          '',
      receiptNumber: json['receiptNumber']?.toString() ??
          json['ReceiptNumber']?.toString() ??
          '',
      barcodeValue: json['barcodeValue']?.toString() ??
          json['BarcodeValue']?.toString() ??
          json['receiptNumber']?.toString() ??
          json['ReceiptNumber']?.toString() ??
          '',
      completedAt: DateTime.tryParse(
        json['completedAt']?.toString() ??
            json['CompletedAt']?.toString() ??
            '',
      ),
      subtotal: _toMoney(json['subtotal'] ?? json['Subtotal']),
      discount: _toMoney(json['discountTotal'] ?? json['DiscountTotal']),
      tax: _toMoney(json['taxTotal'] ?? json['TaxTotal']),
      cashReceived: _toMoney(json['cashReceived'] ?? json['CashReceived']),
      changeDue: _toMoney(json['changeDue'] ?? json['ChangeDue']),
      items: _completedLines(json['items'] ?? json['Items']),
      paymentId: json['paymentId']?.toString() ?? json['PaymentId']?.toString(),
      receiptId: json['receiptId']?.toString() ?? json['ReceiptId']?.toString(),
      merchantName:
          json['merchantName']?.toString() ?? json['MerchantName']?.toString(),
      outletName:
          json['outletName']?.toString() ?? json['OutletName']?.toString(),
      tillId: json['tillId']?.toString() ?? json['TillId']?.toString(),
      tillName: json['tillName']?.toString() ?? json['TillName']?.toString(),
      cashierId: json['cashierId']?.toString() ?? json['CashierId']?.toString(),
      cashierName:
          json['cashierName']?.toString() ?? json['CashierName']?.toString(),
      tenders: _maps(json['tenders'] ?? json['Tenders'])
          .map(PosReceiptTenderPayload.fromJson)
          .toList(growable: false),
      discountLines: _maps(json['discountLines'] ?? json['DiscountLines'])
          .map(PosReceiptDiscountPayload.fromJson)
          .toList(growable: false),
      taxLines: _maps(json['taxLines'] ?? json['TaxLines'])
          .map(PosReceiptTaxPayload.fromJson)
          .toList(growable: false),
      copyPolicy: PosReceiptCopyPolicyPayload.fromJson(
        _mapValue(json['copyPolicy'] ?? json['CopyPolicy']),
      ),
      taxRegistrationNumber: json['taxRegistrationNumber']?.toString() ??
          json['TaxRegistrationNumber']?.toString(),
      taxInvoiceLabel: json['taxInvoiceLabel']?.toString() ??
          json['TaxInvoiceLabel']?.toString(),
      drawerOperationId: json['drawerOperationId']?.toString() ??
          json['DrawerOperationId']?.toString(),
      cashDrawerSettings: json['cashDrawerSettings'] is Map
          ? Map<String, dynamic>.from(json['cashDrawerSettings'] as Map)
          : (json['CashDrawerSettings'] is Map
              ? Map<String, dynamic>.from(json['CashDrawerSettings'] as Map)
              : null),
    );
  }
}

class PosReceiptTenderPayload {
  const PosReceiptTenderPayload({
    required this.paymentId,
    required this.methodCode,
    required this.methodName,
    required this.methodType,
    required this.amount,
    required this.currency,
    required this.status,
    this.amountTendered,
    this.changeAmount,
    this.providerName,
    this.cardBrand,
    this.maskedCardLast4,
    this.authorizationReference,
    this.terminalReference,
  });

  final String paymentId, methodCode, methodName, methodType, currency, status;
  final int amount;
  final int? amountTendered, changeAmount;
  final String? providerName, cardBrand, maskedCardLast4;
  final String? authorizationReference, terminalReference;

  factory PosReceiptTenderPayload.fromJson(Map<String, dynamic> json) =>
      PosReceiptTenderPayload(
        paymentId: _text(json, 'paymentId'),
        methodCode: _text(json, 'methodCode'),
        methodName: _text(json, 'methodName'),
        methodType: _text(json, 'methodType'),
        amount: _toMoney(json['amount'] ?? json['Amount']),
        amountTendered: _optionalMoney(json, 'amountTendered'),
        changeAmount: _optionalMoney(json, 'changeAmount'),
        currency: _text(json, 'currency'),
        status: _text(json, 'status'),
        providerName: _optionalTextValue(json, 'providerName'),
        cardBrand: _optionalTextValue(json, 'cardBrand'),
        maskedCardLast4: _optionalTextValue(json, 'maskedCardLast4'),
        authorizationReference:
            _optionalTextValue(json, 'authorizationReference'),
        terminalReference: _optionalTextValue(json, 'terminalReference'),
      );
}

class PosReceiptDiscountPayload {
  const PosReceiptDiscountPayload({
    required this.scope,
    required this.name,
    required this.amount,
    this.saleLineId,
    this.code,
    this.promotionReference,
  });
  final String scope, name;
  final String? saleLineId, code, promotionReference;
  final int amount;

  factory PosReceiptDiscountPayload.fromJson(Map<String, dynamic> json) =>
      PosReceiptDiscountPayload(
        scope: _text(json, 'scope'),
        saleLineId: _optionalTextValue(json, 'saleLineId'),
        name: _text(json, 'name'),
        code: _optionalTextValue(json, 'code'),
        promotionReference: _optionalTextValue(json, 'promotionReference'),
        amount: _toMoney(json['amount'] ?? json['Amount']),
      );
}

class PosReceiptTaxPayload {
  const PosReceiptTaxPayload({
    required this.taxCode,
    required this.taxName,
    required this.taxableAmount,
    required this.taxAmount,
    this.rate,
  });
  final String taxCode, taxName;
  final double? rate;
  final int taxableAmount, taxAmount;

  factory PosReceiptTaxPayload.fromJson(Map<String, dynamic> json) =>
      PosReceiptTaxPayload(
        taxCode: _text(json, 'taxCode'),
        taxName: _text(json, 'taxName'),
        rate: (json['rate'] ?? json['Rate'] as num?)?.toDouble(),
        taxableAmount: _toMoney(json['taxableAmount'] ?? json['TaxableAmount']),
        taxAmount: _toMoney(json['taxAmount'] ?? json['TaxAmount']),
      );
}

class PosReceiptCopyPolicyPayload {
  const PosReceiptCopyPolicyPayload({
    this.customerCopyCount = 1,
    this.merchantCopyCount = 0,
    this.printCustomerCopy = true,
    this.printMerchantCopy = false,
    this.terminalSlipExpected = false,
    this.terminalSlipPrintedByExternalTerminal = false,
  });
  final int customerCopyCount, merchantCopyCount;
  final bool printCustomerCopy, printMerchantCopy;
  final bool terminalSlipExpected, terminalSlipPrintedByExternalTerminal;

  factory PosReceiptCopyPolicyPayload.fromJson(Map<String, dynamic> json) =>
      PosReceiptCopyPolicyPayload(
        customerCopyCount:
            _toInt(json['customerCopyCount'] ?? json['CustomerCopyCount'] ?? 1),
        merchantCopyCount:
            _toInt(json['merchantCopyCount'] ?? json['MerchantCopyCount']),
        printCustomerCopy:
            json['printCustomerCopy'] ?? json['PrintCustomerCopy'] ?? true,
        printMerchantCopy:
            json['printMerchantCopy'] ?? json['PrintMerchantCopy'] ?? false,
        terminalSlipExpected: json['terminalSlipExpected'] ??
            json['TerminalSlipExpected'] ??
            false,
        terminalSlipPrintedByExternalTerminal:
            json['terminalSlipPrintedByExternalTerminal'] ??
                json['TerminalSlipPrintedByExternalTerminal'] ??
                false,
      );
}

class PosCheckoutCompletedLinePayload {
  const PosCheckoutCompletedLinePayload({
    required this.name,
    required this.quantity,
    required this.unitPrice,
    required this.lineTotal,
    this.variantSummary,
    this.saleLineId,
    this.discountAmount = 0,
    this.lineNote,
  });

  final String name;
  final int quantity;
  final int unitPrice;
  final int lineTotal;
  final String? variantSummary;
  final String? saleLineId;
  final int discountAmount;
  final String? lineNote;

  factory PosCheckoutCompletedLinePayload.fromJson(Map<String, dynamic> json) {
    return PosCheckoutCompletedLinePayload(
      name: json['name']?.toString() ?? json['Name']?.toString() ?? '',
      quantity: _toInt(json['qty'] ?? json['Qty']),
      unitPrice: _toMoney(json['unitPrice'] ?? json['UnitPrice']),
      lineTotal: _toMoney(json['lineTotal'] ?? json['LineTotal']),
      variantSummary: json['sku']?.toString() ?? json['Sku']?.toString(),
      saleLineId:
          json['saleLineId']?.toString() ?? json['SaleLineId']?.toString(),
      discountAmount:
          _toMoney(json['discountAmount'] ?? json['DiscountAmount']),
      lineNote: json['lineNote']?.toString() ?? json['LineNote']?.toString(),
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

List<PosCheckoutCompletedLinePayload> _completedLines(Object? value) {
  if (value is Iterable) {
    return value
        .whereType<Map>()
        .map((item) => PosCheckoutCompletedLinePayload.fromJson(
              Map<String, dynamic>.from(item),
            ))
        .toList(growable: false);
  }

  return const [];
}

List<Map<String, dynamic>> _maps(Object? value) => value is Iterable
    ? value
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList(growable: false)
    : const [];

Map<String, dynamic> _mapValue(Object? value) =>
    value is Map ? Map<String, dynamic>.from(value) : const {};

String _text(Map<String, dynamic> json, String key) =>
    (json[key] ?? json['${key[0].toUpperCase()}${key.substring(1)}'])
        ?.toString() ??
    '';

String? _optionalTextValue(Map<String, dynamic> json, String key) {
  final value = _text(json, key).trim();
  return value.isEmpty ? null : value;
}

int? _optionalMoney(Map<String, dynamic> json, String key) {
  final value = json[key] ?? json['${key[0].toUpperCase()}${key.substring(1)}'];
  return value == null ? null : _toMoney(value);
}

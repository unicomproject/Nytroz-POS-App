class CompletedSaleReceiptLine {
  const CompletedSaleReceiptLine({
    required this.name,
    required this.quantity,
    required this.unitPrice,
    required this.lineTotal,
    this.variantOrSku,
    this.saleLineId,
  });

  final String name;
  final int quantity;
  final int unitPrice;
  final int lineTotal;
  final String? variantOrSku;
  final String? saleLineId;

  Map<String, dynamic> toJson() => {
        'name': name,
        'quantity': quantity,
        'unitPrice': unitPrice,
        'lineTotal': lineTotal,
        'variantOrSku': variantOrSku,
        'saleLineId': saleLineId,
      };

  factory CompletedSaleReceiptLine.fromJson(Map<String, dynamic> json) {
    return CompletedSaleReceiptLine(
      name: json['name']?.toString() ?? '',
      quantity: (json['quantity'] as num?)?.toInt() ?? 0,
      unitPrice: (json['unitPrice'] as num?)?.toInt() ?? 0,
      lineTotal: (json['lineTotal'] as num?)?.toInt() ?? 0,
      variantOrSku: json['variantOrSku']?.toString(),
      saleLineId: json['saleLineId']?.toString(),
    );
  }
}

class CompletedSaleTender {
  const CompletedSaleTender({
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
  final String methodCode, methodName, methodType, currency, status;
  final int amount;
  final int? amountTendered, changeAmount;
  final String? providerName, cardBrand, maskedCardLast4;
  final String? authorizationReference, terminalReference;

  Map<String, dynamic> toJson() => {
        'methodCode': methodCode,
        'methodName': methodName,
        'methodType': methodType,
        'amount': amount,
        'currency': currency,
        'status': status,
        'amountTendered': amountTendered,
        'changeAmount': changeAmount,
        'providerName': providerName,
        'cardBrand': cardBrand,
        'maskedCardLast4': maskedCardLast4,
        'authorizationReference': authorizationReference,
        'terminalReference': terminalReference,
      };

  factory CompletedSaleTender.fromJson(Map<String, dynamic> json) =>
      CompletedSaleTender(
        methodCode: json['methodCode']?.toString() ?? '',
        methodName: json['methodName']?.toString() ?? '',
        methodType: json['methodType']?.toString() ?? '',
        amount: (json['amount'] as num?)?.toInt() ?? 0,
        currency: json['currency']?.toString() ?? '',
        status: json['status']?.toString() ?? '',
        amountTendered: (json['amountTendered'] as num?)?.toInt(),
        changeAmount: (json['changeAmount'] as num?)?.toInt(),
        providerName: json['providerName']?.toString(),
        cardBrand: json['cardBrand']?.toString(),
        maskedCardLast4: json['maskedCardLast4']?.toString(),
        authorizationReference: json['authorizationReference']?.toString(),
        terminalReference: json['terminalReference']?.toString(),
      );
}

class CompletedSaleDiscount {
  const CompletedSaleDiscount({
    required this.scope,
    required this.name,
    required this.amount,
    this.saleLineId,
    this.code,
    this.promotionReference,
  });
  final String scope, name;
  final int amount;
  final String? saleLineId, code, promotionReference;

  Map<String, dynamic> toJson() => {
        'scope': scope,
        'name': name,
        'amount': amount,
        'saleLineId': saleLineId,
        'code': code,
        'promotionReference': promotionReference,
      };

  factory CompletedSaleDiscount.fromJson(Map<String, dynamic> json) =>
      CompletedSaleDiscount(
        scope: json['scope']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        amount: (json['amount'] as num?)?.toInt() ?? 0,
        saleLineId: json['saleLineId']?.toString(),
        code: json['code']?.toString(),
        promotionReference: json['promotionReference']?.toString(),
      );
}

class CompletedSaleTax {
  const CompletedSaleTax({
    required this.taxCode,
    required this.taxName,
    required this.taxableAmount,
    required this.taxAmount,
    this.rate,
  });
  final String taxCode, taxName;
  final double? rate;
  final int taxableAmount, taxAmount;

  Map<String, dynamic> toJson() => {
        'taxCode': taxCode,
        'taxName': taxName,
        'rate': rate,
        'taxableAmount': taxableAmount,
        'taxAmount': taxAmount,
      };

  factory CompletedSaleTax.fromJson(Map<String, dynamic> json) =>
      CompletedSaleTax(
        taxCode: json['taxCode']?.toString() ?? '',
        taxName: json['taxName']?.toString() ?? '',
        rate: (json['rate'] as num?)?.toDouble(),
        taxableAmount: (json['taxableAmount'] as num?)?.toInt() ?? 0,
        taxAmount: (json['taxAmount'] as num?)?.toInt() ?? 0,
      );
}

class CompletedSaleCopyPolicy {
  const CompletedSaleCopyPolicy({
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

  Map<String, dynamic> toJson() => {
        'customerCopyCount': customerCopyCount,
        'merchantCopyCount': merchantCopyCount,
        'printCustomerCopy': printCustomerCopy,
        'printMerchantCopy': printMerchantCopy,
        'terminalSlipExpected': terminalSlipExpected,
        'terminalSlipPrintedByExternalTerminal':
            terminalSlipPrintedByExternalTerminal,
      };

  factory CompletedSaleCopyPolicy.fromJson(Map<String, dynamic> json) =>
      CompletedSaleCopyPolicy(
        customerCopyCount: (json['customerCopyCount'] as num?)?.toInt() ?? 1,
        merchantCopyCount: (json['merchantCopyCount'] as num?)?.toInt() ?? 0,
        printCustomerCopy: json['printCustomerCopy'] as bool? ?? true,
        printMerchantCopy: json['printMerchantCopy'] as bool? ?? false,
        terminalSlipExpected: json['terminalSlipExpected'] as bool? ?? false,
        terminalSlipPrintedByExternalTerminal:
            json['terminalSlipPrintedByExternalTerminal'] as bool? ?? false,
      );
}

/// Immutable values returned after the backend commits the completed sale.
///
/// Money remains in the backend's integer currency unit. No totals are
/// recalculated by the printer integration.
class CompletedSaleReceipt {
  const CompletedSaleReceipt({
    required this.receiptId,
    required this.saleId,
    required this.receiptNumber,
    required this.completedAt,
    required this.merchantName,
    required this.outletName,
    required this.tillId,
    required this.tillName,
    required this.cashierId,
    required this.cashierName,
    required this.deviceId,
    required this.currency,
    required this.items,
    required this.subtotal,
    required this.discountTotal,
    required this.taxTotal,
    required this.total,
    required this.paymentMethods,
    required this.amountTendered,
    required this.change,
    this.barcodeValue = '',
    this.footerLines = const [],
    this.tenders = const [],
    this.discountLines = const [],
    this.taxLines = const [],
    this.copyPolicy = const CompletedSaleCopyPolicy(),
    this.taxRegistrationNumber,
    this.taxInvoiceLabel,
    this.isReprint = false,
    this.copyType = 'CUSTOMER',
    this.copyIndex = 1,
  });

  final String receiptId;
  final String saleId;
  final String receiptNumber;
  final DateTime completedAt;
  final String merchantName;
  final String outletName;
  final String tillId;
  final String tillName;
  final String cashierId;
  final String cashierName;
  final String deviceId;
  final String currency;
  final List<CompletedSaleReceiptLine> items;
  final int subtotal;
  final int discountTotal;
  final int taxTotal;
  final int total;
  final List<String> paymentMethods;
  final int amountTendered;
  final int change;
  final String barcodeValue;
  final List<String> footerLines;
  final List<CompletedSaleTender> tenders;
  final List<CompletedSaleDiscount> discountLines;
  final List<CompletedSaleTax> taxLines;
  final CompletedSaleCopyPolicy copyPolicy;
  final String? taxRegistrationNumber, taxInvoiceLabel;
  final bool isReprint;
  final String copyType;
  final int copyIndex;

  String get paymentSummary => paymentMethods.join(' + ');

  Map<String, dynamic> toJson() => {
        'receiptId': receiptId,
        'saleId': saleId,
        'receiptNumber': receiptNumber,
        'completedAt': completedAt.toUtc().toIso8601String(),
        'merchantName': merchantName,
        'outletName': outletName,
        'tillId': tillId,
        'tillName': tillName,
        'cashierId': cashierId,
        'cashierName': cashierName,
        'deviceId': deviceId,
        'currency': currency,
        'items': items.map((item) => item.toJson()).toList(growable: false),
        'subtotal': subtotal,
        'discountTotal': discountTotal,
        'taxTotal': taxTotal,
        'total': total,
        'paymentMethods': paymentMethods,
        'amountTendered': amountTendered,
        'change': change,
        'barcodeValue': barcodeValue,
        'footerLines': footerLines,
        'tenders': tenders.map((item) => item.toJson()).toList(growable: false),
        'discountLines':
            discountLines.map((item) => item.toJson()).toList(growable: false),
        'taxLines':
            taxLines.map((item) => item.toJson()).toList(growable: false),
        'copyPolicy': copyPolicy.toJson(),
        'taxRegistrationNumber': taxRegistrationNumber,
        'taxInvoiceLabel': taxInvoiceLabel,
        'isReprint': isReprint,
        'copyType': copyType,
        'copyIndex': copyIndex,
      };

  factory CompletedSaleReceipt.fromJson(Map<String, dynamic> json) {
    List<String> strings(String key) => (json[key] as List? ?? const [])
        .map((item) => item.toString())
        .toList();
    return CompletedSaleReceipt(
      receiptId: json['receiptId']?.toString() ?? '',
      saleId: json['saleId']?.toString() ?? '',
      receiptNumber: json['receiptNumber']?.toString() ?? '',
      completedAt: DateTime.parse(json['completedAt'].toString()).toUtc(),
      merchantName: json['merchantName']?.toString() ?? '',
      outletName: json['outletName']?.toString() ?? '',
      tillId: json['tillId']?.toString() ?? '',
      tillName: json['tillName']?.toString() ?? '',
      cashierId: json['cashierId']?.toString() ?? '',
      cashierName: json['cashierName']?.toString() ?? '',
      deviceId: json['deviceId']?.toString() ?? '',
      currency: json['currency']?.toString() ?? '',
      items: (json['items'] as List? ?? const [])
          .whereType<Map>()
          .map((item) => CompletedSaleReceiptLine.fromJson(
                item.map((key, value) => MapEntry(key.toString(), value)),
              ))
          .toList(growable: false),
      subtotal: (json['subtotal'] as num?)?.toInt() ?? 0,
      discountTotal: (json['discountTotal'] as num?)?.toInt() ?? 0,
      taxTotal: (json['taxTotal'] as num?)?.toInt() ?? 0,
      total: (json['total'] as num?)?.toInt() ?? 0,
      paymentMethods: strings('paymentMethods'),
      amountTendered: (json['amountTendered'] as num?)?.toInt() ?? 0,
      change: (json['change'] as num?)?.toInt() ?? 0,
      barcodeValue: json['barcodeValue']?.toString() ?? '',
      footerLines: strings('footerLines'),
      tenders: _jsonMaps(json['tenders'])
          .map(CompletedSaleTender.fromJson)
          .toList(growable: false),
      discountLines: _jsonMaps(json['discountLines'])
          .map(CompletedSaleDiscount.fromJson)
          .toList(growable: false),
      taxLines: _jsonMaps(json['taxLines'])
          .map(CompletedSaleTax.fromJson)
          .toList(growable: false),
      copyPolicy: CompletedSaleCopyPolicy.fromJson(
        json['copyPolicy'] is Map
            ? Map<String, dynamic>.from(json['copyPolicy'] as Map)
            : const {},
      ),
      taxRegistrationNumber: json['taxRegistrationNumber']?.toString(),
      taxInvoiceLabel: json['taxInvoiceLabel']?.toString(),
      isReprint: json['isReprint'] as bool? ?? false,
      copyType: json['copyType']?.toString() ?? 'CUSTOMER',
      copyIndex: (json['copyIndex'] as num?)?.toInt() ?? 1,
    );
  }

  CompletedSaleReceipt forCopy({
    required String copyType,
    required int copyIndex,
  }) =>
      CompletedSaleReceipt.fromJson({
        ...toJson(),
        'copyType': copyType,
        'copyIndex': copyIndex,
      });
}

List<Map<String, dynamic>> _jsonMaps(Object? value) => value is Iterable
    ? value
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList(growable: false)
    : const [];

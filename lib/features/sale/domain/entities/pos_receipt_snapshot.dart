import 'dart:convert';

class PosReceiptSnapshot {
  const PosReceiptSnapshot({
    required this.contractVersion,
    required this.templateVersionId,
    required this.templateCode,
    required this.paperSize,
    required this.branding,
    required this.receiptIdentity,
    required this.operatorDetails,
    required this.items,
    required this.totals,
    required this.tenders,
    required this.presentation,
    required this.copyPolicy,
  });

  final String contractVersion;
  final String? templateVersionId;
  final String? templateCode;
  final String? paperSize;
  final PosReceiptBranding branding;
  final PosReceiptIdentity receiptIdentity;
  final PosReceiptOperator operatorDetails;
  final List<PosReceiptItem> items;
  final PosReceiptTotals totals;
  final List<PosReceiptTender> tenders;
  final PosReceiptPresentation presentation;
  final PosReceiptCopyPolicy copyPolicy;

  factory PosReceiptSnapshot.fromJson(Map<String, dynamic> json) {
    return PosReceiptSnapshot(
      contractVersion: json['contractVersion']?.toString() ?? '1.0',
      templateVersionId: json['templateVersionId']?.toString(),
      templateCode: json['templateCode']?.toString(),
      paperSize: json['paperSize']?.toString(),
      branding: PosReceiptBranding.fromJson(_map(json['branding'])),
      receiptIdentity:
          PosReceiptIdentity.fromJson(_map(json['receiptIdentity'])),
      operatorDetails: PosReceiptOperator.fromJson(_map(json['operator'])),
      items: _list(json['items'])
          .map((e) => PosReceiptItem.fromJson(_map(e)))
          .toList(growable: false),
      totals: PosReceiptTotals.fromJson(_map(json['totals'])),
      tenders: _list(json['tenders'])
          .map((e) => PosReceiptTender.fromJson(_map(e)))
          .toList(growable: false),
      presentation: PosReceiptPresentation.fromJson(_map(json['presentation'])),
      copyPolicy: PosReceiptCopyPolicy.fromJson(_map(json['copyPolicy'])),
    );
  }

  static PosReceiptSnapshot? parse(String? jsonString) {
    if (jsonString == null || jsonString.isEmpty) return null;
    try {
      final decoded = jsonDecode(jsonString);
      if (decoded is Map<String, dynamic>) {
        return PosReceiptSnapshot.fromJson(decoded);
      }
    } catch (_) {
      // Return null if parsing fails
    }
    return null;
  }

  static Map<String, dynamic> _map(Object? value) {
    if (value is Map) return Map<String, dynamic>.from(value);
    return const {};
  }

  static List<dynamic> _list(Object? value) {
    if (value is Iterable) return value.toList(growable: false);
    return const [];
  }
}

class PosReceiptBranding {
  const PosReceiptBranding({
    this.merchantName,
    this.tradingName,
    this.logoUrl,
    this.outletName,
    this.addressLines,
    this.phone,
    this.email,
    this.taxRegistration,
  });

  final String? merchantName;
  final String? tradingName;
  final String? logoUrl;
  final String? outletName;
  final List<String>? addressLines;
  final String? phone;
  final String? email;
  final String? taxRegistration;

  factory PosReceiptBranding.fromJson(Map<String, dynamic> json) {
    return PosReceiptBranding(
      merchantName: json['merchantName']?.toString(),
      tradingName: json['tradingName']?.toString(),
      logoUrl: json['logoUrl']?.toString(),
      outletName: json['outletName']?.toString(),
      addressLines: _stringList(json['addressLines']),
      phone: json['phone']?.toString(),
      email: json['email']?.toString(),
      taxRegistration: json['taxRegistration']?.toString(),
    );
  }

  static List<String>? _stringList(Object? value) {
    if (value is Iterable) {
      return value.map((e) => e.toString()).toList(growable: false);
    }
    return null;
  }
}

class PosReceiptIdentity {
  const PosReceiptIdentity({
    required this.receiptId,
    required this.receiptNumber,
    this.saleId,
    this.saleNumber,
    this.receiptType,
    required this.issuedAt,
    this.businessDate,
  });

  final String receiptId;
  final String receiptNumber;
  final String? saleId;
  final String? saleNumber;
  final String? receiptType;
  final DateTime issuedAt;
  final String? businessDate;

  factory PosReceiptIdentity.fromJson(Map<String, dynamic> json) {
    return PosReceiptIdentity(
      receiptId: json['receiptId']?.toString() ?? '',
      receiptNumber: json['receiptNumber']?.toString() ?? '',
      saleId: json['saleId']?.toString(),
      saleNumber: json['saleNumber']?.toString(),
      receiptType: json['receiptType']?.toString(),
      issuedAt: DateTime.tryParse(json['issuedAt']?.toString() ?? '') ??
          DateTime.now(),
      businessDate: json['businessDate']?.toString(),
    );
  }
}

class PosReceiptOperator {
  const PosReceiptOperator({
    this.cashierId,
    this.cashierName,
    this.tillId,
    this.tillName,
    this.posDeviceId,
  });

  final String? cashierId;
  final String? cashierName;
  final String? tillId;
  final String? tillName;
  final String? posDeviceId;

  factory PosReceiptOperator.fromJson(Map<String, dynamic> json) {
    return PosReceiptOperator(
      cashierId: json['cashierId']?.toString(),
      cashierName: json['cashierName']?.toString(),
      tillId: json['tillId']?.toString(),
      tillName: json['tillName']?.toString(),
      posDeviceId: json['posDeviceId']?.toString(),
    );
  }
}

class PosReceiptItem {
  const PosReceiptItem({
    required this.productName,
    this.variantName,
    this.sku,
    required this.quantity,
    required this.unitPrice,
    required this.discount,
    required this.tax,
    required this.lineTotal,
  });

  final String productName;
  final String? variantName;
  final String? sku;
  final int quantity;
  final int unitPrice;
  final int discount;
  final int tax;
  final int lineTotal;

  factory PosReceiptItem.fromJson(Map<String, dynamic> json) {
    return PosReceiptItem(
      productName: json['productName']?.toString() ?? '',
      variantName: json['variantName']?.toString(),
      sku: json['sku']?.toString(),
      quantity: _parseInt(json['quantity']),
      unitPrice: _parseInt(json['unitPrice']),
      discount: _parseInt(json['discount']),
      tax: _parseInt(json['tax']),
      lineTotal: _parseInt(json['lineTotal']),
    );
  }

  static int _parseInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}

class PosReceiptTotals {
  const PosReceiptTotals({
    required this.subtotal,
    required this.discount,
    required this.tax,
    required this.charges,
    required this.rounding,
    required this.total,
    required this.paid,
    required this.cashReceived,
    required this.changeDue,
  });

  final int subtotal;
  final int discount;
  final int tax;
  final int charges;
  final int rounding;
  final int total;
  final int paid;
  final int cashReceived;
  final int changeDue;

  factory PosReceiptTotals.fromJson(Map<String, dynamic> json) {
    return PosReceiptTotals(
      subtotal: PosReceiptItem._parseInt(json['subtotal']),
      discount: PosReceiptItem._parseInt(json['discount']),
      tax: PosReceiptItem._parseInt(json['tax']),
      charges: PosReceiptItem._parseInt(json['charges']),
      rounding: PosReceiptItem._parseInt(json['rounding']),
      total: PosReceiptItem._parseInt(json['total']),
      paid: PosReceiptItem._parseInt(json['paid']),
      cashReceived: PosReceiptItem._parseInt(json['cashReceived']),
      changeDue: PosReceiptItem._parseInt(json['changeDue']),
    );
  }
}

class PosReceiptTender {
  const PosReceiptTender({
    required this.paymentMethod,
    required this.amount,
    this.safeReference,
  });

  final String paymentMethod;
  final int amount;
  final String? safeReference;

  factory PosReceiptTender.fromJson(Map<String, dynamic> json) {
    final method = json['paymentMethod'] ??
        json['methodName'] ??
        json['MethodName'] ??
        json['methodCode'] ??
        json['MethodCode'] ??
        json['methodType'] ??
        json['MethodType'];
    return PosReceiptTender(
      paymentMethod: method?.toString() ?? '',
      amount: PosReceiptItem._parseInt(json['amount'] ?? json['Amount']),
      safeReference: (json['safeReference'] ??
              json['terminalReference'] ??
              json['TerminalReference'] ??
              json['authorizationReference'] ??
              json['AuthorizationReference'])
          ?.toString(),
    );
  }
}

class PosReceiptPresentation {
  const PosReceiptPresentation({
    this.labels,
    this.sectionVisibility,
    this.alignment,
    this.emphasis,
    required this.barcodeVisibility,
    required this.qrVisibility,
    this.footerMessage,
    this.thankYouMessage,
  });

  final Map<String, String>? labels;
  final Map<String, bool>? sectionVisibility;
  final Map<String, String>? alignment;
  final Map<String, bool>? emphasis;
  final bool barcodeVisibility;
  final bool qrVisibility;
  final String? footerMessage;
  final String? thankYouMessage;

  factory PosReceiptPresentation.fromJson(Map<String, dynamic> json) {
    return PosReceiptPresentation(
      labels: _stringMap(json['labels']),
      sectionVisibility: _boolMap(json['sectionVisibility']),
      alignment: _stringMap(json['alignment']),
      emphasis: _boolMap(json['emphasis']),
      barcodeVisibility: _parseBool(json['barcodeVisibility']),
      qrVisibility: _parseBool(json['qrVisibility']),
      footerMessage: json['footerMessage']?.toString(),
      thankYouMessage: json['thankYouMessage']?.toString(),
    );
  }

  static Map<String, String>? _stringMap(Object? value) {
    if (value is Map) {
      return value.map((k, v) => MapEntry(k.toString(), v.toString()));
    }
    return null;
  }

  static Map<String, bool>? _boolMap(Object? value) {
    if (value is Map) {
      return value.map((k, v) => MapEntry(k.toString(), _parseBool(v)));
    }
    return null;
  }

  static bool _parseBool(Object? value) {
    if (value is bool) return value;
    if (value is String) return value.toLowerCase() == 'true';
    return false;
  }
}

class PosReceiptCopyPolicy {
  const PosReceiptCopyPolicy({
    required this.printMerchantCopy,
    required this.printCustomerCopy,
  });

  final bool printMerchantCopy;
  final bool printCustomerCopy;

  factory PosReceiptCopyPolicy.fromJson(Map<String, dynamic> json) {
    return PosReceiptCopyPolicy(
      printMerchantCopy:
          PosReceiptPresentation._parseBool(json['printMerchantCopy']),
      printCustomerCopy:
          PosReceiptPresentation._parseBool(json['printCustomerCopy']),
    );
  }
}

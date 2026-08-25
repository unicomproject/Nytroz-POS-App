class LocalPrintAgentHealth {
  const LocalPrintAgentHealth({
    required this.agentStatus,
    required this.printerName,
    required this.printerExists,
    required this.ready,
    this.detail,
    this.agentVersion,
    this.apiVersion,
    this.receiptContractVersion,
  });

  final String agentStatus;
  final String printerName;
  final bool printerExists;
  final bool ready;
  bool get printerReady => ready;
  final String? detail;
  final String? agentVersion;
  final String? apiVersion;
  final String? receiptContractVersion;

  factory LocalPrintAgentHealth.fromJson(Map<String, dynamic> json) {
    final printer = json['printer'] is Map
        ? Map<String, dynamic>.from(json['printer'] as Map)
        : const <String, dynamic>{};
    return LocalPrintAgentHealth(
      agentStatus:
          _requiredText(json['agentStatus'] ?? json['status'], 'agentStatus'),
      printerName: _requiredText(
        json['printerName'] ??
            json['configuredPrinterName'] ??
            printer['printerName'] ??
            printer['name'],
        'printerName',
      ),
      printerExists: _requiredBool(
        json['printerExists'] ?? printer['printerExists'] ?? printer['exists'],
        'printerExists',
      ),
      ready: _requiredBool(
        json['printerReady'] ??
            json['ready'] ??
            printer['printerReady'] ??
            printer['ready'],
        'printerReady',
      ),
      detail: _optionalText(json['detail']),
      agentVersion: _optionalText(json['agentVersion']),
      apiVersion: _optionalText(json['apiVersion']),
      receiptContractVersion: _optionalText(json['receiptContractVersion']),
    );
  }
}

String _requiredText(Object? value, String fieldName) {
  final text = value?.toString().trim() ?? '';
  if (text.isEmpty) {
    throw FormatException('Missing required health field: $fieldName');
  }
  return text;
}

bool _requiredBool(Object? value, String fieldName) {
  if (value is bool) return value;
  throw FormatException('Missing or invalid health field: $fieldName');
}

class LocalPrintAgentReceiptLine {
  const LocalPrintAgentReceiptLine({
    required this.name,
    required this.quantity,
    required this.unitPrice,
    required this.lineTotal,
    this.saleLineId,
    this.itemGroup,
    this.discountAmount,
    this.taxAmount,
    this.reason,
    this.sku,
    this.valueUnitPrice,
    this.rateUnitPrice,
  });

  final String name;
  final num quantity;
  final num unitPrice;
  final num lineTotal;
  final String? saleLineId;
  final String? itemGroup;
  final num? discountAmount;
  final num? taxAmount;
  final String? reason;
  final String? sku;
  final num? valueUnitPrice;
  final num? rateUnitPrice;

  Map<String, dynamic> toJson() => {
        'name': name,
        'quantity': quantity,
        'unitPrice': unitPrice,
        'lineTotal': lineTotal,
        'saleLineId': saleLineId,
        'itemGroup': itemGroup,
        'discountAmount': discountAmount,
        'taxAmount': taxAmount,
        'reason': reason,
        'sku': sku,
        'valueUnitPrice': valueUnitPrice,
        'rateUnitPrice': rateUnitPrice,
      };
}

class LocalPrintAgentReferenceLine {
  const LocalPrintAgentReferenceLine({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  Map<String, dynamic> toJson() => {'label': label, 'value': value};
}

class LocalPrintAgentSettlementLine {
  const LocalPrintAgentSettlementLine({
    required this.label,
    required this.amount,
    required this.currency,
    this.method,
    this.safeReference,
  });

  final String label;
  final num amount;
  final String currency;
  final String? method;
  final String? safeReference;

  Map<String, dynamic> toJson() => {
        'label': label,
        'amount': amount,
        'currency': currency,
        'method': method,
        'safeReference': safeReference,
      };
}

class LocalPrintAgentTenderLine {
  const LocalPrintAgentTenderLine({
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
  final num amount;
  final num? amountTendered, changeAmount;
  final String? providerName, cardBrand, maskedCardLast4;
  final String? authorizationReference, terminalReference;
  Map<String, dynamic> toJson() => {
        'methodCode': methodCode,
        'methodName': methodName,
        'methodType': methodType,
        'amount': amount,
        'amountTendered': amountTendered,
        'changeAmount': changeAmount,
        'currency': currency,
        'status': status,
        'providerName': providerName,
        'cardBrand': cardBrand,
        'maskedCardLast4': maskedCardLast4,
        'authorizationReference': authorizationReference,
        'terminalReference': terminalReference,
      };
}

class LocalPrintAgentDiscountLine {
  const LocalPrintAgentDiscountLine({
    required this.scope,
    required this.name,
    required this.amount,
    this.saleLineId,
    this.code,
    this.promotionReference,
  });
  final String scope, name;
  final String? saleLineId, code, promotionReference;
  final num amount;
  Map<String, dynamic> toJson() => {
        'scope': scope,
        'saleLineId': saleLineId,
        'name': name,
        'code': code,
        'promotionReference': promotionReference,
        'amount': amount,
      };
}

class LocalPrintAgentTaxLine {
  const LocalPrintAgentTaxLine({
    required this.taxCode,
    required this.taxName,
    required this.taxableAmount,
    required this.taxAmount,
    this.rate,
  });
  final String taxCode, taxName;
  final num? rate;
  final num taxableAmount, taxAmount;
  Map<String, dynamic> toJson() => {
        'taxCode': taxCode,
        'taxName': taxName,
        'rate': rate,
        'taxableAmount': taxableAmount,
        'taxAmount': taxAmount,
      };
}

class LocalPrintAgentReceiptRequest {
  static const supportedApiVersion = '1';
  static const supportedReceiptContractVersion = '3';

  /// Agents advertising these receipt contracts can still print.
  /// Flutter prefers [supportedReceiptContractVersion] and negotiates down
  /// when an older installed agent rejects the preferred wire version.
  static const compatibleReceiptContractVersions = <String>{'1', '2', '3'};

  static bool isCompatibleReceiptContractVersion(String? version) =>
      version == null || compatibleReceiptContractVersions.contains(version);

  static String negotiateReceiptContractVersion(String? agentVersion) {
    if (agentVersion != null &&
        compatibleReceiptContractVersions.contains(agentVersion)) {
      return agentVersion;
    }
    return supportedReceiptContractVersion;
  }

  const LocalPrintAgentReceiptRequest({
    required this.requestId,
    required this.receiptNumber,
    required this.printedAt,
    required this.merchantName,
    required this.currency,
    required this.items,
    required this.subtotal,
    required this.discountTotal,
    required this.taxTotal,
    required this.total,
    required this.paymentMethod,
    this.outletName,
    this.tillName,
    this.cashierName,
    this.amountTendered,
    this.change,
    this.barcodeValue,
    this.footerLines = const [],
    this.tenders = const [],
    this.discountLines = const [],
    this.taxLines = const [],
    this.taxRegistrationNumber,
    this.taxInvoiceLabel,
    this.copyType = 'CUSTOMER',
    this.copyIndex = 1,
    this.isReprint = false,
    this.receiptPurpose = 'saleOriginal',
    this.receiptId,
    this.originalReceiptReference,
    this.referenceLines = const [],
    this.settlementLines = const [],
    this.printerConfigurationId,
    this.printerConfigurationVersion,
    this.brandSubtitle,
    this.outletLocation,
    this.customerName,
    this.issuedAtDisplay,
    this.itemCount,
    this.presentationLayout = 'canonical_v1',
    this.receiptContractVersion = supportedReceiptContractVersion,
  });

  final String requestId;
  final String receiptNumber;
  final DateTime printedAt;
  final String merchantName;
  final String? outletName;
  final String? tillName;
  final String? cashierName;
  final String currency;
  final List<LocalPrintAgentReceiptLine> items;
  final num subtotal;
  final num discountTotal;
  final num taxTotal;
  final num total;
  final String paymentMethod;
  final num? amountTendered;
  final num? change;
  final String? barcodeValue;
  final List<String> footerLines;
  final List<LocalPrintAgentTenderLine> tenders;
  final List<LocalPrintAgentDiscountLine> discountLines;
  final List<LocalPrintAgentTaxLine> taxLines;
  final String? taxRegistrationNumber, taxInvoiceLabel;
  final String copyType;
  final int copyIndex;
  final bool isReprint;
  final String receiptPurpose;
  final String? receiptId;
  final String? originalReceiptReference;
  final List<LocalPrintAgentReferenceLine> referenceLines;
  final List<LocalPrintAgentSettlementLine> settlementLines;
  final String? printerConfigurationId;
  final int? printerConfigurationVersion;
  final String? brandSubtitle;
  final String? outletLocation;
  final String? customerName;
  final String? issuedAtDisplay;
  final int? itemCount;
  final String presentationLayout;
  final String receiptContractVersion;

  Map<String, dynamic> toJson() => {
        'requestId': requestId,
        'receiptNumber': receiptNumber,
        'printedAt': printedAt.toUtc().toIso8601String(),
        'merchantName': merchantName,
        'outletName': outletName,
        'tillName': tillName,
        'cashierName': cashierName,
        'currency': currency,
        'items': items.map((item) => item.toJson()).toList(growable: false),
        'subtotal': subtotal,
        'discountTotal': discountTotal,
        'taxTotal': taxTotal,
        'total': total,
        'paymentMethod': paymentMethod,
        'amountTendered': amountTendered,
        'change': change,
        'barcodeValue': barcodeValue,
        'footerLines': footerLines,
        'tenders': tenders.map((item) => item.toJson()).toList(growable: false),
        'discountLines':
            discountLines.map((item) => item.toJson()).toList(growable: false),
        'taxLines':
            taxLines.map((item) => item.toJson()).toList(growable: false),
        'taxRegistrationNumber': taxRegistrationNumber,
        'taxInvoiceLabel': taxInvoiceLabel,
        'copyType': copyType,
        'copyIndex': copyIndex,
        'isReprint': isReprint,
        'receiptPurpose': receiptPurpose,
        'receiptId': receiptId,
        'originalReceiptReference': originalReceiptReference,
        'referenceLines':
            referenceLines.map((item) => item.toJson()).toList(growable: false),
        'settlementLines': settlementLines
            .map((item) => item.toJson())
            .toList(growable: false),
        'printerConfigurationId': printerConfigurationId,
        'printerConfigurationVersion': printerConfigurationVersion,
        'brandSubtitle': brandSubtitle,
        'outletLocation': outletLocation,
        'customerName': customerName,
        'issuedAtDisplay': issuedAtDisplay,
        'itemCount': itemCount,
        'presentationLayout': presentationLayout,
        'apiVersion': supportedApiVersion,
        'receiptContractVersion': receiptContractVersion,
      };
}

class LocalPrintAgentPrintResult {
  const LocalPrintAgentPrintResult({
    required this.success,
    required this.code,
    required this.message,
    required this.requestId,
    required this.duplicate,
    required this.printerName,
    this.bytesWritten = 0,
  });

  final bool success;
  final String code;
  final String message;
  final String requestId;
  final bool duplicate;
  final String printerName;
  final int bytesWritten;

  factory LocalPrintAgentPrintResult.fromJson(Map<String, dynamic> json) {
    return LocalPrintAgentPrintResult(
      success: json['success'] == true,
      code: json['code']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      requestId: json['requestId']?.toString() ?? '',
      duplicate: json['duplicate'] == true,
      printerName: json['printerName']?.toString() ?? '',
      bytesWritten: _int(json['bytesWritten']),
    );
  }
}

enum LocalPrintAgentDrawerPurpose {
  cashSale,
  cashRefund,
  splitPaymentCash,
  manualNoSale,
  hardwareTest,
}

class LocalPrintAgentDrawerOpenRequest {
  const LocalPrintAgentDrawerOpenRequest({
    required this.requestId,
    required this.drawerOperationId,
    required this.purpose,
    required this.printerName,
    required this.drawerPort,
    required this.pulseOnMilliseconds,
    required this.pulseOffMilliseconds,
    this.configurationId,
    this.configurationVersion,
    this.posDeviceId,
  });

  final String requestId;
  final String drawerOperationId;
  final LocalPrintAgentDrawerPurpose purpose;
  final String printerName;
  final String drawerPort;
  final int pulseOnMilliseconds;
  final int pulseOffMilliseconds;
  final String? configurationId;
  final int? configurationVersion;
  final String? posDeviceId;

  Map<String, dynamic> toJson() => {
        'apiVersion': LocalPrintAgentReceiptRequest.supportedApiVersion,
        'requestId': requestId,
        'drawerOperationId': drawerOperationId,
        'drawerPurpose': purpose.name,
        'printerName': printerName,
        'drawerPort': drawerPort,
        'pulseOnTime': pulseOnMilliseconds,
        'pulseOffTime': pulseOffMilliseconds,
        'requestedAt': DateTime.now().toUtc().toIso8601String(),
        'configurationId': configurationId,
        'configurationVersion': configurationVersion,
        'posDeviceId': posDeviceId,
      };
}

class LocalPrintAgentDrawerOpenResult {
  const LocalPrintAgentDrawerOpenResult({
    required this.success,
    required this.code,
    required this.message,
    required this.requestId,
    required this.drawerOperationId,
    required this.duplicate,
    required this.printerName,
    required this.physicalOpenConfirmed,
    this.bytesWritten = 0,
  });

  final bool success;
  final String code;
  final String message;
  final String requestId;
  final String drawerOperationId;
  final bool duplicate;
  final String printerName;
  final bool physicalOpenConfirmed;
  final int bytesWritten;

  factory LocalPrintAgentDrawerOpenResult.fromJson(
    Map<String, dynamic> json,
  ) =>
      LocalPrintAgentDrawerOpenResult(
        success: json['success'] == true,
        code: json['code']?.toString() ?? '',
        message: json['message']?.toString() ?? '',
        requestId: json['requestId']?.toString() ?? '',
        drawerOperationId: json['drawerOperationId']?.toString() ?? '',
        duplicate: json['duplicate'] == true,
        printerName: json['printerName']?.toString() ?? '',
        bytesWritten: _int(json['bytesWritten']),
        physicalOpenConfirmed: json['physicalOpenConfirmed'] == true,
      );
}

class LocalPrintAgentOperationStatus {
  const LocalPrintAgentOperationStatus({
    required this.requestId,
    required this.state,
    required this.resultCode,
    required this.claimedAt,
    this.success,
    this.completedAt,
  });

  final String requestId;
  final String state;
  final String resultCode;
  final bool? success;
  final DateTime claimedAt;
  final DateTime? completedAt;

  bool get wasAccepted => state == 'accepted';
  bool get completedSuccessfully => state == 'completed' && success == true;

  factory LocalPrintAgentOperationStatus.fromJson(Map<String, dynamic> json) {
    return LocalPrintAgentOperationStatus(
      requestId: json['requestId']?.toString() ?? '',
      state: json['state']?.toString() ?? '',
      resultCode: json['resultCode']?.toString() ?? '',
      success: json['success'] is bool ? json['success'] as bool : null,
      claimedAt: DateTime.parse(json['claimedAt'].toString()).toUtc(),
      completedAt: _optionalDate(json['completedAt']),
    );
  }
}

enum LocalPrintAgentFailureType {
  invalidConfiguration,
  timeout,
  unreachable,
  authentication,
  duplicate,
  printerUnavailable,
  invalidResponse,
  invalidRequest,
  updateRequired,
  unknown,
}

class LocalPrintAgentException implements Exception {
  const LocalPrintAgentException(this.type, this.message, {this.code});

  final LocalPrintAgentFailureType type;
  final String message;
  final String? code;

  @override
  String toString() => message;
}

String? _optionalText(Object? value) {
  final text = value?.toString().trim() ?? '';
  return text.isEmpty ? null : text;
}

int _int(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

DateTime? _optionalDate(Object? value) {
  final text = value?.toString().trim() ?? '';
  return text.isEmpty ? null : DateTime.tryParse(text)?.toUtc();
}

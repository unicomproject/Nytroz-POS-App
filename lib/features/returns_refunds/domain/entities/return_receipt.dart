class ReturnCompletionItem {
  const ReturnCompletionItem({
    required this.saleLineId,
    required this.name,
    required this.variantLabel,
    required this.quantity,
    required this.unitPrice,
    required this.lineAmount,
    this.imageStorageKey,
    this.isReplacement = false,
    this.salesReturnLineId,
    this.replacementOrderLineId,
    this.productId,
    this.variantId,
    this.sku,
    this.subtotal,
    this.discount,
    this.tax,
    this.total,
    this.reasonCode,
    this.reasonDisplay,
    this.conditionCode,
    this.conditionDisplay,
    this.disposition,
    this.currency,
  });

  final String saleLineId;
  final String name;
  final String variantLabel;
  final double quantity;
  final double unitPrice;
  final double lineAmount;
  final String? imageStorageKey;
  final bool isReplacement;
  final String? salesReturnLineId;
  final String? replacementOrderLineId;
  final String? productId;
  final String? variantId;
  final String? sku;
  final double? subtotal;
  final double? discount;
  final double? tax;
  final double? total;
  final String? reasonCode;
  final String? reasonDisplay;
  final String? conditionCode;
  final String? conditionDisplay;
  final String? disposition;
  final String? currency;

  factory ReturnCompletionItem.fromJson(Map<String, dynamic> json) {
    return ReturnCompletionItem(
      saleLineId: _readString(json, 'saleLineId'),
      name: _readString(json, 'name'),
      variantLabel: _readString(json, 'variantLabel'),
      quantity: _readDouble(json, 'quantity'),
      unitPrice: _readDouble(json, 'unitPrice'),
      lineAmount: _readDouble(json, 'lineAmount'),
      imageStorageKey: _readOptionalString(json, 'imageStorageKey'),
      isReplacement: json['isReplacement'] == true,
      salesReturnLineId: _readOptionalString(json, 'salesReturnLineId'),
      replacementOrderLineId:
          _readOptionalString(json, 'replacementOrderLineId'),
      productId: _readOptionalString(json, 'productId'),
      variantId: _readOptionalString(json, 'variantId'),
      sku: _readOptionalString(json, 'sku'),
      subtotal: _readOptionalDouble(json, 'subtotal'),
      discount: _readOptionalDouble(json, 'discount'),
      tax: _readOptionalDouble(json, 'tax'),
      total: _readOptionalDouble(json, 'total'),
      reasonCode: _readOptionalString(json, 'reasonCode'),
      reasonDisplay: _readOptionalString(json, 'reasonDisplay'),
      conditionCode: _readOptionalString(json, 'conditionCode'),
      conditionDisplay: _readOptionalString(json, 'conditionDisplay'),
      disposition: _readOptionalString(json, 'disposition'),
      currency: _readOptionalString(json, 'currency'),
    );
  }
}

class ReturnReceipt {
  const ReturnReceipt({
    required this.returnId,
    required this.receiptNumber,
    required this.originalInvoiceNo,
    required this.returnedItemCount,
    required this.settlementMethodCode,
    required this.settlementMethodLabel,
    required this.settlementDisplay,
    required this.settlementResult,
    required this.currency,
    required this.refundAmount,
    required this.customerCreditAmount,
    required this.completedAt,
    required this.returnStatus,
    required this.customerName,
    required this.cashierName,
    required this.tillName,
    required this.approvalStatus,
    required this.customerAcknowledgement,
    this.receiptId,
    this.originalSaleId,
    this.resolution = 'REFUND',
    this.canPrint = true,
    this.returnNumber,
    this.exchangeNumber,
    this.salesExchangeId,
    this.replacementOrderNumber,
    this.policyMessage,
    this.returnedItems = const [],
    this.replacementItems = const [],
    this.returnItemValue,
    this.replacementItemValue,
    this.differenceAmount,
    this.differenceDirection,
    this.outletId,
    this.outletName,
    this.tillId,
    this.deviceId,
    this.deviceName,
    this.customerId,
    this.customerDisplayName,
    this.processedByUserId,
    this.processedByName,
    this.receiptType,
    this.originalSaleNumber,
    this.cardBrand,
    this.maskedCard,
    this.providerTransactionReference,
    this.paymentRefundStatus,
    this.amountPaidByCustomer,
    this.amountRefundedToCustomer,
    this.amountDueFromCustomer,
    this.amountDueToCustomer,
    this.returnSubtotal,
    this.returnDiscount,
    this.returnTax,
    this.returnTotal,
    this.replacementSubtotal,
    this.replacementDiscount,
    this.replacementTax,
    this.replacementTotal,
    this.printCount = 0,
    this.hasBeenPrinted = false,
  });

  final String returnId;
  final String receiptNumber;
  final String originalInvoiceNo;
  final int returnedItemCount;
  final String settlementMethodCode;
  final String settlementMethodLabel;
  final String settlementDisplay;
  final String settlementResult;
  final String currency;
  final double refundAmount;
  final double customerCreditAmount;
  final DateTime? completedAt;
  final String returnStatus;
  final String customerName;
  final String cashierName;
  final String tillName;
  final String approvalStatus;
  final String customerAcknowledgement;
  final String? receiptId;
  final String? originalSaleId;
  final String resolution;
  final bool canPrint;
  final String? returnNumber;
  final String? exchangeNumber;
  final String? salesExchangeId;
  final String? replacementOrderNumber;
  final String? policyMessage;
  final List<ReturnCompletionItem> returnedItems;
  final List<ReturnCompletionItem> replacementItems;
  final double? returnItemValue;
  final double? replacementItemValue;
  final double? differenceAmount;
  final String? differenceDirection;
  final String? outletId;
  final String? outletName;
  final String? tillId;
  final String? deviceId;
  final String? deviceName;
  final String? customerId;
  final String? customerDisplayName;
  final String? processedByUserId;
  final String? processedByName;
  final String? receiptType;
  final String? originalSaleNumber;
  final String? cardBrand;
  final String? maskedCard;
  final String? providerTransactionReference;
  final String? paymentRefundStatus;
  final double? amountPaidByCustomer;
  final double? amountRefundedToCustomer;
  final double? amountDueFromCustomer;
  final double? amountDueToCustomer;
  final double? returnSubtotal;
  final double? returnDiscount;
  final double? returnTax;
  final double? returnTotal;
  final double? replacementSubtotal;
  final double? replacementDiscount;
  final double? replacementTax;
  final double? replacementTotal;
  final int printCount;
  final bool hasBeenPrinted;

  bool get isExchange => resolution.trim().toUpperCase() == 'EXCHANGE';

  bool get isCompleted {
    final status = returnStatus.trim().toLowerCase();
    return status.isEmpty ||
        status == 'completed' ||
        status == 'success' ||
        status == 'succeeded' ||
        status == 'complete';
  }

  bool get isCashSettlement {
    final code = settlementMethodCode.trim().toUpperCase();
    return code == 'CASH_REFUND' || code == 'CASH_PAYMENT';
  }

  bool get isEvenExchange {
    if (!isExchange) {
      return false;
    }
    final code = settlementMethodCode.trim().toUpperCase();
    final direction = differenceDirection?.trim().toUpperCase() ?? '';
    return code == 'EVEN_EXCHANGE' ||
        direction == 'EVEN_EXCHANGE' ||
        code == 'NO_SETTLEMENT' ||
        direction == 'NO_SETTLEMENT';
  }

  bool get isStoreCredit {
    return settlementMethodCode.trim().toUpperCase() == 'STORE_CREDIT';
  }

  factory ReturnReceipt.fromJson(Map<String, dynamic> json) {
    final settlementCode = _readString(json, 'settlementMethodCode');
    return ReturnReceipt(
      returnId: _readString(json, 'returnId'),
      receiptNumber: _readString(json, 'receiptNumber'),
      originalInvoiceNo: _readString(json, 'originalInvoiceNo'),
      returnedItemCount: _readInt(json, 'returnedItemCount'),
      settlementMethodCode: settlementCode,
      settlementMethodLabel: _readString(json, 'settlementMethodLabel'),
      settlementDisplay: _readString(json, 'settlementDisplay'),
      settlementResult: _readString(json, 'settlementResult'),
      currency: _readString(json, 'currency'),
      refundAmount: _readDouble(json, 'refundAmount'),
      customerCreditAmount: _readDouble(json, 'customerCreditAmount'),
      completedAt: _readDateTime(json['completedAt']),
      returnStatus: _readString(json, 'returnStatus'),
      customerName: _readString(json, 'customerName'),
      cashierName: _readString(json, 'cashierName'),
      tillName: _readString(json, 'tillName'),
      approvalStatus: _readString(json, 'approvalStatus'),
      customerAcknowledgement: _readString(json, 'customerAcknowledgement'),
      receiptId: _readOptionalString(json, 'receiptId'),
      originalSaleId: _readOptionalString(json, 'originalSaleId'),
      resolution: _readString(json, 'resolution').isEmpty
          ? 'REFUND'
          : _readString(json, 'resolution'),
      canPrint: json['canPrint'] != false,
      returnNumber: _readOptionalString(json, 'returnNumber'),
      exchangeNumber: _readOptionalString(json, 'exchangeNumber'),
      salesExchangeId: _readOptionalString(json, 'salesExchangeId'),
      replacementOrderNumber:
          _readOptionalString(json, 'replacementOrderNumber'),
      policyMessage: _readOptionalString(json, 'policyMessage'),
      returnedItems: _readItems(json['returnedItems']),
      replacementItems: _readItems(json['replacementItems']),
      returnItemValue: _readOptionalDouble(json, 'returnItemValue'),
      replacementItemValue: _readOptionalDouble(json, 'replacementItemValue'),
      differenceAmount: _readOptionalDouble(json, 'differenceAmount'),
      differenceDirection: _readOptionalString(json, 'differenceDirection'),
      outletId: _readOptionalString(json, 'outletId'),
      outletName: _readOptionalString(json, 'outletName'),
      tillId: _readOptionalString(json, 'tillId'),
      deviceId: _readOptionalString(json, 'deviceId'),
      deviceName: _readOptionalString(json, 'deviceName'),
      customerId: _readOptionalString(json, 'customerId'),
      customerDisplayName: _readOptionalString(json, 'customerDisplayName'),
      processedByUserId: _readOptionalString(json, 'processedByUserId'),
      processedByName: _readOptionalString(json, 'processedByName'),
      receiptType: _readOptionalString(json, 'receiptType'),
      originalSaleNumber: _readOptionalString(json, 'originalSaleNumber'),
      cardBrand: _readOptionalString(json, 'cardBrand'),
      maskedCard: _readOptionalString(json, 'maskedCard'),
      providerTransactionReference:
          _readOptionalString(json, 'providerTransactionReference'),
      paymentRefundStatus: _readOptionalString(json, 'paymentRefundStatus'),
      amountPaidByCustomer: _readOptionalDouble(json, 'amountPaidByCustomer'),
      amountRefundedToCustomer:
          _readOptionalDouble(json, 'amountRefundedToCustomer'),
      amountDueFromCustomer: _readOptionalDouble(json, 'amountDueFromCustomer'),
      amountDueToCustomer: _readOptionalDouble(json, 'amountDueToCustomer'),
      returnSubtotal: _readOptionalDouble(json, 'returnSubtotal'),
      returnDiscount: _readOptionalDouble(json, 'returnDiscount'),
      returnTax: _readOptionalDouble(json, 'returnTax'),
      returnTotal: _readOptionalDouble(json, 'returnTotal'),
      replacementSubtotal: _readOptionalDouble(json, 'replacementSubtotal'),
      replacementDiscount: _readOptionalDouble(json, 'replacementDiscount'),
      replacementTax: _readOptionalDouble(json, 'replacementTax'),
      replacementTotal: _readOptionalDouble(json, 'replacementTotal'),
      printCount: _readInt(json, 'printCount'),
      hasBeenPrinted: json['hasBeenPrinted'] == true ||
          _readInt(json, 'printCount') > 0,
    );
  }

  ReturnReceipt copyWith({
    int? printCount,
    bool? hasBeenPrinted,
  }) {
    return ReturnReceipt(
      returnId: returnId,
      receiptNumber: receiptNumber,
      originalInvoiceNo: originalInvoiceNo,
      returnedItemCount: returnedItemCount,
      settlementMethodCode: settlementMethodCode,
      settlementMethodLabel: settlementMethodLabel,
      settlementDisplay: settlementDisplay,
      settlementResult: settlementResult,
      currency: currency,
      refundAmount: refundAmount,
      customerCreditAmount: customerCreditAmount,
      completedAt: completedAt,
      returnStatus: returnStatus,
      customerName: customerName,
      cashierName: cashierName,
      tillName: tillName,
      approvalStatus: approvalStatus,
      customerAcknowledgement: customerAcknowledgement,
      receiptId: receiptId,
      originalSaleId: originalSaleId,
      resolution: resolution,
      canPrint: canPrint,
      returnNumber: returnNumber,
      exchangeNumber: exchangeNumber,
      salesExchangeId: salesExchangeId,
      replacementOrderNumber: replacementOrderNumber,
      policyMessage: policyMessage,
      returnedItems: returnedItems,
      replacementItems: replacementItems,
      returnItemValue: returnItemValue,
      replacementItemValue: replacementItemValue,
      differenceAmount: differenceAmount,
      differenceDirection: differenceDirection,
      outletId: outletId,
      outletName: outletName,
      tillId: tillId,
      deviceId: deviceId,
      deviceName: deviceName,
      customerId: customerId,
      customerDisplayName: customerDisplayName,
      processedByUserId: processedByUserId,
      processedByName: processedByName,
      receiptType: receiptType,
      originalSaleNumber: originalSaleNumber,
      cardBrand: cardBrand,
      maskedCard: maskedCard,
      providerTransactionReference: providerTransactionReference,
      paymentRefundStatus: paymentRefundStatus,
      amountPaidByCustomer: amountPaidByCustomer,
      amountRefundedToCustomer: amountRefundedToCustomer,
      amountDueFromCustomer: amountDueFromCustomer,
      amountDueToCustomer: amountDueToCustomer,
      returnSubtotal: returnSubtotal,
      returnDiscount: returnDiscount,
      returnTax: returnTax,
      returnTotal: returnTotal,
      replacementSubtotal: replacementSubtotal,
      replacementDiscount: replacementDiscount,
      replacementTax: replacementTax,
      replacementTotal: replacementTotal,
      printCount: printCount ?? this.printCount,
      hasBeenPrinted: hasBeenPrinted ?? this.hasBeenPrinted,
    );
  }
}

List<ReturnCompletionItem> _readItems(Object? value) {
  if (value is! List) {
    return const [];
  }
  return value
      .whereType<Map<String, dynamic>>()
      .map(ReturnCompletionItem.fromJson)
      .toList(growable: false);
}

String _readString(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value == null) {
    return '';
  }
  return value.toString();
}

String? _readOptionalString(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value == null) {
    return null;
  }
  final text = value.toString().trim();
  return text.isEmpty ? null : text;
}

double _readDouble(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is num) {
    return value.toDouble();
  }
  return double.tryParse(value?.toString() ?? '') ?? 0;
}

double? _readOptionalDouble(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value == null) {
    return null;
  }
  if (value is num) {
    return value.toDouble();
  }
  return double.tryParse(value.toString());
}

int _readInt(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is num) {
    return value.toInt();
  }
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

DateTime? _readDateTime(Object? value) {
  if (value == null) {
    return null;
  }
  if (value is DateTime) {
    return value.toLocal();
  }
  return DateTime.tryParse(value.toString())?.toLocal();
}

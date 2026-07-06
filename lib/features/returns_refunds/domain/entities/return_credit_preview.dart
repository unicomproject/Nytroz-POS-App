class ReturnCreditPreviewItem {
  const ReturnCreditPreviewItem({
    required this.saleLineId,
    required this.name,
    required this.sku,
    required this.variantLabel,
    this.imageStorageKey,
    required this.returnQty,
    required this.unitPrice,
    required this.lineAmount,
  });

  final String saleLineId;
  final String name;
  final String sku;
  final String variantLabel;
  final String? imageStorageKey;
  final double returnQty;
  final double unitPrice;
  final double lineAmount;

  factory ReturnCreditPreviewItem.fromJson(Map<String, dynamic> json) {
    return ReturnCreditPreviewItem(
      saleLineId: _readString(json, 'saleLineId'),
      name: _readString(json, 'name'),
      sku: _readString(json, 'sku'),
      variantLabel: _readString(json, 'variantLabel'),
      imageStorageKey: _readNullableString(json, 'imageStorageKey'),
      returnQty: _readDouble(json, 'returnQty'),
      unitPrice: _readDouble(json, 'unitPrice'),
      lineAmount: _readDouble(json, 'lineAmount'),
    );
  }
}

class ReturnCreditCalculation {
  const ReturnCreditCalculation({
    required this.itemValue,
    required this.discountLabel,
    required this.discountAdjustment,
    required this.taxLabel,
    required this.taxAdjustment,
    required this.netCreditAmount,
  });

  final double itemValue;
  final String discountLabel;
  final double discountAdjustment;
  final String taxLabel;
  final double taxAdjustment;
  final double netCreditAmount;

  factory ReturnCreditCalculation.fromJson(Map<String, dynamic> json) {
    return ReturnCreditCalculation(
      itemValue: _readDouble(json, 'itemValue'),
      discountLabel: _readString(json, 'discountLabel'),
      discountAdjustment: _readDouble(json, 'discountAdjustment'),
      taxLabel: _readString(json, 'taxLabel'),
      taxAdjustment: _readDouble(json, 'taxAdjustment'),
      netCreditAmount: _readDouble(json, 'netCreditAmount'),
    );
  }
}

class ReturnCreditPreview {
  const ReturnCreditPreview({
    required this.saleId,
    required this.invoiceNo,
    this.customerId,
    required this.customerName,
    required this.customerDisplayId,
    this.saleDate,
    required this.paymentMethod,
    required this.maskedCard,
    required this.currency,
    required this.saleTotal,
    required this.saleItemCount,
    required this.reasonCode,
    required this.reasonLabel,
    required this.items,
    required this.calculation,
    required this.creditReference,
    required this.validityDays,
    this.expiresAt,
    required this.selectedItemCount,
  });

  final String saleId;
  final String invoiceNo;
  final String? customerId;
  final String customerName;
  final String customerDisplayId;
  final DateTime? saleDate;
  final String paymentMethod;
  final String maskedCard;
  final String currency;
  final double saleTotal;
  final int saleItemCount;
  final String reasonCode;
  final String reasonLabel;
  final List<ReturnCreditPreviewItem> items;
  final ReturnCreditCalculation calculation;
  final String creditReference;
  final int validityDays;
  final DateTime? expiresAt;
  final int selectedItemCount;

  factory ReturnCreditPreview.fromJson(Map<String, dynamic> json) {
    final itemsJson = json['items'];

    return ReturnCreditPreview(
      saleId: _readString(json, 'saleId'),
      invoiceNo: _readString(json, 'invoiceNo'),
      customerId: _readNullableString(json, 'customerId'),
      customerName: _readString(json, 'customerName'),
      customerDisplayId: _readString(json, 'customerDisplayId'),
      saleDate: _readDateTime(json['saleDate']),
      paymentMethod: _readString(json, 'paymentMethod'),
      maskedCard: _readString(json, 'maskedCard'),
      currency: _readString(json, 'currency'),
      saleTotal: _readDouble(json, 'saleTotal'),
      saleItemCount: _readInt(json, 'saleItemCount'),
      reasonCode: _readString(json, 'reasonCode'),
      reasonLabel: _readString(json, 'reasonLabel'),
      items: itemsJson is List
          ? itemsJson
              .whereType<Map<String, dynamic>>()
              .map(ReturnCreditPreviewItem.fromJson)
              .toList(growable: false)
          : const [],
      calculation: ReturnCreditCalculation.fromJson(
        json['calculation'] is Map<String, dynamic>
            ? json['calculation'] as Map<String, dynamic>
            : const {},
      ),
      creditReference: _readString(json, 'creditReference'),
      validityDays: _readInt(json, 'validityDays'),
      expiresAt: _readDateTime(json['expiresAt']),
      selectedItemCount: _readInt(json, 'selectedItemCount'),
    );
  }

  String get paymentDisplay {
    if (maskedCard.isNotEmpty && paymentMethod.isNotEmpty) {
      return '$paymentMethod $maskedCard';
    }
    if (paymentMethod.isNotEmpty) {
      return paymentMethod;
    }
    return maskedCard;
  }
}

String _readString(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value == null) {
    return '';
  }
  return value.toString();
}

String? _readNullableString(Map<String, dynamic> json, String key) {
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

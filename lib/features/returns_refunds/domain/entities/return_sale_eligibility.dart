class ReturnLineSelection {
  const ReturnLineSelection({
    required this.saleLineId,
    required this.isSelected,
    required this.returnQty,
  });

  final String saleLineId;
  final bool isSelected;
  final int returnQty;

  ReturnLineSelection copyWith({
    bool? isSelected,
    int? returnQty,
  }) {
    return ReturnLineSelection(
      saleLineId: saleLineId,
      isSelected: isSelected ?? this.isSelected,
      returnQty: returnQty ?? this.returnQty,
    );
  }
}

class ReturnPolicyCheck {
  const ReturnPolicyCheck({
    required this.label,
    required this.value,
    required this.passed,
  });

  final String label;
  final String value;
  final bool passed;

  factory ReturnPolicyCheck.fromJson(Map<String, dynamic> json) {
    return ReturnPolicyCheck(
      label: _readString(json, 'label'),
      value: _readString(json, 'value'),
      passed: json['passed'] == true,
    );
  }
}

class ReturnSaleLineEligibility {
  const ReturnSaleLineEligibility({
    required this.saleLineId,
    required this.variantId,
    required this.name,
    required this.sku,
    this.imageStorageKey,
    required this.soldQty,
    required this.returnedQty,
    required this.availableReturnQty,
    required this.unitPrice,
    required this.lineTotal,
    required this.isReturnable,
    required this.eligibilityStatus,
    this.ineligibilityReason,
  });

  final String saleLineId;
  final String variantId;
  final String name;
  final String sku;
  final String? imageStorageKey;
  final double soldQty;
  final double returnedQty;
  final double availableReturnQty;
  final double unitPrice;
  final double lineTotal;
  final bool isReturnable;
  final String eligibilityStatus;
  final String? ineligibilityReason;

  factory ReturnSaleLineEligibility.fromJson(Map<String, dynamic> json) {
    return ReturnSaleLineEligibility(
      saleLineId: _readString(json, 'saleLineId'),
      variantId: _readString(json, 'variantId'),
      name: _readString(json, 'name'),
      sku: _readString(json, 'sku'),
      imageStorageKey: _readNullableString(json, 'imageStorageKey'),
      soldQty: _readDouble(json, 'soldQty'),
      returnedQty: _readDouble(json, 'returnedQty'),
      availableReturnQty: _readDouble(json, 'availableReturnQty'),
      unitPrice: _readDouble(json, 'unitPrice'),
      lineTotal: _readDouble(json, 'lineTotal'),
      isReturnable: json['isReturnable'] == true,
      eligibilityStatus: _readString(json, 'eligibilityStatus'),
      ineligibilityReason: _readNullableString(json, 'ineligibilityReason'),
    );
  }

  int get maxReturnQty => availableReturnQty.floor().clamp(0, 999999);
}

class ReturnSaleEligibility {
  const ReturnSaleEligibility({
    required this.saleId,
    required this.invoiceNo,
    this.customerId,
    required this.customerName,
    this.saleDate,
    required this.paymentMethod,
    required this.maskedCard,
    required this.currency,
    required this.items,
    required this.policyChecks,
  });

  final String saleId;
  final String invoiceNo;
  final String? customerId;
  final String customerName;
  final DateTime? saleDate;
  final String paymentMethod;
  final String maskedCard;
  final String currency;
  final List<ReturnSaleLineEligibility> items;
  final List<ReturnPolicyCheck> policyChecks;

  factory ReturnSaleEligibility.fromJson(Map<String, dynamic> json) {
    final itemsJson = json['items'];
    final checksJson = json['policyChecks'];

    return ReturnSaleEligibility(
      saleId: _readString(json, 'saleId'),
      invoiceNo: _readString(json, 'invoiceNo'),
      customerId: _readNullableString(json, 'customerId'),
      customerName: _readString(json, 'customerName'),
      saleDate: _readDateTime(json['saleDate']),
      paymentMethod: _readString(json, 'paymentMethod'),
      maskedCard: _readString(json, 'maskedCard'),
      currency: _readString(json, 'currency'),
      items: itemsJson is List
          ? itemsJson
              .whereType<Map<String, dynamic>>()
              .map(ReturnSaleLineEligibility.fromJson)
              .toList(growable: false)
          : const [],
      policyChecks: checksJson is List
          ? checksJson
              .whereType<Map<String, dynamic>>()
              .map(ReturnPolicyCheck.fromJson)
              .toList(growable: false)
          : const [],
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

DateTime? _readDateTime(Object? value) {
  if (value == null) {
    return null;
  }
  if (value is DateTime) {
    return value.toLocal();
  }
  return DateTime.tryParse(value.toString())?.toLocal();
}

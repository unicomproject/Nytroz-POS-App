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
    this.code = '',
    this.description = '',
    this.status = '',
    this.severity = '',
    this.reason,
    this.requiresReview = false,
  });

  final String label;
  final String value;
  final bool passed;
  final String code;
  final String description;
  final String status;
  final String severity;
  final String? reason;
  final bool requiresReview;

  factory ReturnPolicyCheck.fromJson(Map<String, dynamic> json) {
    return ReturnPolicyCheck(
      label: _readString(json, 'label'),
      value: _readString(json, 'value'),
      passed: json['passed'] == true,
      code: _readString(json, 'code'),
      description: _readString(json, 'description'),
      status: _readString(json, 'status'),
      severity: _readString(json, 'severity'),
      reason: _readNullableString(json, 'reason'),
      requiresReview: json['requiresReview'] == true,
    );
  }

  String get displayStatus {
    if (status.isNotEmpty) {
      return status;
    }
    // Do not invent PASSED/FAILED from the boolean when status is absent.
    return 'UNKNOWN';
  }
}

class ReturnSaleLineEligibility {
  const ReturnSaleLineEligibility({
    required this.saleLineId,
    required this.variantId,
    required this.name,
    required this.sku,
    this.barcode,
    this.imageStorageKey,
    required this.soldQty,
    required this.returnedQty,
    required this.availableReturnQty,
    required this.unitPrice,
    required this.lineTotal,
    required this.isReturnable,
    required this.eligibilityStatus,
    this.ineligibilityReason,
    this.requestedReturnQty,
    this.eligibleReturnQty,
  });

  final String saleLineId;
  final String variantId;
  final String name;
  final String sku;
  final String? barcode;
  final String? imageStorageKey;
  final double soldQty;
  final double returnedQty;
  final double availableReturnQty;
  final double unitPrice;
  final double lineTotal;
  final bool isReturnable;
  final String eligibilityStatus;
  final String? ineligibilityReason;
  final double? requestedReturnQty;
  final double? eligibleReturnQty;

  factory ReturnSaleLineEligibility.fromJson(Map<String, dynamic> json) {
    return ReturnSaleLineEligibility(
      saleLineId: _readString(json, 'saleLineId'),
      variantId: _readString(json, 'variantId'),
      name: _readString(json, 'name'),
      sku: _readString(json, 'sku'),
      barcode: _readNullableString(json, 'barcode'),
      imageStorageKey: _readNullableString(json, 'imageStorageKey'),
      soldQty: _readDouble(json, 'soldQty'),
      returnedQty: _readDouble(json, 'returnedQty'),
      availableReturnQty: _readDouble(json, 'availableReturnQty'),
      unitPrice: _readDouble(json, 'unitPrice'),
      lineTotal: _readDouble(json, 'lineTotal'),
      isReturnable: json['isReturnable'] == true,
      eligibilityStatus: _readString(json, 'eligibilityStatus'),
      ineligibilityReason: _readNullableString(json, 'ineligibilityReason'),
      requestedReturnQty: _readNullableDouble(json, 'requestedReturnQty'),
      eligibleReturnQty: _readNullableDouble(json, 'eligibleReturnQty'),
    );
  }

  int get maxReturnQty => availableReturnQty.floor().clamp(0, 999999);

  /// Selectable only when backend marks returnable and remaining qty is positive.
  bool get isSelectable =>
      saleLineId.isNotEmpty && isReturnable && maxReturnQty > 0;
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
    this.overallStatus = '',
    this.canContinue = false,
    this.eligibleItemCount = 0,
    this.selectedItemCount = 0,
    this.overallMessage = '',
    this.policyNote,
    this.requiresInspection = false,
    this.requiresManagerApproval = false,
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
  final String overallStatus;
  final bool canContinue;
  final int eligibleItemCount;
  final int selectedItemCount;
  final String overallMessage;
  final String? policyNote;
  final bool requiresInspection;
  final bool requiresManagerApproval;

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
      overallStatus: _readString(json, 'overallStatus'),
      canContinue: json['canContinue'] == true,
      eligibleItemCount: _readInt(json, 'eligibleItemCount'),
      selectedItemCount: _readInt(json, 'selectedItemCount'),
      overallMessage: _readString(json, 'overallMessage'),
      policyNote: _readNullableString(json, 'policyNote'),
      requiresInspection: json['requiresInspection'] == true,
      requiresManagerApproval: json['requiresManagerApproval'] == true,
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

  String get customerDisplay {
    final trimmed = customerName.trim();
    return trimmed.isEmpty ? 'Walk-in Customer' : trimmed;
  }

  String get statusDisplayLabel {
    switch (overallStatus) {
      case 'ELIGIBLE':
        return 'Eligible to Continue';
      case 'ELIGIBLE_WITH_WARNINGS':
        return 'Eligible to Continue';
      case 'PARTIALLY_ELIGIBLE':
        return 'Partially Eligible';
      case 'UNDER_REVIEW':
        return 'Under Review';
      case 'NOT_ELIGIBLE':
        return 'Not Eligible';
      default:
        return overallStatus.isEmpty ? 'Pending Review' : overallStatus;
    }
  }

  bool get isEligibleOverall =>
      overallStatus == 'ELIGIBLE' || overallStatus == 'ELIGIBLE_WITH_WARNINGS';

  bool get hasWarnings =>
      overallStatus == 'ELIGIBLE_WITH_WARNINGS' ||
      overallStatus == 'UNDER_REVIEW' ||
      requiresInspection ||
      requiresManagerApproval ||
      policyChecks.any(
        (check) =>
            check.status == 'UNDER_REVIEW' ||
            check.status == 'REQUIRES_REVIEW' ||
            check.requiresReview,
      );
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

double? _readNullableDouble(Map<String, dynamic> json, String key) {
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
  if (value is int) {
    return value;
  }
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

enum PosDiscountValueType {
  percentage,
  fixedAmount;

  String get label {
    return switch (this) {
      PosDiscountValueType.percentage => 'Percentage',
      PosDiscountValueType.fixedAmount => 'Fixed Amount',
    };
  }
}

class PosCartDiscount {
  const PosCartDiscount({
    required this.valueType,
    required this.value,
    this.reason,
    this.policyId,
    this.applicationId,
    this.status = 'local',
    this.cartHash,
    this.source = 'MANUAL',
    this.scope = 'ORDER',
    this.targetVariantId,
    this.discountAmount,
    this.totalAfterDiscount,
    this.currencyCode = 'LKR',
    this.expiresAt,
  });

  final PosDiscountValueType valueType;
  final double value;
  final String? reason;
  final String? policyId;
  final String? applicationId;
  final String status;
  final String? cartHash;
  final String source;
  final String scope;
  final String? targetVariantId;
  final int? discountAmount;
  final int? totalAfterDiscount;
  final String currencyCode;
  final DateTime? expiresAt;

  bool get isBackendApproved =>
      applicationId != null && (status == 'approved' || status == 'applied');
  bool get isPendingApproval => status == 'pending_approval';

  PosCartDiscount copyWith({String? status}) => PosCartDiscount(
        valueType: valueType,
        value: value,
        reason: reason,
        policyId: policyId,
        applicationId: applicationId,
        status: status ?? this.status,
        cartHash: cartHash,
        source: source,
        scope: scope,
        targetVariantId: targetVariantId,
        discountAmount: discountAmount,
        totalAfterDiscount: totalAfterDiscount,
        currencyCode: currencyCode,
        expiresAt: expiresAt,
      );

  int amountFor(int baseAmount) {
    if (baseAmount <= 0 || value <= 0) {
      return 0;
    }

    final authoritativeAmount = discountAmount;
    if (authoritativeAmount != null) {
      return authoritativeAmount.clamp(0, baseAmount);
    }

    final amount = switch (valueType) {
      PosDiscountValueType.percentage => (baseAmount * value / 100).round(),
      PosDiscountValueType.fixedAmount => value.round(),
    };

    return amount.clamp(0, baseAmount).toInt();
  }

  Map<String, dynamic> toJson() {
    return {
      'valueType': valueType.name,
      'value': value,
      'reason': reason,
      'policyId': policyId,
      'applicationId': applicationId,
      'status': status,
      'cartHash': cartHash,
      'source': source,
      'scope': scope,
      'targetVariantId': targetVariantId,
      'discountAmount': discountAmount,
      'totalAfterDiscount': totalAfterDiscount,
      'currencyCode': currencyCode,
      'expiresAt': expiresAt?.toIso8601String(),
    };
  }

  factory PosCartDiscount.fromJson(Map<String, dynamic> json) {
    final typeName = json['valueType']?.toString();
    final valueType = PosDiscountValueType.values.firstWhere(
      (type) => type.name == typeName,
      orElse: () => PosDiscountValueType.percentage,
    );

    return PosCartDiscount(
      valueType: valueType,
      value: _doubleValue(json['value']),
      reason: _nullableString(json['reason']),
      policyId: _nullableString(json['policyId']),
      applicationId: _nullableString(json['applicationId']),
      status: _nullableString(json['status']) ?? 'local',
      cartHash: _nullableString(json['cartHash']),
      source: _nullableString(json['source']) ?? 'MANUAL',
      scope: _nullableString(json['scope']) ?? 'ORDER',
      targetVariantId: _nullableString(json['targetVariantId']),
      discountAmount: _nullableInt(json['discountAmount']),
      totalAfterDiscount: _nullableInt(json['totalAfterDiscount']),
      currencyCode: _nullableString(json['currencyCode']) ?? 'LKR',
      expiresAt: DateTime.tryParse(json['expiresAt']?.toString() ?? ''),
    );
  }
}

int? _nullableInt(Object? value) {
  if (value == null) return null;
  if (value is num) return value.round();
  return int.tryParse(value.toString());
}

double _doubleValue(Object? value) {
  if (value is double) {
    return value;
  }
  if (value is int) {
    return value.toDouble();
  }
  if (value is num) {
    return value.toDouble();
  }
  return double.tryParse(value?.toString() ?? '') ?? 0;
}

String? _nullableString(Object? value) {
  final trimmed = value?.toString().trim();
  if (trimmed == null || trimmed.isEmpty) {
    return null;
  }
  return trimmed;
}

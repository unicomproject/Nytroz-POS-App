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
  });

  final PosDiscountValueType valueType;
  final double value;
  final String? reason;

  int amountFor(int baseAmount) {
    if (baseAmount <= 0 || value <= 0) {
      return 0;
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
    );
  }
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

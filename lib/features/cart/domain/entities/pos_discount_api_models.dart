class PosDiscountAuthority {
  const PosDiscountAuthority({
    required this.maxPercentage,
    required this.maxFixedAmount,
    required this.currencyCode,
  });

  final double maxPercentage;
  final double maxFixedAmount;
  final String currencyCode;

  factory PosDiscountAuthority.fromJson(Map<String, dynamic> json) =>
      PosDiscountAuthority(
        maxPercentage: _double(json['maxPercentage']),
        maxFixedAmount: _double(json['maxFixedAmount']),
        currencyCode: json['currencyCode']?.toString() ?? 'LKR',
      );
}

class PosDiscountPolicy {
  const PosDiscountPolicy({
    required this.id,
    required this.code,
    required this.name,
    required this.scope,
    required this.calculationMethod,
    required this.predefinedValue,
    required this.absoluteValueLimit,
    required this.cashierValueLimit,
    required this.requiresManagerApproval,
    this.description,
  });

  final String id;
  final String code;
  final String name;
  final String? description;
  final String scope;
  final String calculationMethod;
  final double predefinedValue;
  final double absoluteValueLimit;
  final double cashierValueLimit;
  final bool requiresManagerApproval;

  bool get isPercentage => calculationMethod == 'PERCENTAGE';

  factory PosDiscountPolicy.fromJson(Map<String, dynamic> json) =>
      PosDiscountPolicy(
        id: json['id']?.toString() ?? '',
        code: json['code']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        description: json['description']?.toString(),
        scope: json['scope']?.toString() ?? 'ORDER',
        calculationMethod: json['calculationMethod']?.toString() ?? '',
        predefinedValue: _double(json['predefinedValue']),
        absoluteValueLimit: _double(json['absoluteValueLimit']),
        cashierValueLimit: _double(json['cashierValueLimit']),
        requiresManagerApproval: json['requiresManagerApproval'] == true,
      );
}

class PosDiscountCatalog {
  const PosDiscountCatalog({required this.authority, required this.discounts});
  final PosDiscountAuthority authority;
  final List<PosDiscountPolicy> discounts;

  factory PosDiscountCatalog.fromJson(Map<String, dynamic> json) =>
      PosDiscountCatalog(
        authority: PosDiscountAuthority.fromJson(_map(json['authority'])),
        discounts: _list(json['discounts'])
            .map((x) => PosDiscountPolicy.fromJson(_map(x)))
            .where((x) => x.id.isNotEmpty)
            .toList(growable: false),
      );
}

class PosDiscountApplyResult {
  const PosDiscountApplyResult({
    required this.applicationId,
    required this.discountId,
    required this.applied,
    required this.status,
    required this.subtotal,
    required this.discountAmount,
    required this.totalAfterDiscount,
    required this.requiresManagerApproval,
    required this.cartHash,
    required this.messages,
  });

  final String applicationId;
  final String discountId;
  final bool applied;
  final String status;
  final int subtotal;
  final int discountAmount;
  final int totalAfterDiscount;
  final bool requiresManagerApproval;
  final String cartHash;
  final List<String> messages;

  factory PosDiscountApplyResult.fromJson(Map<String, dynamic> json) =>
      PosDiscountApplyResult(
        applicationId: json['applicationId']?.toString() ?? '',
        discountId: json['discountId']?.toString() ?? '',
        applied: json['applied'] == true,
        status: json['status']?.toString() ?? '',
        subtotal: _int(json['subtotal']),
        discountAmount: _int(json['discountAmount']),
        totalAfterDiscount: _int(json['totalAfterDiscount']),
        requiresManagerApproval: json['requiresManagerApproval'] == true,
        cartHash: json['cartHash']?.toString() ?? '',
        messages: _list(json['messages']).map((x) => x.toString()).toList(),
      );
}

class PosDiscountValidationResult {
  const PosDiscountValidationResult({
    required this.discountId,
    required this.isValid,
    required this.outcome,
    required this.calculationMethod,
    required this.requestedValue,
    required this.cashierLimit,
    required this.absoluteLimit,
    required this.subtotal,
    required this.eligibleSubtotal,
    required this.discountAmount,
    required this.totalAfterDiscount,
    required this.currencyCode,
    required this.cartHash,
    required this.validationMessages,
  });

  final String discountId;
  final bool isValid;
  final String outcome;
  final String calculationMethod;
  final double requestedValue;
  final double cashierLimit;
  final double absoluteLimit;
  final int subtotal;
  final int eligibleSubtotal;
  final int discountAmount;
  final int totalAfterDiscount;
  final String currencyCode;
  final String cartHash;
  final List<String> validationMessages;

  factory PosDiscountValidationResult.fromJson(Map<String, dynamic> json) =>
      PosDiscountValidationResult(
        discountId: json['discountId']?.toString() ?? '',
        isValid: json['isValid'] == true,
        outcome: json['outcome']?.toString() ?? '',
        calculationMethod: json['calculationMethod']?.toString() ?? '',
        requestedValue: _double(json['requestedValue']),
        cashierLimit: _double(json['cashierLimit']),
        absoluteLimit: _double(json['absoluteLimit']),
        subtotal: _int(json['subtotal']),
        eligibleSubtotal: _int(json['eligibleSubtotal']),
        discountAmount: _int(json['discountAmount']),
        totalAfterDiscount: _int(json['totalAfterDiscount']),
        currencyCode: json['currencyCode']?.toString() ?? 'LKR',
        cartHash: json['cartHash']?.toString() ?? '',
        validationMessages:
            _list(json['validationMessages']).map((x) => x.toString()).toList(),
      );
}

Map<String, dynamic> _map(Object? value) =>
    value is Map ? Map<String, dynamic>.from(value) : const {};
List<dynamic> _list(Object? value) => value is List ? value : const [];
double _double(Object? value) =>
    value is num ? value.toDouble() : double.tryParse('$value') ?? 0;
int _int(Object? value) =>
    value is num ? value.round() : int.tryParse('$value') ?? 0;

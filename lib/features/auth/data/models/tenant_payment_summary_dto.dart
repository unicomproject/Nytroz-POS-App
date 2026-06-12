class TenantPaymentSummaryDto {
  const TenantPaymentSummaryDto({
    required this.paymentToken,
    required this.tenantName,
    required this.planName,
    required this.billingPeriod,
    required this.amount,
    required this.currency,
    required this.totalPayable,
    required this.paymentStatus,
    this.taxAmount,
  });

  factory TenantPaymentSummaryDto.fromJson(Map<String, dynamic> json) {
    return TenantPaymentSummaryDto(
      paymentToken: json['paymentToken'] as String? ?? '',
      tenantName: json['tenantName'] as String? ?? '',
      planName: json['planName'] as String? ?? '',
      billingPeriod: json['billingPeriod'] as String? ?? '',
      amount: json['amount']?.toString() ?? '',
      currency: json['currency'] as String? ?? '',
      taxAmount: json['taxAmount']?.toString(),
      totalPayable: json['totalPayable']?.toString() ?? '',
      paymentStatus: json['paymentStatus'] as String? ?? '',
    );
  }

  final String paymentToken;
  final String tenantName;
  final String planName;
  final String billingPeriod;
  final String amount;
  final String currency;
  final String? taxAmount;
  final String totalPayable;
  final String paymentStatus;
}

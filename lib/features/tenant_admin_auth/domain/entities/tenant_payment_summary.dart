class TenantPaymentSummary {
  const TenantPaymentSummary({
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

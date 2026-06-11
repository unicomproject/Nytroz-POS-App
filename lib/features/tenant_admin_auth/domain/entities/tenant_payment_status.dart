class TenantPaymentStatus {
  const TenantPaymentStatus({
    required this.paymentToken,
    required this.status,
    this.message,
    this.redirectUrl,
  });

  final String paymentToken;
  final String status;
  final String? message;
  final String? redirectUrl;

  bool get isSuccess =>
      status.toLowerCase() == 'success' || status.toLowerCase() == 'paid';
  bool get isFailed => status.toLowerCase() == 'failed';
}

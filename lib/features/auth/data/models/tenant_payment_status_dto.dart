class TenantPaymentStatusDto {
  const TenantPaymentStatusDto({
    required this.paymentToken,
    required this.status,
    this.message,
    this.redirectUrl,
  });

  factory TenantPaymentStatusDto.fromJson(Map<String, dynamic> json) {
    return TenantPaymentStatusDto(
      paymentToken: json['paymentToken'] as String? ?? '',
      status: json['status'] as String? ?? '',
      message: json['message'] as String?,
      redirectUrl: json['redirectUrl'] as String?,
    );
  }

  final String paymentToken;
  final String status;
  final String? message;
  final String? redirectUrl;
}

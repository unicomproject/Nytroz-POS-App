import '../../domain/entities/setup_token_validation.dart';
import '../../domain/entities/tenant_admin_session.dart';
import '../../domain/entities/tenant_payment_status.dart';
import '../../domain/entities/tenant_payment_summary.dart';
import '../models/setup_token_validation_dto.dart';
import '../models/tenant_payment_status_dto.dart';
import '../models/tenant_payment_summary_dto.dart';

extension TenantPaymentSummaryDtoMapper on TenantPaymentSummaryDto {
  TenantPaymentSummary toEntity() {
    return TenantPaymentSummary(
      paymentToken: paymentToken,
      tenantName: tenantName,
      planName: planName,
      billingPeriod: billingPeriod,
      amount: amount,
      currency: currency,
      taxAmount: taxAmount,
      totalPayable: totalPayable,
      paymentStatus: paymentStatus,
    );
  }
}

extension TenantPaymentStatusDtoMapper on TenantPaymentStatusDto {
  TenantPaymentStatus toEntity() {
    return TenantPaymentStatus(
      paymentToken: paymentToken,
      status: status,
      message: message,
      redirectUrl: redirectUrl,
    );
  }
}

extension SetupTokenValidationDtoMapper on SetupTokenValidationDto {
  SetupTokenValidation toEntity() {
    return SetupTokenValidation(
      setupToken: setupToken,
      valid: valid,
      expired: expired,
      email: email,
      message: message,
    );
  }
}

TenantAdminSession tenantAdminSessionFromJson(Map<String, dynamic> json) {
  return TenantAdminSession(
    accessToken:
        json['accessToken'] as String? ?? json['token'] as String? ?? '',
    refreshToken: json['refreshToken'] as String?,
    userId: json['userId'] as String? ?? '',
    userDisplayName: json['userDisplayName'] as String? ?? '',
    expiresAt: DateTime.tryParse(json['expiresAt']?.toString() ?? ''),
  );
}

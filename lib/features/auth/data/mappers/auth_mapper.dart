import '../../domain/entities/setup_token_validation.dart';
import '../../domain/entities/auth_branding.dart';
import '../../domain/entities/auth_exception.dart';
import '../../domain/entities/auth_session.dart';
import '../../domain/entities/tenant_payment_status.dart';
import '../../domain/entities/tenant_payment_summary.dart';
import '../models/setup_token_validation_dto.dart';
import '../models/auth_branding_dto.dart';
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

extension AuthBrandingDtoMapper on AuthBrandingDto {
  AuthBranding toEntity() {
    return AuthBranding(
      logoUrl: logoUrl,
      loginIllustrationUrl: loginIllustrationUrl,
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

AuthSession authSessionFromJson(Map<String, dynamic> json) {
  final payload = json['data'] is Map<String, dynamic>
      ? json['data'] as Map<String, dynamic>
      : json;
  final user = payload['user'] is Map<String, dynamic>
      ? payload['user'] as Map<String, dynamic>
      : const <String, dynamic>{};
  final accessToken =
      payload['accessToken'] as String? ?? payload['token'] as String? ?? '';

  if (accessToken.isEmpty) {
    throw const AuthException(
      errorCode: 'INVALID_LOGIN_RESPONSE',
      message: 'Login response did not include an access token.',
    );
  }

  return AuthSession(
    accessToken: accessToken,
    refreshToken: payload['refreshToken'] as String?,
    userId: user['id']?.toString() ?? payload['userId']?.toString() ?? '',
    userDisplayName: user['fullName'] as String? ??
        user['username'] as String? ??
        user['email'] as String? ??
        payload['userDisplayName'] as String? ??
        '',
    permissionCodes: _permissionCodesFromJson(payload),
    expiresAt: DateTime.tryParse(
      payload['accessTokenExpiresAt']?.toString() ??
          payload['expiresAt']?.toString() ??
          '',
    ),
  );
}

List<String> _permissionCodesFromJson(Map<String, dynamic> payload) {
  final rawPermissionCodes = payload['permissionCodes'];
  if (rawPermissionCodes is Iterable) {
    return rawPermissionCodes
        .map((item) => item.toString())
        .where((item) => item.trim().isNotEmpty)
        .toList(growable: false);
  }

  final rawPermissions = payload['permissions'];
  if (rawPermissions is Iterable) {
    return rawPermissions
        .map((item) {
          if (item is Map) {
            return item['permissionCode']?.toString() ??
                item['code']?.toString();
          }

          return item.toString();
        })
        .whereType<String>()
        .where((item) => item.trim().isNotEmpty)
        .toList(growable: false);
  }

  return const [];
}

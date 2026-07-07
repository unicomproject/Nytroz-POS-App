import 'dart:developer' as developer;
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
  final rawPayload = json['data'] ?? json['Data'];
  final payload = rawPayload is Map<String, dynamic> ? rawPayload : json;
  final rawUser = payload['user'] ?? payload['User'];
  final user =
      rawUser is Map<String, dynamic> ? rawUser : const <String, dynamic>{};
  final accessToken = payload['accessToken'] as String? ??
      payload['AccessToken'] as String? ??
      payload['token'] as String? ??
      payload['Token'] as String? ??
      '';

  if (accessToken.isEmpty) {
    throw const AuthException(
      errorCode: 'INVALID_LOGIN_RESPONSE',
      message: 'Login response did not include an access token.',
    );
  }

  return AuthSession(
    accessToken: accessToken,
    refreshToken: payload['refreshToken'] as String? ??
        payload['RefreshToken'] as String?,
    userId: user['tenantUserId']?.toString() ??
        user['TenantUserId']?.toString() ??
        user['id']?.toString() ??
        user['Id']?.toString() ??
        payload['userId']?.toString() ??
        payload['UserId']?.toString() ??
        '',
    userDisplayName: user['fullName'] as String? ??
        user['FullName'] as String? ??
        user['username'] as String? ??
        user['Username'] as String? ??
        user['email'] as String? ??
        user['Email'] as String? ??
        user['tenantUserId']?.toString() ??
        payload['userDisplayName'] as String? ??
        payload['UserDisplayName'] as String? ??
        '',
    permissionCodes: _permissionCodesFromJson(payload),
    expiresAt: DateTime.tryParse(
      payload['accessTokenExpiresAt']?.toString() ??
          payload['AccessTokenExpiresAt']?.toString() ??
          payload['expiresAt']?.toString() ??
          payload['ExpiresAt']?.toString() ??
          '',
    ),
  );
}

List<String> _permissionCodesFromJson(Map<String, dynamic> payload) {
  final rawPermissionCodes = payload['permissionCodes'] ??
      payload['PermissionCodes'] ??
      _mapValue(payload['user'], 'permissionCodes') ??
      _mapValue(payload['user'], 'PermissionCodes');
  if (rawPermissionCodes is Iterable) {
    return rawPermissionCodes
        .map((item) => item.toString())
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
  }

  final rawPermissions = payload['permissions'] ??
      payload['Permissions'] ??
      _mapValue(payload['user'], 'permissions') ??
      _mapValue(payload['user'], 'Permissions');

  developer.log('Raw permissions from backend: $rawPermissions', name: 'auth.mapper');

  if (rawPermissions is Iterable) {
    final parsed = rawPermissions
        .map((item) {
          if (item is Map) {
            return item['permissionCode']?.toString() ??
                item['PermissionCode']?.toString() ??
                item['code']?.toString() ??
                item['Code']?.toString();
          }

          return item.toString();
        })
        .whereType<String>()
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
    
    developer.log('Final parsed permissions: $parsed', name: 'auth.mapper');
    return parsed;
  }

  developer.log('No permissions found or not iterable.', name: 'auth.mapper');
  return const [];
}

Object? _mapValue(Object? value, String key) {
  if (value is Map<String, dynamic>) {
    return value[key];
  }

  if (value is Map) {
    return value[key];
  }

  return null;
}

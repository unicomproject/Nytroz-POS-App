import 'package:dio/dio.dart';

import '../models/set_password_request_dto.dart';
import '../models/setup_token_validation_dto.dart';
import '../models/tenant_admin_login_request_dto.dart';
import '../models/tenant_payment_status_dto.dart';
import '../models/tenant_payment_summary_dto.dart';

class TenantAdminAuthRemoteDatasource {
  const TenantAdminAuthRemoteDatasource(this._dio);

  final Dio _dio;

  Future<TenantPaymentSummaryDto> getPaymentSummary(String paymentToken) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/tenant-admin/onboarding/payment-summary/$paymentToken',
    );
    return TenantPaymentSummaryDto.fromJson(response.data ?? const {});
  }

  Future<TenantPaymentStatusDto> startPayment(String paymentToken) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/tenant-admin/onboarding/start-payment',
      data: {'paymentToken': paymentToken},
    );
    return TenantPaymentStatusDto.fromJson(response.data ?? const {});
  }

  Future<TenantPaymentStatusDto> verifyPaymentStatus(
      String paymentToken) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/tenant-admin/onboarding/payment-status/$paymentToken',
    );
    return TenantPaymentStatusDto.fromJson(response.data ?? const {});
  }

  Future<SetupTokenValidationDto> validateSetupToken(String setupToken) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/tenant-admin/onboarding/setup-token/$setupToken/validate',
    );
    return SetupTokenValidationDto.fromJson(response.data ?? const {});
  }

  Future<void> setPassword(SetPasswordRequestDto request) async {
    await _dio.post<void>(
      '/api/tenant-admin/onboarding/setup-password',
      data: request.toJson(),
    );
  }

  Future<Map<String, dynamic>> login(TenantAdminLoginRequestDto request) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/tenant-admin/auth/login',
      data: request.toJson(),
    );
    return response.data ?? const {};
  }
}

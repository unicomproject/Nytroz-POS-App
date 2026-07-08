import 'dart:developer' as developer;

import 'package:dio/dio.dart';

import '../../../../core/network/dio_error_message.dart';
import '../../domain/entities/auth_exception.dart';
import '../models/set_password_request_dto.dart';
import '../models/setup_token_validation_dto.dart';
import '../models/auth_branding_dto.dart';
import '../models/login_request_dto.dart';
import '../models/tenant_payment_status_dto.dart';
import '../models/tenant_payment_summary_dto.dart';

class AuthRemoteDatasource {
  const AuthRemoteDatasource(this._dio);

  final Dio _dio;

  Future<AuthBrandingDto> getAuthBranding() async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/tenant-admin/onboarding/auth-branding',
    );
    return AuthBrandingDto.fromJson(response.data ?? const {});
  }

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

  Future<Map<String, dynamic>> login(LoginRequestDto request) async {
    const endpoint = '/api/v1/tenant-auth/login';
    final stopwatch = Stopwatch()..start();

    try {
      final response = await _dio.post<Map<String, dynamic>>(
        endpoint,
        data: request.toJson(),
      );
      stopwatch.stop();
      final responseData = response.data ?? const {};
      final payload = _mapFromValue(responseData['data']);
      final user = _mapFromValue(payload['user']);
      final permissionCodes = payload['permissionCodes'];
      developer.log(
        'API success. step=tenant-login baseUrl=${_dio.options.baseUrl} endpoint=$endpoint status=${response.statusCode} durationMs=${stopwatch.elapsedMilliseconds} success=${responseData['success']} message=${responseData['message']} tenantCode=${_stringValue(user, 'tenantCode')} email=${_stringValue(user, 'email')} permissionCount=${_iterableLength(permissionCodes)}',
        name: 'auth.login',
      );
      return responseData;
    } on DioException catch (error) {
      stopwatch.stop();
      developer.log(
        'API failure. step=tenant-login baseUrl=${_dio.options.baseUrl} endpoint=$endpoint status=${error.response?.statusCode ?? 'none'} durationMs=${stopwatch.elapsedMilliseconds} errorType=${error.type.name} message=${error.message}',
        name: 'auth.login',
      );
      final data = error.response?.data;
      if (data is Map<String, dynamic>) {
        throw AuthException(
          errorCode: data['errorCode']?.toString() ?? 'LOGIN_FAILED',
          message: data['message']?.toString() ?? 'Login failed.',
        );
      }

      throw AuthException(
        errorCode: 'NETWORK_ERROR',
        message: messageFromDioException(
          error,
          contextPrefix: 'Login failed',
          fallback: 'Unable to connect to the login service.',
          attemptedBaseUrl: _dio.options.baseUrl,
        ),
      );
    }
  }

  Map<String, dynamic> _mapFromValue(Object? value) {
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }

    return const {};
  }

  String _stringValue(Map<String, dynamic> value, String key) {
    return value[key]?.toString() ?? '';
  }

  int _iterableLength(Object? value) {
    return value is Iterable ? value.length : 0;
  }
}

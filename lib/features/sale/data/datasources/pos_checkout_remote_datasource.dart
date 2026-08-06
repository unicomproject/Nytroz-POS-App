import 'dart:developer' as developer;

import 'package:dio/dio.dart';

import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/auth_unauthorized_interceptor.dart';
import '../../domain/entities/pos_checkout_api_exception.dart';
import '../../domain/entities/pos_cash_payment_observability.dart';
import '../../domain/entities/pos_checkout_summary.dart';

class PosCheckoutRemoteDatasource {
  const PosCheckoutRemoteDatasource(this._dio);

  final Dio _dio;

  Future<PosCheckoutSummaryPayload> getCheckoutSummary({
    required String deviceId,
    required List<PosCheckoutLineRequest> lines,
    String saleType = 'NewSale',
    String? customerId,
    String? discountApplicationId,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.posCheckoutSummary,
        data: _buildRequestBody(
          deviceId: deviceId,
          saleType: saleType,
          lines: lines,
          customerId: customerId,
          discountApplicationId: discountApplicationId,
        ),
      );

      final payload = PosCheckoutSummaryPayload.fromJson(
        _unwrapApiData(response.data ?? const {}),
      );

      developer.log(
        'Loaded checkout summary for ${lines.length} line(s).',
        name: 'pos.checkout',
      );

      return payload;
    } on DioException catch (error) {
      developer.log(
        'Checkout summary API failed. endpoint=${ApiEndpoints.posCheckoutSummary}, '
        'status=${error.response?.statusCode ?? 'none'}',
        name: 'pos.checkout',
      );
      throw checkoutApiExceptionFromDio(error);
    }
  }

  Future<PosCheckoutStartPaymentPayload> startPayment({
    required String deviceId,
    required String paymentMethod,
    required List<PosCheckoutLineRequest> lines,
    int? cashReceived,
    String saleType = 'NewSale',
    String? customerId,
    String? discountApplicationId,
    required String idempotencyKey,
  }) async {
    final correlation = cashPaymentCorrelation(idempotencyKey);
    final stopwatch = Stopwatch()..start();
    CashPaymentTrace.emit('pos_cash_payment_request_dispatched', {
      'correlation': correlation,
      'endpoint': ApiEndpoints.posCheckoutStartPayment,
      'timestamp': DateTime.now().toUtc().toIso8601String(),
    });
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.posCheckoutStartPayment,
        options: Options(extra: const {
          AuthUnauthorizedInterceptor.disableAutomaticRetry: true,
        }),
        data: {
          ..._buildRequestBody(
            deviceId: deviceId,
            saleType: saleType,
            lines: lines,
            customerId: customerId,
            discountApplicationId: discountApplicationId,
          ),
          'paymentMethod': paymentMethod,
          'idempotencyKey': idempotencyKey,
          if (cashReceived != null) 'cashReceived': cashReceived,
        },
      );

      final payload = PosCheckoutStartPaymentPayload.fromJson(
        _unwrapApiData(response.data ?? const {}),
      );
      CashPaymentTrace.emit('pos_cash_payment_response_received', {
        'correlation': correlation,
        'httpStatus': response.statusCode,
        'outcome': 'success',
        'elapsedMs': stopwatch.elapsedMilliseconds,
        'timestamp': DateTime.now().toUtc().toIso8601String(),
      });
      return payload;
    } on DioException catch (error) {
      final mapped = checkoutApiExceptionFromDio(error);
      CashPaymentTrace.emit('pos_cash_payment_request_failed', {
        'correlation': correlation,
        'category': error.type.name,
        'httpStatus': mapped.statusCode,
        'backendErrorCode': mapped.code,
        'message': mapped.message,
        'timeoutOrCancellation':
            error.type == DioExceptionType.connectionTimeout ||
                error.type == DioExceptionType.sendTimeout ||
                error.type == DioExceptionType.receiveTimeout ||
                error.type == DioExceptionType.cancel,
        'elapsedMs': stopwatch.elapsedMilliseconds,
        'timestamp': DateTime.now().toUtc().toIso8601String(),
      });
      developer.log(
        'Checkout start-payment API failed. endpoint=${ApiEndpoints.posCheckoutStartPayment}, '
        'status=${error.response?.statusCode ?? 'none'}',
        name: 'pos.checkout',
      );
      throw mapped;
    } on Object catch (error) {
      CashPaymentTrace.emit('pos_cash_payment_request_failed', {
        'correlation': correlation,
        'category': 'response_parsing',
        'message': 'Checkout response could not be processed.',
        'timeoutOrCancellation': false,
        'elapsedMs': stopwatch.elapsedMilliseconds,
        'timestamp': DateTime.now().toUtc().toIso8601String(),
      });
      Error.throwWithStackTrace(error, StackTrace.current);
    }
  }

  Future<void> recordReceiptPrint({
    required String saleId,
    required Map<String, dynamic> audit,
  }) async {
    try {
      await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.posReceiptPrint(saleId),
        data: audit,
      );
    } on DioException catch (error) {
      developer.log(
        'Receipt print audit API failed. endpoint=${ApiEndpoints.posReceiptPrint(saleId)}, '
        'status=${error.response?.statusCode ?? 'none'}',
        name: 'pos.checkout',
      );
      throw checkoutApiExceptionFromDio(error);
    }
  }

  Map<String, dynamic> _buildRequestBody({
    required String deviceId,
    required String saleType,
    required List<PosCheckoutLineRequest> lines,
    String? customerId,
    String? discountApplicationId,
  }) {
    return {
      'deviceId': deviceId,
      'saleType': saleType,
      'lines': lines.map((line) => line.toJson()).toList(growable: false),
      if (customerId != null && customerId.isNotEmpty) 'customerId': customerId,
      if (discountApplicationId != null && discountApplicationId.isNotEmpty)
        'discountApplicationId': discountApplicationId,
    };
  }

  Map<String, dynamic> _unwrapApiData(Map<String, dynamic> json) {
    final data = json['data'];
    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }

    return json;
  }
}

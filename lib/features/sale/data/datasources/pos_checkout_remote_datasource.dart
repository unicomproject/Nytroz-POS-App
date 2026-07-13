import 'dart:developer' as developer;

import 'package:dio/dio.dart';

import '../../../../core/network/api_endpoints.dart';
import '../../domain/entities/pos_checkout_api_exception.dart';
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
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.posCheckoutStartPayment,
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

      return PosCheckoutStartPaymentPayload.fromJson(
        _unwrapApiData(response.data ?? const {}),
      );
    } on DioException catch (error) {
      developer.log(
        'Checkout start-payment API failed. endpoint=${ApiEndpoints.posCheckoutStartPayment}, '
        'status=${error.response?.statusCode ?? 'none'}',
        name: 'pos.checkout',
      );
      throw checkoutApiExceptionFromDio(error);
    }
  }

  Future<void> recordReceiptPrint({required String saleId}) async {
    try {
      await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.posReceiptPrint(saleId),
        data: const {
          'status': 'success',
          'copies': 1,
        },
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

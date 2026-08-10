import 'package:dio/dio.dart';

import '../../../../core/network/api_endpoints.dart';
import '../../../sale/domain/entities/pos_checkout_api_exception.dart';
import '../../../sale/domain/entities/pos_checkout_summary.dart';
import '../../domain/entities/pos_discount_api_models.dart';

class PosDiscountRemoteDatasource {
  const PosDiscountRemoteDatasource(this._dio);
  final Dio _dio;

  Future<PosDiscountCatalog> getDiscounts({
    required String deviceId,
    required String scope,
    String? variantId,
    List<String> variantIds = const [],
    String? customerId,
    double? quantity,
    double? cartSubtotal,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.posDiscounts,
        queryParameters: {
          'deviceId': deviceId,
          'scope': scope,
          if (variantId != null) 'variantId': variantId,
          if (variantIds.isNotEmpty) 'variantIds': variantIds,
          if (customerId != null) 'customerId': customerId,
          if (quantity != null) 'quantity': quantity,
          if (cartSubtotal != null) 'cartSubtotal': cartSubtotal,
        },
      );
      return PosDiscountCatalog.fromJson(_data(response.data));
    } on DioException catch (error) {
      throw checkoutApiExceptionFromDio(error);
    }
  }

  Future<PosDiscountApplyResult> apply({
    required String deviceId,
    String? discountId,
    required String discountSource,
    required String scope,
    required String calculationMethod,
    required List<PosCheckoutLineRequest> lines,
    required String idempotencyKey,
    double? requestedValue,
    String? targetVariantId,
    String? reason,
    String? customerId,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.posDiscountApply,
        data: {
          'deviceId': deviceId,
          if (discountId != null) 'discountId': discountId,
          'discountSource': discountSource,
          'calculationMethod': calculationMethod,
          if (requestedValue != null) 'requestedValue': requestedValue,
          'scope': scope,
          if (targetVariantId != null) 'targetVariantId': targetVariantId,
          if (reason != null && reason.trim().isNotEmpty)
            'reason': reason.trim(),
          'saleType': 'NewSale',
          if (customerId != null && customerId.isNotEmpty)
            'customerId': customerId,
          'lines': lines.map((x) => x.toJson()).toList(growable: false),
          'idempotencyKey': idempotencyKey,
        },
      );
      return PosDiscountApplyResult.fromJson(_data(response.data));
    } on DioException catch (error) {
      throw checkoutApiExceptionFromDio(error);
    }
  }

  Future<PosDiscountValidationResult> validate({
    required String deviceId,
    required String scope,
    required String calculationMethod,
    required List<PosCheckoutLineRequest> lines,
    required double requestedValue,
    String? targetVariantId,
    String? reason,
    String? customerId,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.posDiscountValidate,
        data: {
          'deviceId': deviceId,
          'discountId': null,
          'discountSource': 'MANUAL',
          'calculationMethod': calculationMethod,
          'requestedValue': requestedValue,
          'scope': scope,
          if (targetVariantId != null) 'targetVariantId': targetVariantId,
          if (reason != null && reason.trim().isNotEmpty)
            'reason': reason.trim(),
          'saleType': 'NewSale',
          if (customerId != null && customerId.isNotEmpty)
            'customerId': customerId,
          'lines': lines.map((x) => x.toJson()).toList(growable: false),
        },
      );
      return PosDiscountValidationResult.fromJson(_data(response.data));
    } on DioException catch (error) {
      throw checkoutApiExceptionFromDio(error);
    }
  }

  Future<void> cancel({
    required String applicationId,
    required String deviceId,
    String? reason,
  }) async {
    try {
      await _dio.post<Map<String, dynamic>>(
        '${ApiEndpoints.posDiscounts}/$applicationId/cancel',
        data: {'deviceId': deviceId, if (reason != null) 'reason': reason},
      );
    } on DioException catch (error) {
      throw checkoutApiExceptionFromDio(error);
    }
  }

  Future<String> decide({
    required String applicationId,
    required String decision,
    String? note,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.posDiscountApprove(applicationId),
        data: {'decision': decision, if (note != null) 'note': note},
      );
      return _data(response.data)['status']?.toString() ?? '';
    } on DioException catch (error) {
      throw checkoutApiExceptionFromDio(error);
    }
  }

  Map<String, dynamic> _data(Map<String, dynamic>? body) {
    final data = body?['data'];
    return data is Map ? Map<String, dynamic>.from(data) : (body ?? const {});
  }
}

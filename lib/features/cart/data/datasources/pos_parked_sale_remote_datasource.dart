import 'package:dio/dio.dart';

import '../../../../core/network/api_endpoints.dart';
import '../../../sale/domain/entities/pos_checkout_api_exception.dart';
import '../models/pos_parked_sale_dtos.dart';

class PosParkedSaleRemoteDatasource {
  const PosParkedSaleRemoteDatasource(this._dio);
  final Dio _dio;

  Future<PosHoldDto> create(PosCreateHoldRequestDto request) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
          ApiEndpoints.posHolds,
          data: request.toJson());
      if (response.statusCode != 201) {
        throw PosCheckoutApiException(
            message: 'Park Sale returned an unexpected status.',
            statusCode: response.statusCode);
      }
      return PosHoldDto.fromJson(_data(response.data));
    } on DioException catch (e) {
      throw checkoutApiExceptionFromDio(e);
    }
  }

  Future<PosHoldListDto> list({
    required String deviceId,
    required String scope,
    required int page,
    required int pageSize,
  }) async {
    try {
      final response = await _dio
          .get<Map<String, dynamic>>(ApiEndpoints.posHolds, queryParameters: {
        'deviceId': deviceId,
        'scope': scope,
        'page': page,
        'pageSize': pageSize,
      });
      if (response.statusCode != 200) {
        throw PosCheckoutApiException(
            message: 'Parked Sales returned an unexpected status.',
            statusCode: response.statusCode);
      }
      return PosHoldListDto.fromJson(_data(response.data));
    } on DioException catch (e) {
      throw checkoutApiExceptionFromDio(e);
    }
  }

  Future<PosRecallHoldDto> recall(String holdId, String deviceId) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
          ApiEndpoints.posHoldRecall(holdId),
          data: {'deviceId': deviceId});
      if (response.statusCode != 200) {
        throw PosCheckoutApiException(
            message: 'Recall returned an unexpected status.',
            statusCode: response.statusCode);
      }
      return PosRecallHoldDto.fromJson(_data(response.data));
    } on DioException catch (e) {
      throw checkoutApiExceptionFromDio(e);
    }
  }

  Future<void> cancel(String holdId, {String? reason}) async {
    try {
      final response = await _dio.delete<void>(ApiEndpoints.posHold(holdId),
          queryParameters: {
            if (reason?.trim().isNotEmpty == true) 'reason': reason!.trim()
          });
      if (response.statusCode != 204) {
        throw PosCheckoutApiException(
            message: 'Cancel returned an unexpected status.',
            statusCode: response.statusCode);
      }
    } on DioException catch (e) {
      throw checkoutApiExceptionFromDio(e);
    }
  }

  Map<String, dynamic> _data(Map<String, dynamic>? envelope) {
    final data = envelope?['data'];
    if (data is Map) return Map<String, dynamic>.from(data);
    throw const FormatException('Malformed Park Sale response envelope.');
  }
}

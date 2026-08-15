import 'package:dio/dio.dart';

import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/dio_error_message.dart';

class CashDrawerRemoteDatasource {
  const CashDrawerRemoteDatasource(this._dio);
  final Dio _dio;

  Future<Map<String, dynamic>> getSummary(String deviceId) => _get(
        ApiEndpoints.posCashDrawerSummary,
        {'deviceId': deviceId},
      );

  Future<Map<String, dynamic>> getMovements(
          String deviceId, int page, int pageSize) =>
      _get(
        ApiEndpoints.posCashDrawerMovements,
        {'deviceId': deviceId, 'page': page, 'pageSize': pageSize},
      );

  Future<Map<String, dynamic>> createMovement(
      Map<String, dynamic> request) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.posCashDrawerMovements,
        data: request,
      );
      return _unwrap(response.data);
    } on DioException catch (error) {
      throw CashDrawerException(messageFromDioException(error,
          contextPrefix: 'Cash drawer request failed', fallback: 'Try again.'));
    }
  }

  Future<Map<String, dynamic>> _get(
      String path, Map<String, dynamic> query) async {
    try {
      final response =
          await _dio.get<Map<String, dynamic>>(path, queryParameters: query);
      return _unwrap(response.data);
    } on DioException catch (error) {
      throw CashDrawerException(messageFromDioException(error,
          contextPrefix: 'Cash drawer request failed', fallback: 'Try again.'));
    }
  }

  Map<String, dynamic> _unwrap(Map<String, dynamic>? json) {
    final value = json?['data'];
    return value is Map
        ? Map<String, dynamic>.from(value)
        : Map<String, dynamic>.from(json ?? const {});
  }
}

class CashDrawerException implements Exception {
  const CashDrawerException(this.message);
  final String message;
}

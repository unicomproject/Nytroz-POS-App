import 'package:dio/dio.dart';

import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/dio_error_message.dart';

class CashDrawerRemoteDatasource {
  const CashDrawerRemoteDatasource(this._dio);
  final Dio _dio;

  Future<Map<String, dynamic>> getSummary(String deviceId) => _getMap(
        ApiEndpoints.posCashDrawerSummary,
        {'deviceId': deviceId},
      );

  Future<Map<String, dynamic>> getMovements(
          String deviceId, int page, int pageSize) =>
      _getMap(
        ApiEndpoints.posCashDrawerMovements,
        {'deviceId': deviceId, 'page': page, 'pageSize': pageSize},
      );

  Future<List<Map<String, dynamic>>> getMovementTypes({
    String direction = 'IN',
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.posCashMovementTypes,
        queryParameters: {'direction': direction},
      );
      return _unwrapList(response.data);
    } on DioException catch (error) {
      throw _mapError(error, fallback: 'Cash movement types could not be loaded.');
    }
  }

  Future<Map<String, dynamic>> createCashInMovement(
      Map<String, dynamic> request) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.posCashDrawerMovements,
        data: request,
      );
      return _unwrapMap(response.data);
    } on DioException catch (error) {
      throw _mapError(error, fallback: 'Cash in could not be recorded.');
    }
  }

  Future<Map<String, dynamic>> createCashDropMovement(
      Map<String, dynamic> request) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.posCashDrawerMovements,
        data: request,
      );
      return _unwrapMap(response.data);
    } on DioException catch (error) {
      throw _mapError(error, fallback: 'Cash drop could not be recorded.');
    }
  }

  /// Legacy mutation used by Cash Out until its Chunk is wired.
  Future<Map<String, dynamic>> createMovement(
      Map<String, dynamic> request) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.posCashDrawerMovements,
        data: request,
      );
      return _unwrapMap(response.data);
    } on DioException catch (error) {
      throw _mapError(error, fallback: 'Cash drawer request failed.');
    }
  }

  Future<Map<String, dynamic>> _getMap(
      String path, Map<String, dynamic> query) async {
    try {
      final response =
          await _dio.get<Map<String, dynamic>>(path, queryParameters: query);
      return _unwrapMap(response.data);
    } on DioException catch (error) {
      throw _mapError(error, fallback: 'Cash drawer request failed.');
    }
  }

  Map<String, dynamic> _unwrapMap(Map<String, dynamic>? json) {
    final value = json?['data'];
    return value is Map
        ? Map<String, dynamic>.from(value)
        : Map<String, dynamic>.from(json ?? const {});
  }

  List<Map<String, dynamic>> _unwrapList(Map<String, dynamic>? json) {
    final value = json?['data'];
    if (value is List) {
      return value
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    }
    return const [];
  }

  CashDrawerException _mapError(DioException error, {required String fallback}) {
    final data = error.response?.data;
    String? code;
    if (data is Map) {
      final rawCode = data['code'];
      if (rawCode is String && rawCode.trim().isNotEmpty) {
        code = rawCode.trim();
      }
    }
    final message = messageFromDioException(
      error,
      contextPrefix: 'Cash drawer request failed',
      fallback: fallback,
    );
    return CashDrawerException(message, code: code);
  }
}

class CashDrawerException implements Exception {
  const CashDrawerException(this.message, {this.code});
  final String message;
  final String? code;

  @override
  String toString() => message;
}

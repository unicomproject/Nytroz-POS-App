import 'package:dio/dio.dart';

import '../../../../core/network/api_endpoints.dart';
import '../models/pos_hardware_models.dart';

class PosHardwareRemoteDatasource {
  const PosHardwareRemoteDatasource(this._dio);

  final Dio _dio;

  Future<List<PosHardwareConfiguration>> getConfigurations(
      String posDeviceId) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.posHardwareConfigurations,
        queryParameters: {'posDeviceId': posDeviceId},
      );
      final data = response.data?['data'];
      return data is List
          ? data
              .whereType<Map>()
              .map((item) => PosHardwareConfiguration.fromJson(
                    Map<String, dynamic>.from(item),
                  ))
              .toList(growable: false)
          : const [];
    } on DioException catch (error) {
      throw _map(error);
    }
  }

  Future<PosHardwareConfiguration> saveConfiguration(
      Map<String, dynamic> request) async {
    try {
      final response = await _dio.put<Map<String, dynamic>>(
        ApiEndpoints.posHardwareConfigurations,
        data: request,
      );
      return PosHardwareConfiguration.fromJson(
        Map<String, dynamic>.from(response.data?['data'] as Map),
      );
    } on DioException catch (error) {
      throw _map(error);
    }
  }

  Future<HardwareTestOperation> createTest(Map<String, dynamic> request) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.posHardwareTests,
        data: request,
      );
      return HardwareTestOperation.fromJson(
        Map<String, dynamic>.from(response.data?['data'] as Map),
      );
    } on DioException catch (error) {
      throw _map(error);
    }
  }

  Future<HardwareTestOperation> submitResult(
    String testId,
    Map<String, dynamic> request,
  ) async {
    try {
      final response = await _dio.put<Map<String, dynamic>>(
        ApiEndpoints.posHardwareTestResult(testId),
        data: request,
      );
      return HardwareTestOperation.fromJson(
        Map<String, dynamic>.from(response.data?['data'] as Map),
      );
    } on DioException catch (error) {
      throw _map(error);
    }
  }

  Future<List<HardwareTestOperation>> getHistory(
    String posDeviceId, {
    int take = 25,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.posHardwareTests,
        queryParameters: {'posDeviceId': posDeviceId, 'take': take},
      );
      final data = response.data?['data'];
      return data is List
          ? data
              .whereType<Map>()
              .map((item) => HardwareTestOperation.fromJson(
                    Map<String, dynamic>.from(item),
                  ))
              .toList(growable: false)
          : const [];
    } on DioException catch (error) {
      throw _map(error);
    }
  }

  PosHardwareApiException _map(DioException error) {
    final body = error.response?.data;
    final map = body is Map ? Map<String, dynamic>.from(body) : const {};
    final code = map['code']?.toString() ?? 'pos_hardware.backend_unavailable';
    final message = map['message']?.toString() ??
        'Hardware service is unavailable. Try again.';
    return PosHardwareApiException(code, message);
  }
}

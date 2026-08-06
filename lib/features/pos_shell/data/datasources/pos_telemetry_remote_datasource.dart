import 'package:dio/dio.dart';

class PosTelemetryRemoteDataSource {
  PosTelemetryRemoteDataSource(this._dio);

  final Dio _dio;

  Future<void> sendHardwareHeartbeat(
      String posDeviceId, Map<String, dynamic> payload) async {
    await _dio.post(
      '/api/v1/pos/devices/$posDeviceId/hardware-heartbeat',
      data: payload,
    );
  }
}

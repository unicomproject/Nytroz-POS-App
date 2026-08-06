import 'package:dio/dio.dart';
import '../models/hardware_device_dto.dart';
import '../models/hardware_device_list_item_dto.dart';

abstract class HardwareRemoteDataSource {
  Future<List<HardwareDeviceListItemDto>> getHardwareDevices({
    required int page,
    required int pageSize,
    String? outletId,
  });

  Future<HardwareDeviceDto> getHardwareDevice(String hardwareDeviceId);

  Future<HardwareDeviceDto> createHardwareDevice(Map<String, dynamic> request);

  Future<void> assignHardwareToTill(
    String tillId,
    Map<String, dynamic> request,
  );

  Future<void> assignHardwareToPosDevice(
    String posDeviceId,
    Map<String, dynamic> request,
  );

  Future<void> releaseHardwareAssignment(
    String assignmentId,
    Map<String, dynamic> request,
  );
}

class HardwareRemoteDataSourceImpl implements HardwareRemoteDataSource {
  const HardwareRemoteDataSourceImpl(this._dio);

  final Dio _dio;

  @override
  Future<List<HardwareDeviceListItemDto>> getHardwareDevices({
    required int page,
    required int pageSize,
    String? outletId,
  }) async {
    final queryParameters = <String, dynamic>{
      'page': page,
      'pageSize': pageSize,
    };
    if (outletId != null && outletId.isNotEmpty) {
      queryParameters['outletId'] = outletId;
    }

    final response = await _dio.get(
      '/api/v1/tenant/hardware',
      queryParameters: queryParameters,
    );

    final data = response.data['data'] as Map<String, dynamic>;
    final items = data['items'] as List<dynamic>;

    return items
        .map((e) =>
            HardwareDeviceListItemDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<HardwareDeviceDto> getHardwareDevice(String hardwareDeviceId) async {
    final response =
        await _dio.get('/api/v1/tenant/hardware/$hardwareDeviceId');
    final data = response.data['data'] as Map<String, dynamic>;
    return HardwareDeviceDto.fromJson(data);
  }

  @override
  Future<HardwareDeviceDto> createHardwareDevice(
      Map<String, dynamic> request) async {
    final response = await _dio.post(
      '/api/v1/tenant/hardware',
      data: request,
    );
    final data = response.data['data'] as Map<String, dynamic>;
    return HardwareDeviceDto.fromJson(data);
  }

  @override
  Future<void> assignHardwareToTill(
    String tillId,
    Map<String, dynamic> request,
  ) async {
    await _dio.post(
      '/api/v1/tenant/tills/$tillId/hardware-assignments',
      data: request,
    );
  }

  @override
  Future<void> assignHardwareToPosDevice(
    String posDeviceId,
    Map<String, dynamic> request,
  ) async {
    await _dio.post(
      '/api/v1/tenant/pos-devices/$posDeviceId/hardware-assignments',
      data: request,
    );
  }

  @override
  Future<void> releaseHardwareAssignment(
    String assignmentId,
    Map<String, dynamic> request,
  ) async {
    await _dio.post(
      '/api/v1/tenant/hardware-assignments/$assignmentId/release',
      data: request,
    );
  }
}

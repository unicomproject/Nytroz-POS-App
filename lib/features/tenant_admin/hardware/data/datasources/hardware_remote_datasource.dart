import 'package:dio/dio.dart';
import 'dart:convert';
import 'dart:math';
import '../models/hardware_device_dto.dart';
import '../models/hardware_device_list_item_dto.dart';
import '../models/hardware_compatibility_profile.dart';

abstract class HardwareRemoteDataSource {
  Future<void> updateHardwareDevice(String id, Map<String, dynamic> request);
  Future<List<HardwareCompatibilityProfile>> getCompatibilityProfiles();
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
  HardwareRemoteDataSourceImpl(this._dio);

  final Dio _dio;
  final Map<String, String> _pending = {};

  Future<Response<dynamic>> _mutate(String path, Map<String, dynamic> request,
      {String method = 'POST'}) async {
    final identity = '$method:$path:${jsonEncode(request)}';
    final key = _pending.putIfAbsent(
        identity,
        () => List.generate(
            24,
            (_) => Random.secure()
                .nextInt(256)
                .toRadixString(16)
                .padLeft(2, '0')).join());
    final response = await _dio.request(path,
        data: request,
        options: Options(method: method, headers: {'Idempotency-Key': key}));
    _pending.remove(identity);
    return response;
  }

  @override
  Future<void> updateHardwareDevice(
      String id, Map<String, dynamic> request) async {
    await _mutate('/api/v1/tenant-admin/hardware-devices/$id', request,
        method: 'PUT');
  }

  @override
  Future<List<HardwareCompatibilityProfile>> getCompatibilityProfiles() async {
    final response =
        await _dio.get('/api/v1/tenant-admin/hardware-devices/create-options');
    final data = response.data['data'] as Map<String, dynamic>;
    return (data['compatibilityProfiles'] as List<dynamic>)
        .map((entry) => HardwareCompatibilityProfile.fromJson(
            entry as Map<String, dynamic>))
        .toList();
  }

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
      '/api/v1/tenant-admin/hardware-devices',
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
    final response = await _dio
        .get('/api/v1/tenant-admin/hardware-devices/$hardwareDeviceId');
    final data = response.data['data'] as Map<String, dynamic>;
    return HardwareDeviceDto.fromJson(data);
  }

  @override
  Future<HardwareDeviceDto> createHardwareDevice(
      Map<String, dynamic> request) async {
    final response = await _mutate(
      '/api/v1/tenant-admin/hardware-devices',
      request,
    );
    final data = response.data['data'] as Map<String, dynamic>;
    return HardwareDeviceDto.fromJson(data);
  }

  @override
  Future<void> assignHardwareToTill(
    String tillId,
    Map<String, dynamic> request,
  ) async {
    await _mutate(
      '/api/v1/tenant-admin/tills/$tillId/hardware-assignments',
      request,
    );
  }

  @override
  Future<void> assignHardwareToPosDevice(
    String posDeviceId,
    Map<String, dynamic> request,
  ) async {
    await _mutate(
      '/api/v1/tenant-admin/pos-devices/$posDeviceId/hardware-assignments',
      request,
    );
  }

  @override
  Future<void> releaseHardwareAssignment(
    String assignmentId,
    Map<String, dynamic> request,
  ) async {
    await _mutate(
      '/api/v1/tenant-admin/hardware-assignments/$assignmentId/release',
      request,
    );
  }
}

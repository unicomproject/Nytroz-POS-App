import 'dart:developer' as developer;

import 'package:dio/dio.dart';

import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/dio_error_message.dart';
import '../../domain/entities/pos_device_context.dart';

class DeviceActivationRemoteDatasource {
  const DeviceActivationRemoteDatasource(this._dio);

  final Dio _dio;

  Future<PosDeviceContext?> getCurrentDevice(DeviceActivationForm form) async {
    final stopwatch = Stopwatch()..start();

    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.currentDevice,
        queryParameters: {
          'deviceFingerprint': form.deviceFingerprint,
        },
      );
      stopwatch.stop();
      developer.log(
        'API success. step=current-device endpoint=${ApiEndpoints.currentDevice} status=${response.statusCode} durationMs=${stopwatch.elapsedMilliseconds} authAttached=${_hasAuthHeader()}',
        name: 'pos.session',
      );

      final data = _unwrapApiData(response.data ?? const {});
      return _deviceContextFromJson(data, form);
    } on DioException catch (error) {
      stopwatch.stop();
      developer.log(
        'API failure. step=current-device endpoint=${ApiEndpoints.currentDevice} status=${error.response?.statusCode ?? 'none'} durationMs=${stopwatch.elapsedMilliseconds} authAttached=${_hasAuthHeader()} message=${_messageFromDio(error)}',
        name: 'pos.session',
      );
      if (error.response?.statusCode == 404) {
        return null;
      }

      throw DeviceActivationException(_messageFromDio(error));
    }
  }

  Future<PosDeviceContext> activateDevice(DeviceActivationForm form) async {
    final stopwatch = Stopwatch()..start();

    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.activateDevice,
        data: {
          'activationCode': form.activationCode,
          'deviceFingerprint': form.deviceFingerprint,
          'deviceName': form.deviceName,
          'deviceType': form.deviceType,
          'platform': form.platform,
          'appVersion': form.appVersion,
        },
      );
      stopwatch.stop();
      developer.log(
        'API success. step=activate-device endpoint=${ApiEndpoints.activateDevice} status=${response.statusCode} durationMs=${stopwatch.elapsedMilliseconds} authAttached=${_hasAuthHeader()}',
        name: 'pos.session',
      );

      final data = _unwrapApiData(response.data ?? const {});
      return _deviceContextFromJson(data, form);
    } on DioException catch (error) {
      stopwatch.stop();
      developer.log(
        'API failure. step=activate-device endpoint=${ApiEndpoints.activateDevice} status=${error.response?.statusCode ?? 'none'} durationMs=${stopwatch.elapsedMilliseconds} authAttached=${_hasAuthHeader()} message=${_messageFromDio(error)}',
        name: 'pos.session',
      );
      throw DeviceActivationException(_messageFromDio(error));
    }
  }

  Map<String, dynamic> _unwrapApiData(Map<String, dynamic> json) {
    final data = json['data'];
    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }

    return json;
  }

  PosDeviceContext _deviceContextFromJson(
    Map<String, dynamic> json,
    DeviceActivationForm form,
  ) {
    final device = _map(json['device']);
    final outlet = _map(json['outlet']);
    final till = _map(json['till']);

    return PosDeviceContext(
      deviceId: _string(device['id']),
      deviceCode: _string(device['deviceCode']),
      deviceName: _string(device['deviceName'], fallback: form.deviceName),
      deviceType: _string(device['deviceType'], fallback: form.deviceType),
      platform: _string(device['platform'], fallback: form.platform),
      deviceFingerprint: form.deviceFingerprint,
      isTrusted: _bool(device['isTrusted']),
      tenantId: _string(json['tenantId']),
      outletId: _string(device['outletId'], fallback: _string(outlet['id'])),
      outletName: _string(outlet['name']),
      tillId: _string(device['tillId'], fallback: _string(till['id'])),
      tillCode: _string(till['code']),
      tillName: _string(till['name']),
      pairedAt: DateTime.now(),
    );
  }

  Map<String, dynamic> _map(Object? value) {
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }

    return const {};
  }

  String _string(Object? value, {String fallback = ''}) {
    final text = value?.toString();
    if (text == null || text.trim().isEmpty) {
      return fallback;
    }

    return text;
  }

  bool _bool(Object? value) {
    if (value is bool) {
      return value;
    }

    final text = value?.toString().trim().toLowerCase();
    return text == 'true' || text == '1';
  }

  String _messageFromDio(DioException error) {
    return messageFromDioException(
      error,
      contextPrefix: 'Device activation failed at ${error.requestOptions.path}',
      fallback: 'Try again.',
    );
  }

  bool _hasAuthHeader() {
    final value = _dio.options.headers['Authorization'];
    return value is String && value.trim().isNotEmpty;
  }
}

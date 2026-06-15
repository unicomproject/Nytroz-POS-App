import 'package:dio/dio.dart';

import '../../../../core/network/api_endpoints.dart';
import '../../domain/entities/pos_device_context.dart';

class DeviceActivationRemoteDatasource {
  const DeviceActivationRemoteDatasource(this._dio);

  final Dio _dio;

  Future<PosDeviceContext> activateDevice(DeviceActivationForm form) async {
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

      final data = _unwrapApiData(response.data ?? const {});
      return _deviceContextFromJson(data, form);
    } on DioException catch (error) {
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
      isTrusted: device['isTrusted'] == true,
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

  String _messageFromDio(DioException error) {
    final data = error.response?.data;
    if (data is Map) {
      final message = data['message'];
      if (message is String && message.trim().isNotEmpty) {
        return message;
      }
    }

    return 'Device activation failed. Try again.';
  }
}

import 'dart:developer' as developer;

import 'package:dio/dio.dart';

import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/dio_error_message.dart';
import '../../domain/entities/open_till.dart';

class TillRemoteDatasource {
  const TillRemoteDatasource(this._dio);

  final Dio _dio;

  Future<TillSession?> getCurrentSession(OpenTillForm form) async {
    final stopwatch = Stopwatch()..start();

    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.currentTillSession,
        queryParameters: {
          'deviceId': form.deviceContext.deviceId,
        },
      );
      stopwatch.stop();
      developer.log(
        'API success. step=current-till-session endpoint=${ApiEndpoints.currentTillSession} status=${response.statusCode} durationMs=${stopwatch.elapsedMilliseconds} authAttached=${_hasAuthHeader()}',
        name: 'pos.session',
      );

      final data = _unwrapApiData(response.data ?? const {});
      return _sessionFromJson(data, form);
    } on DioException catch (error) {
      stopwatch.stop();
      developer.log(
        'API failure. step=current-till-session endpoint=${ApiEndpoints.currentTillSession} status=${error.response?.statusCode ?? 'none'} durationMs=${stopwatch.elapsedMilliseconds} authAttached=${_hasAuthHeader()} message=${_messageFromDio(error)}',
        name: 'pos.session',
      );
      if (error.response?.statusCode == 404) {
        return null;
      }

      throw TillException(_messageFromDio(error));
    }
  }

  Future<TillSession> openTill(OpenTillForm form) async {
    final stopwatch = Stopwatch()..start();

    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.openTill,
        data: {
          'deviceId': form.deviceContext.deviceId,
          'tillId': form.deviceContext.tillId,
          'openingFloat': form.openingFloat,
          'openingNote':
              form.openingNote.trim().isEmpty ? null : form.openingNote.trim(),
        },
      );
      stopwatch.stop();
      developer.log(
        'API success. step=open-till endpoint=${ApiEndpoints.openTill} status=${response.statusCode} durationMs=${stopwatch.elapsedMilliseconds} authAttached=${_hasAuthHeader()}',
        name: 'pos.session',
      );

      final data = _unwrapApiData(response.data ?? const {});
      return _sessionFromJson(data, form);
    } on DioException catch (error) {
      stopwatch.stop();
      developer.log(
        'API failure. step=open-till endpoint=${ApiEndpoints.openTill} status=${error.response?.statusCode ?? 'none'} durationMs=${stopwatch.elapsedMilliseconds} authAttached=${_hasAuthHeader()} message=${_messageFromDio(error)}',
        name: 'pos.session',
      );
      throw TillException(_messageFromDio(error));
    }
  }

  Map<String, dynamic> _unwrapApiData(Map<String, dynamic> json) {
    final data = json['data'];
    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }

    return json;
  }

  TillSession _sessionFromJson(
    Map<String, dynamic> json,
    OpenTillForm form,
  ) {
    final session = _map(json['tillSession']);
    final device = form.deviceContext;

    return TillSession(
      sessionId: _string(session['id']),
      tenantId: device.tenantId,
      outletId: _string(session['outletId'], fallback: device.outletId),
      outletName: device.outletName,
      tillId: _string(session['tillId'], fallback: device.tillId),
      tillCode: device.tillCode,
      tillName: device.tillName,
      openedDeviceId: _string(
        session['openedDeviceId'],
        fallback: device.deviceId,
      ),
      openingFloat: _double(session['openingFloat'], form.openingFloat),
      status: _string(session['status'], fallback: 'open'),
      openedAt:
          DateTime.tryParse(_string(session['openedAt'])) ?? DateTime.now(),
      openingNote: session['openingNote']?.toString(),
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

  double _double(Object? value, double fallback) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value?.toString() ?? '') ?? fallback;
  }

  String _messageFromDio(DioException error) {
    return messageFromDioException(
      error,
      contextPrefix: 'Till request failed at ${error.requestOptions.path}',
      fallback: 'Try again.',
    );
  }

  bool _hasAuthHeader() {
    final value = _dio.options.headers['Authorization'];
    return value is String && value.trim().isNotEmpty;
  }
}

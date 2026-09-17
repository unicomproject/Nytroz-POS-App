import 'dart:developer' as developer;

import 'package:dio/dio.dart';

import '../../../../../core/network/api_endpoints.dart';
import '../../../domain/entities/open_till.dart';

import '../../mappers/till_session_mapper.dart';
import '../../utils/till_api_error_mapper.dart';

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

      return tillSessionFromJson(response.data ?? const {}, form);
    } on DioException catch (error) {
      stopwatch.stop();
      developer.log(
        'API failure. step=current-till-session endpoint=${ApiEndpoints.currentTillSession} status=${error.response?.statusCode ?? 'none'} durationMs=${stopwatch.elapsedMilliseconds} authAttached=${_hasAuthHeader()} message=${tillErrorMessage(error)}',
        name: 'pos.session',
      );
      final code = tillErrorCode(error);
      if (error.response?.statusCode == 404 &&
          code == 'till_session.not_found') {
        return null;
      }

      throw mapTillDioException(error);
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

      return tillSessionFromJson(response.data ?? const {}, form);
    } on DioException catch (error) {
      stopwatch.stop();
      developer.log(
        'API failure. step=open-till endpoint=${ApiEndpoints.openTill} status=${error.response?.statusCode ?? 'none'} durationMs=${stopwatch.elapsedMilliseconds} authAttached=${_hasAuthHeader()} message=${tillErrorMessage(error)}',
        name: 'pos.session',
      );
      throw mapTillDioException(error);
    }
  }

  Future<ClosedTillSession> closeTill(CloseTillForm form) async {
    final stopwatch = Stopwatch()..start();

    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.closeTill,
        data: {
          'deviceId': form.deviceContext.deviceId,
          'tillId': form.deviceContext.tillId,
          'countedCash': form.countedCash,
          'mismatchReason': form.mismatchReason?.trim().isEmpty == true
              ? null
              : form.mismatchReason?.trim(),
          'closingNote': form.closingNote?.trim().isEmpty == true
              ? null
              : form.closingNote?.trim(),
        },
      );
      stopwatch.stop();
      developer.log(
        'API success. step=close-till endpoint=${ApiEndpoints.closeTill} status=${response.statusCode} durationMs=${stopwatch.elapsedMilliseconds} authAttached=${_hasAuthHeader()}',
        name: 'pos.session',
      );

      return closedTillSessionFromJson(response.data ?? const {});
    } on DioException catch (error) {
      stopwatch.stop();
      developer.log(
        'API failure. step=close-till endpoint=${ApiEndpoints.closeTill} status=${error.response?.statusCode ?? 'none'} durationMs=${stopwatch.elapsedMilliseconds} authAttached=${_hasAuthHeader()} message=${tillErrorMessage(error)}',
        name: 'pos.session',
      );
      throw mapTillDioException(error, includeCode: false);
    }
  }

  bool _hasAuthHeader() {
    final value = _dio.options.headers['Authorization'];
    return value is String && value.trim().isNotEmpty;
  }
}

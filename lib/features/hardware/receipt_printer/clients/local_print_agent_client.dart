import 'dart:async';
import 'dart:developer' as developer;

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../config/local_print_agent_config.dart';
import '../models/local_print_agent_models.dart';
import '../models/pos_device_printer_config.dart';

class LocalPrintAgentClient {
  LocalPrintAgentClient({Dio? dio}) : _dio = dio ?? Dio();

  final Dio _dio;

  Future<LocalPrintAgentHealth> health(
    PosDevicePrinterConfig config,
  ) async {
    _validate(config);
    final endpoint =
        '${normalizeLocalPrintAgentUrl(config.agentBaseUrl!)}/api/print/health';
    _debugHealth('request endpoint=$endpoint '
        'selectedPrinter=${config.agentPrinterName ?? ''}');
    try {
      final response = await _dio
          .get<Object?>(
            endpoint,
            options: Options(
              responseType: ResponseType.json,
              headers: {'X-Local-Print-Key': config.localApiKey},
              validateStatus: (status) =>
                  status != null && status >= 200 && status < 600,
            ),
            queryParameters: const {},
            cancelToken: null,
          )
          .timeout(Duration(milliseconds: config.connectionTimeoutMs));
      final body = _map(response.data);
      _debugHealth(
        'response status=${response.statusCode} fields=${body.keys.toList()..sort()}',
      );
      if (response.statusCode == 401 || response.statusCode == 429) {
        throw const LocalPrintAgentException(
          LocalPrintAgentFailureType.authentication,
          'Authentication failed. Check the saved local API key.',
          code: 'unauthorized',
        );
      }
      if (response.statusCode != 200) {
        throw const LocalPrintAgentException(
          LocalPrintAgentFailureType.invalidResponse,
          'The print agent returned an unexpected health response.',
        );
      }
      final health = LocalPrintAgentHealth.fromJson(body);
      _debugHealth(
        'parsed printerName=${health.printerName} '
        'printerExists=${health.printerExists} '
        'printerReady=${health.printerReady}',
      );
      if ((health.apiVersion != null &&
              health.apiVersion !=
                  LocalPrintAgentReceiptRequest.supportedApiVersion) ||
          (health.receiptContractVersion != null &&
              health.receiptContractVersion !=
                  LocalPrintAgentReceiptRequest
                      .supportedReceiptContractVersion)) {
        throw const LocalPrintAgentException(
          LocalPrintAgentFailureType.updateRequired,
          'The Windows Print Agent version is incompatible. Update the agent before printing.',
          code: 'unsupported_contract_version',
        );
      }
      return health;
    } on LocalPrintAgentException {
      rethrow;
    } on DioException catch (error) {
      throw _mapDioFailure(error, isPrint: false);
    } on TimeoutException {
      throw const LocalPrintAgentException(
        LocalPrintAgentFailureType.timeout,
        'The print agent did not respond before the timeout.',
      );
    } catch (_) {
      throw const LocalPrintAgentException(
        LocalPrintAgentFailureType.invalidResponse,
        'The print agent returned an invalid health response.',
      );
    }
  }

  void _debugHealth(String message) {
    if (kDebugMode) {
      developer.log(message, name: 'LocalPrintAgentHealth');
    }
  }

  Future<LocalPrintAgentPrintResult> printReceipt(
    PosDevicePrinterConfig config,
    LocalPrintAgentReceiptRequest request,
  ) async {
    _validate(config);
    try {
      final response = await _dio
          .post<Object?>(
            '${normalizeLocalPrintAgentUrl(config.agentBaseUrl!)}/api/print/receipt',
            data: request.toJson(),
            options: Options(
              responseType: ResponseType.json,
              headers: {'X-Local-Print-Key': config.localApiKey},
              validateStatus: (status) =>
                  status != null && status >= 200 && status < 600,
            ),
          )
          .timeout(Duration(milliseconds: config.connectionTimeoutMs));
      final body = _map(response.data);
      if (response.statusCode == 401) {
        throw const LocalPrintAgentException(
          LocalPrintAgentFailureType.authentication,
          'Authentication failed. Check the saved local API key.',
          code: 'unauthorized',
        );
      }
      if (response.statusCode == 429) {
        throw const LocalPrintAgentException(
          LocalPrintAgentFailureType.authentication,
          'Print Agent authentication is temporarily rate limited.',
          code: 'authentication_rate_limited',
        );
      }
      final result = LocalPrintAgentPrintResult.fromJson(body);
      if (response.statusCode == 409 || result.duplicate) {
        throw LocalPrintAgentException(
          LocalPrintAgentFailureType.duplicate,
          result.message.isEmpty
              ? 'This print request was already accepted.'
              : result.message,
          code: result.code,
        );
      }
      if (response.statusCode == 400) {
        if (body['code'] == 'unsupported_contract_version') {
          throw LocalPrintAgentException(
            LocalPrintAgentFailureType.updateRequired,
            body['message']?.toString() ??
                'The Windows Print Agent must be updated.',
            code: 'unsupported_contract_version',
          );
        }
        throw LocalPrintAgentException(
          LocalPrintAgentFailureType.invalidRequest,
          body['message']?.toString() ?? 'The print request is invalid.',
          code: body['code']?.toString(),
        );
      }
      if (response.statusCode == 503 || !result.success) {
        final unknown = result.code == 'spooler_timeout' ||
            result.code == 'partial_or_unknown_output';
        throw LocalPrintAgentException(
          result.code == 'spooler_timeout'
              ? LocalPrintAgentFailureType.timeout
              : unknown
                  ? LocalPrintAgentFailureType.unknown
                  : LocalPrintAgentFailureType.printerUnavailable,
          result.message.isEmpty
              ? 'The configured printer is unavailable.'
              : result.message,
          code: result.code,
        );
      }
      return result;
    } on LocalPrintAgentException {
      rethrow;
    } on DioException catch (error) {
      throw _mapDioFailure(error, isPrint: true);
    } on TimeoutException {
      throw const LocalPrintAgentException(
        LocalPrintAgentFailureType.timeout,
        'The print request timed out. Check the agent before printing again.',
      );
    } catch (_) {
      throw const LocalPrintAgentException(
        LocalPrintAgentFailureType.invalidResponse,
        'The print agent returned an invalid print response.',
      );
    }
  }

  Future<LocalPrintAgentDrawerOpenResult> openDrawer(
    PosDevicePrinterConfig config,
    LocalPrintAgentDrawerOpenRequest request,
  ) async {
    _validate(config);
    try {
      final response = await _dio
          .post<Object?>(
            '${normalizeLocalPrintAgentUrl(config.agentBaseUrl!)}/api/drawer/open',
            data: request.toJson(),
            options: Options(
              responseType: ResponseType.json,
              headers: {'X-Local-Print-Key': config.localApiKey},
              validateStatus: (status) =>
                  status != null && status >= 200 && status < 600,
            ),
          )
          .timeout(Duration(milliseconds: config.connectionTimeoutMs));
      final body = _map(response.data);
      if (response.statusCode == 401 || response.statusCode == 429) {
        throw const LocalPrintAgentException(
          LocalPrintAgentFailureType.authentication,
          'Cash drawer authorization failed. Check the saved Local Agent key.',
          code: 'unauthorized',
        );
      }
      final result = LocalPrintAgentDrawerOpenResult.fromJson(body);
      if (response.statusCode == 409 || result.duplicate) {
        throw LocalPrintAgentException(
          LocalPrintAgentFailureType.duplicate,
          result.message.isEmpty
              ? 'This drawer operation was already accepted.'
              : result.message,
          code: result.code,
        );
      }
      if (response.statusCode == 400) {
        throw LocalPrintAgentException(
          LocalPrintAgentFailureType.invalidRequest,
          body['message']?.toString() ?? 'The drawer request is invalid.',
          code: body['code']?.toString(),
        );
      }
      if (response.statusCode == 503 || !result.success) {
        throw LocalPrintAgentException(
          result.code == 'spooler_timeout'
              ? LocalPrintAgentFailureType.unknown
              : LocalPrintAgentFailureType.printerUnavailable,
          result.message.isEmpty
              ? 'The drawer operation could not be submitted.'
              : result.message,
          code: result.code,
        );
      }
      return result;
    } on LocalPrintAgentException {
      rethrow;
    } on DioException catch (error) {
      if (error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.receiveTimeout ||
          error.type == DioExceptionType.sendTimeout) {
        throw const LocalPrintAgentException(
          LocalPrintAgentFailureType.unknown,
          'Drawer outcome is unknown. Check the drawer physically; do not retry automatically.',
          code: 'spooler_timeout',
        );
      }
      throw _mapDioFailure(error, isPrint: true);
    } on TimeoutException {
      throw const LocalPrintAgentException(
        LocalPrintAgentFailureType.unknown,
        'Drawer outcome is unknown. Check the drawer physically; do not retry automatically.',
        code: 'spooler_timeout',
      );
    } catch (_) {
      throw const LocalPrintAgentException(
        LocalPrintAgentFailureType.invalidResponse,
        'The print agent returned an invalid drawer response.',
      );
    }
  }

  Future<LocalPrintAgentOperationStatus?> operationStatus(
    PosDevicePrinterConfig config,
    String requestId,
  ) async {
    _validate(config);
    try {
      final response = await _dio
          .get<Object?>(
            '${normalizeLocalPrintAgentUrl(config.agentBaseUrl!)}/api/print/operations/$requestId',
            options: Options(
              responseType: ResponseType.json,
              headers: {'X-Local-Print-Key': config.localApiKey},
              validateStatus: (status) =>
                  status != null && status >= 200 && status < 600,
            ),
          )
          .timeout(Duration(milliseconds: config.connectionTimeoutMs));
      if (response.statusCode == 404) return null;
      if (response.statusCode == 401) {
        throw const LocalPrintAgentException(
          LocalPrintAgentFailureType.authentication,
          'Authentication failed. Check the saved local API key.',
          code: 'unauthorized',
        );
      }
      if (response.statusCode != 200) {
        throw const LocalPrintAgentException(
          LocalPrintAgentFailureType.invalidResponse,
          'The print agent could not resolve this operation.',
        );
      }
      return LocalPrintAgentOperationStatus.fromJson(_map(response.data));
    } on LocalPrintAgentException {
      rethrow;
    } on DioException catch (error) {
      throw _mapDioFailure(error, isPrint: false);
    } on TimeoutException {
      throw const LocalPrintAgentException(
        LocalPrintAgentFailureType.timeout,
        'The print agent operation lookup timed out.',
      );
    } catch (_) {
      throw const LocalPrintAgentException(
        LocalPrintAgentFailureType.invalidResponse,
        'The print agent returned an invalid operation response.',
      );
    }
  }

  void _validate(PosDevicePrinterConfig config) {
    final errors = validateLocalPrintAgentConfig(config);
    if (errors.isNotEmpty) {
      throw LocalPrintAgentException(
        LocalPrintAgentFailureType.invalidConfiguration,
        errors.first,
      );
    }
  }

  Map<String, dynamic> _map(Object? data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) {
      return data.map((key, value) => MapEntry(key.toString(), value));
    }
    throw const LocalPrintAgentException(
      LocalPrintAgentFailureType.invalidResponse,
      'The print agent returned malformed JSON.',
    );
  }

  LocalPrintAgentException _mapDioFailure(
    DioException error, {
    required bool isPrint,
  }) {
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout) {
      return LocalPrintAgentException(
        LocalPrintAgentFailureType.timeout,
        isPrint
            ? 'The print request timed out. Check the agent before printing again.'
            : 'The print agent did not respond before the timeout.',
      );
    }
    return const LocalPrintAgentException(
      LocalPrintAgentFailureType.unreachable,
      'Print agent unreachable. Confirm the agent is running, the phone and laptop use the same private Wi-Fi, and Windows Firewall allows port 9101.',
    );
  }
}

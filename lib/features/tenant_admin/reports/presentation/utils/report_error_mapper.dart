import 'package:dio/dio.dart';

import '../providers/report_providers.dart';

enum ReportErrorKind {
  validation,
  unauthorized,
  notFound,
  server,
  apiUnavailable,
  permissionDenied,
  featureDisabled,
  network,
  conflict,
  unknown,
}

ReportErrorKind reportErrorKind(Object error) {
  if (error is ReportValidationException) {
    return ReportErrorKind.validation;
  }
  if (error is! DioException) {
    return ReportErrorKind.unknown;
  }
  final status = error.response?.statusCode;
  if (status == 400) {
    return ReportErrorKind.validation;
  }
  if (status == 401) {
    return ReportErrorKind.unauthorized;
  }
  if (status == 404 || status == 405 || status == 501) {
    return status == 404
        ? ReportErrorKind.notFound
        : ReportErrorKind.apiUnavailable;
  }
  if (status == 403) {
    return ReportErrorKind.permissionDenied;
  }
  if (status == 409) {
    return ReportErrorKind.conflict;
  }
  if (error.type == DioExceptionType.connectionError ||
      error.type == DioExceptionType.connectionTimeout ||
      error.type == DioExceptionType.receiveTimeout ||
      error.type == DioExceptionType.sendTimeout) {
    return ReportErrorKind.network;
  }
  if (status != null && status >= 500) {
    return ReportErrorKind.server;
  }
  return ReportErrorKind.unknown;
}

String reportErrorMessage(Object error) {
  if (error is ReportValidationException) {
    return error.message;
  }
  if (error is DioException) {
    final apiMessage = _apiErrorMessage(error.response?.data);
    if (apiMessage != null) {
      return apiMessage;
    }
    return _reportDioMessage(error);
  }
  return 'Unable to load this report.';
}

String _reportDioMessage(DioException error) {
  final status = error.response?.statusCode;
  if (status == 400) {
    return 'The report request is invalid. Check the selected filters.';
  }
  if (status == 401) {
    return 'Your session has expired. Please sign in again.';
  }
  if (status == 403) {
    return 'You do not have permission to view this report.';
  }
  if (status == 404) {
    return 'The requested report was not found.';
  }
  if (status == 409) {
    return 'The report request conflicts with the current data state.';
  }
  if (status != null && status >= 500) {
    return 'Reports server error. Please check backend logs and try again.';
  }

  if (error.type == DioExceptionType.connectionError ||
      error.type == DioExceptionType.connectionTimeout ||
      error.type == DioExceptionType.receiveTimeout ||
      error.type == DioExceptionType.sendTimeout) {
    return 'Backend server is not reachable. Check API server and port.';
  }

  return error.message?.trim().isNotEmpty == true
      ? error.message!
      : 'Unable to load this report.';
}

String? _apiErrorMessage(Object? data) {
  if (data is! Map) {
    return null;
  }

  final payload = Map<String, dynamic>.from(data);
  for (final key in const ['message', 'detail', 'title', 'error']) {
    final value = payload[key]?.toString().trim();
    if (value != null && value.isNotEmpty) {
      return value;
    }
  }

  final errors = payload['errors'];
  if (errors is Map && errors.isNotEmpty) {
    final first = errors.values.first;
    if (first is List && first.isNotEmpty) {
      return first.first.toString();
    }
    return first.toString();
  }

  final code = payload['code']?.toString().trim();
  return code == null || code.isEmpty ? null : code;
}

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

String messageFromDioException(
  DioException error, {
  String? contextPrefix,
  String fallback = 'Request failed.',
  String? attemptedBaseUrl,
}) {
  final data = error.response?.data;
  if (data is Map) {
    final message = data['message'];
    if (message is String && message.trim().isNotEmpty) {
      return message;
    }
  }

  final status = error.response?.statusCode;
  if (status == 404) {
    return contextPrefix != null
        ? '$contextPrefix. Products API was not found on the server.'
        : 'Products could not be loaded. The API endpoint was not found.';
  }

  if (status == 403) {
    return contextPrefix != null
        ? '$contextPrefix. You do not have permission to view products.'
        : 'You do not have permission to view products.';
  }

  if (status != null && status >= 500) {
    return contextPrefix != null
        ? '$contextPrefix. Server error — please check backend logs.'
        : 'Server error. Please check backend logs and try again.';
  }

  if (status != null && contextPrefix != null) {
    return '$contextPrefix (HTTP $status).';
  }

  final networkMessage = _networkMessage(error);
  if (networkMessage != null) {
    return _withDebugNetworkHint(networkMessage, attemptedBaseUrl);
  }

  if (contextPrefix != null) {
    return '$contextPrefix. ${error.message ?? fallback}';
  }

  return error.message ?? fallback;
}

String _withDebugNetworkHint(String message, String? attemptedBaseUrl) {
  if (!kDebugMode || attemptedBaseUrl == null || attemptedBaseUrl.isEmpty) {
    return message;
  }

  return '$message Attempted API base URL: $attemptedBaseUrl. '
      'Development hosts: Windows/Desktop/Web use localhost or 127.0.0.1; '
      'Android emulator uses 10.0.2.2; physical devices use the PC LAN IP.';
}

String? _networkMessage(DioException error) {
  switch (error.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.receiveTimeout:
    case DioExceptionType.sendTimeout:
      return 'Backend server is not reachable. Check API server and port.';
    case DioExceptionType.connectionError:
      return _connectionErrorMessage(error);
    case DioExceptionType.badCertificate:
      return 'Secure connection failed. Check HTTPS certificate or use HTTP for development.';
    case DioExceptionType.unknown:
      return _connectionErrorMessage(error);
    default:
      return null;
  }
}

String? _connectionErrorMessage(DioException error) {
  final message =
      (error.message ?? error.error?.toString() ?? '').toLowerCase();

  if (message.contains('connection refused') ||
      message.contains('failed host lookup') ||
      message.contains('network is unreachable')) {
    return 'API server is not running or wrong port.';
  }

  if (message.contains('network error') ||
      message.contains('socketexception') ||
      message.contains('no address associated with hostname')) {
    return 'Network connection failed. Check your internet or Wi-Fi connection.';
  }

  if (message.contains('handshake') ||
      message.contains('certificate') ||
      message.contains('ssl')) {
    return 'Secure connection failed. Check HTTPS certificate or use HTTP for development.';
  }

  if (error.type == DioExceptionType.connectionError ||
      error.type == DioExceptionType.unknown) {
    return 'Backend server is not reachable. Check API server and port.';
  }

  return null;
}

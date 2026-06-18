import 'package:dio/dio.dart';

String messageFromDioException(
  DioException error, {
  String? contextPrefix,
  String fallback = 'Request failed.',
}) {
  final data = error.response?.data;
  if (data is Map) {
    final message = data['message'];
    if (message is String && message.trim().isNotEmpty) {
      return message;
    }
  }

  final status = error.response?.statusCode;
  if (status != null && contextPrefix != null) {
    return '$contextPrefix (HTTP $status).';
  }

  final networkMessage = _networkMessage(error);
  if (networkMessage != null) {
    return networkMessage;
  }

  if (contextPrefix != null) {
    return '$contextPrefix. ${error.message ?? fallback}';
  }

  return error.message ?? fallback;
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

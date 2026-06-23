import 'package:dio/dio.dart';

class PosCheckoutApiException implements Exception {
  PosCheckoutApiException({
    required this.message,
    this.statusCode,
    this.isNetworkUnavailable = false,
  });

  final String message;
  final int? statusCode;
  final bool isNetworkUnavailable;

  @override
  String toString() => message;
}

bool isCheckoutNetworkFallback(DioException error) {
  final status = error.response?.statusCode;
  if (status == 401 ||
      status == 403 ||
      status == 400 ||
      status == 404 ||
      status == 409) {
    return false;
  }

  if (status != null && status >= 500) {
    return true;
  }

  switch (error.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.receiveTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.connectionError:
      return true;
    case DioExceptionType.unknown:
      return _looksLikeNetworkFailure(error);
    default:
      return false;
  }
}

bool _looksLikeNetworkFailure(DioException error) {
  final message =
      (error.message ?? error.error?.toString() ?? '').toLowerCase();

  return message.contains('connection refused') ||
      message.contains('failed host lookup') ||
      message.contains('network is unreachable') ||
      message.contains('network error') ||
      message.contains('socketexception') ||
      message.contains('no address associated with hostname');
}

PosCheckoutApiException checkoutApiExceptionFromDio(DioException error) {
  return PosCheckoutApiException(
    message: _messageFromDio(error),
    statusCode: error.response?.statusCode,
    isNetworkUnavailable: isCheckoutNetworkFallback(error),
  );
}

String _messageFromDio(DioException error) {
  final data = error.response?.data;
  if (data is Map) {
    final message = data['message'];
    if (message is String && message.trim().isNotEmpty) {
      return message.trim();
    }
  }

  final status = error.response?.statusCode;
  if (status == 401) {
    return 'You are not authorized to access checkout.';
  }

  if (status == 403) {
    return 'You do not have permission to perform this checkout action.';
  }

  if (status == 409) {
    return 'Checkout could not continue because of a conflict.';
  }

  if (status == 400 || status == 404) {
    return 'Checkout request could not be validated.';
  }

  if (isCheckoutNetworkFallback(error)) {
    return 'Backend validation is unavailable. Check your connection and try again.';
  }

  return error.message ?? 'Checkout request failed.';
}

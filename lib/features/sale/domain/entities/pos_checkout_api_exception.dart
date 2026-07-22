import 'package:dio/dio.dart';

class PosCheckoutApiException implements Exception {
  PosCheckoutApiException({
    required this.message,
    this.code,
    this.statusCode,
    this.isNetworkUnavailable = false,
  });

  final String message;
  final String? code;
  final int? statusCode;
  final bool isNetworkUnavailable;

  @override
  String toString() => message;
}

bool isCheckoutNetworkFallback(DioException error) {
  if (error.response?.statusCode != null) {
    return false;
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
  final data = error.response?.data;
  return PosCheckoutApiException(
    message: _messageFromDio(error),
    code: data is Map ? (data['code'] ?? data['errorCode'])?.toString() : null,
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

    final validationMessage = _validationMessageFromErrors(data['errors']);
    if (validationMessage != null) {
      return validationMessage;
    }

    final title = data['title'];
    if (title is String && title.trim().isNotEmpty) {
      return title.trim();
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
    return 'Checkout could not continue because stock or prices changed. Refresh the cart and try again.';
  }

  if (status == 400 || status == 404) {
    return 'Checkout request could not be validated.';
  }

  if (status != null && status >= 500) {
    return 'Server error while processing checkout. Try again.';
  }

  if (isCheckoutNetworkFallback(error)) {
    return 'Backend validation is unavailable. Check your connection and try again.';
  }

  return error.message ?? 'Checkout request failed.';
}

String? _validationMessageFromErrors(Object? errors) {
  if (errors is Map) {
    for (final value in errors.values) {
      final message = _firstMessage(value);
      if (message != null) {
        return message;
      }
    }
  }

  return _firstMessage(errors);
}

String? _firstMessage(Object? value) {
  if (value is String && value.trim().isNotEmpty) {
    return value.trim();
  }

  if (value is Iterable) {
    for (final item in value) {
      final message = _firstMessage(item);
      if (message != null) {
        return message;
      }
    }
  }

  return null;
}

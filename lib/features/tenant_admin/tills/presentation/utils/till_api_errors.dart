import 'package:dio/dio.dart';

Map<String, String> tillValidationErrors(DioException error) {
  final data = error.response?.data;
  if (data is! Map) {
    return const {};
  }

  final mapped = <String, String>{};
  final errors = data['errors'];

  if (errors is List) {
    for (final item in errors) {
      if (item is! Map) {
        continue;
      }

      final field = item['field']?.toString() ?? '';
      final message = item['message']?.toString() ?? '';
      if (field.isEmpty || message.isEmpty) {
        continue;
      }

      mapped[field] = message;
    }
  }

  if (errors is Map) {
    return errors.map((key, value) {
      final message = value is List && value.isNotEmpty
          ? value.first.toString()
          : value.toString();
      return MapEntry(key.toString(), message);
    });
  }

  return mapped;
}

String tillErrorMessage(DioException error, {String fallback = 'Request failed'}) {
  if (error.type == DioExceptionType.connectionError ||
      error.type == DioExceptionType.connectionTimeout ||
      error.type == DioExceptionType.sendTimeout ||
      error.type == DioExceptionType.receiveTimeout) {
    return 'Unable to reach the server. Start the backend on port 5052 and try again.';
  }

  final statusCode = error.response?.statusCode;
  if (statusCode == 403) {
    return 'You do not have permission to perform this action.';
  }

  if (statusCode == 409) {
    return 'A till with this code already exists for the outlet.';
  }

  final data = error.response?.data;
  if (data is Map && data['message'] != null) {
    return data['message'].toString();
  }

  return error.message ?? fallback;
}

String tillSubmitErrorMessage(
  DioException error,
  Map<String, String> fieldErrors, {
  String fallback = 'Failed to save till',
}) {
  if (fieldErrors.isNotEmpty) {
    return fieldErrors.values.first;
  }

  return tillErrorMessage(error, fallback: fallback);
}

String formatTillSales(double amount, String currency) {
  final symbol = currency.toUpperCase() == 'GBP'
      ? '£'
      : currency.toUpperCase() == 'LKR'
          ? 'Rs '
          : '$currency ';

  return '$symbol${amount.toStringAsFixed(2)}';
}

String formatTillLastSync(DateTime? value) {
  if (value == null) {
    return 'Never';
  }

  final difference = DateTime.now().toUtc().difference(value.toUtc());
  if (difference.inMinutes < 1) {
    return 'Just now';
  }

  if (difference.inMinutes < 60) {
    return '${difference.inMinutes} min ago';
  }

  if (difference.inHours < 24) {
    return '${difference.inHours} hr ago';
  }

  return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
}

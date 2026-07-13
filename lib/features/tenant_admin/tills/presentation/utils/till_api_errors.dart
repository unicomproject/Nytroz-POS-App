import 'package:dio/dio.dart';

const tillBackendFieldAliases = {
  'tillName': 'name',
  'name': 'name',
  'tillCode': 'code',
  'code': 'code',
  'outletId': 'outletId',
  'status': 'status',
};

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

      final key = tillBackendFieldAliases[field] ?? field;
      mapped[key] = message;
    }

    if (mapped.isNotEmpty) {
      return mapped;
    }
  }

  if (errors is Map) {
    return errors.map((key, value) {
      final field = key.toString();
      final message = value is List && value.isNotEmpty
          ? value.first.toString()
          : value.toString();
      return MapEntry(tillBackendFieldAliases[field] ?? field, message);
    });
  }

  return const {};
}

String tillErrorMessage(DioException error, {String fallback = 'Request failed'}) {
  final data = error.response?.data;
  if (data is Map && data['message'] != null) {
    return data['message'].toString();
  }

  return error.message ?? fallback;
}

String tillUnexpectedErrorMessage(Object error, {String fallback = 'Failed to save till'}) {
  if (error is DioException) {
    return tillSubmitErrorMessage(error, tillValidationErrors(error), fallback: fallback);
  }

  return fallback;
}

String tillSubmitErrorMessage(
  DioException error,
  Map<String, String> fieldErrors, {
  String fallback = 'Failed to save till',
}) {
  if (fieldErrors.isNotEmpty) {
    return fieldErrors.values.first;
  }

  final statusCode = error.response?.statusCode;
  if (statusCode == 401) {
    return tillErrorMessage(
      error,
      fallback: 'Your session has expired. Please sign in again.',
    );
  }

  if (statusCode == 403) {
    return tillErrorMessage(
      error,
      fallback: 'You do not have permission to create tills.',
    );
  }

  if (statusCode == 409) {
    return tillErrorMessage(
      error,
      fallback: 'A till with this code already exists for this tenant.',
    );
  }

  final message = tillErrorMessage(error, fallback: fallback);
  final traceId = tillErrorTraceId(error);
  if (traceId != null && traceId.isNotEmpty) {
    return '$message (Ref: $traceId)';
  }

  return message;
}

String? tillErrorTraceId(DioException error) {
  final data = error.response?.data;
  if (data is Map && data['traceId'] != null) {
    return data['traceId'].toString();
  }

  return null;
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

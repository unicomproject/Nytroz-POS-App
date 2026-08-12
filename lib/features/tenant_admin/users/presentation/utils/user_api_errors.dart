import 'package:dio/dio.dart';

String userErrorMessage(DioException error,
    {String fallback = 'Request failed'}) {
  final data = error.response?.data;
  if (data is Map && data['message'] != null) {
    return data['message'].toString();
  }

  return error.message ?? fallback;
}

String? _errorCode(DioException error) {
  final data = error.response?.data;
  if (data is Map && data['code'] != null) {
    return data['code'].toString();
  }

  return null;
}

Map<String, String> userValidationErrors(DioException error) {
  final detailErrors = _detailFieldErrors(error);
  if (detailErrors.isNotEmpty) {
    return detailErrors;
  }

  final code = _errorCode(error);
  final message = userErrorMessage(error, fallback: 'Failed to save user');

  switch (code) {
    case 'user.duplicate_email':
      return {'email': message};
    case 'user.role_not_found':
      return {'roleId': message};
    case 'user.outlet_not_found':
      return {'outletIds': message};
    case 'user.invalid_permissions':
      return {'permissions': message};
    case 'user.validation_failed':
      return {'form': message};
    default:
      return const {};
  }
}

Map<String, String> _detailFieldErrors(DioException error) {
  final data = error.response?.data;
  if (data is! Map || data['details'] is! List) {
    return const {};
  }

  final errors = <String, String>{};
  for (final item in data['details'] as List) {
    if (item is! Map) {
      continue;
    }

    final field = item['field']?.toString();
    if (field == null || field.trim().isEmpty) {
      continue;
    }

    final message = item['message']?.toString() ??
        item['error']?.toString() ??
        userErrorMessage(error, fallback: 'Invalid value.');
    errors[field.trim()] = message;
  }

  return errors;
}

String userSubmitErrorMessage(
  DioException error, {
  String fallback = 'Failed to save user',
}) {
  final statusCode = error.response?.statusCode;
  if (statusCode == 401) {
    return userErrorMessage(
      error,
      fallback: 'Your session has expired. Please sign in again.',
    );
  }

  if (statusCode == 403) {
    return userErrorMessage(
      error,
      fallback: 'You do not have permission to perform this action.',
    );
  }

  if (statusCode == 409) {
    return userErrorMessage(
      error,
      fallback: 'A user with this email already exists for this tenant.',
    );
  }

  return userErrorMessage(error, fallback: fallback);
}

String formatUserLastActive(DateTime? value) {
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

String formatUserDate(DateTime? value) {
  if (value == null) {
    return '—';
  }

  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  return '${months[value.month - 1]} ${value.day}, ${value.year}';
}

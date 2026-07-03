import 'package:dio/dio.dart';

import '../../../../../core/network/dio_error_message.dart';

const outletBackendFieldAliases = {
  'name': 'outletName',
  'code': 'outletCode',
  'outletType': 'outletType',
  'phone': 'mainPhoneNumber',
  'email': 'emailAddress',
  'status': 'status',
  'addressLine1': 'addressLine1',
  'addressLine2': 'addressLine2',
  'city': 'city',
  'state': 'state',
  'country': 'country',
  'postalCode': 'postalCode',
};

Map<String, String> outletValidationErrors(DioException error) {
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

      final key = outletBackendFieldAliases[field] ?? field;
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
      return MapEntry(outletBackendFieldAliases[field] ?? field, message);
    });
  }

  return const {};
}

String outletErrorMessage(DioException error,
    {String fallback = 'Request failed'}) {
  final data = error.response?.data;
  if (data is Map && data['message'] != null) {
    final message = data['message'].toString().trim();
    if (message.isNotEmpty) {
      return message;
    }
  }

  if (error.response?.statusCode != null) {
    return fallback;
  }

  return messageFromDioException(error, fallback: fallback);
}

String outletSubmitErrorMessage(
  DioException error,
  Map<String, String> fieldErrors, {
  String fallback = 'Failed to save outlet',
}) {
  if (fieldErrors.isNotEmpty) {
    return fieldErrors.values.first;
  }

  return outletErrorMessage(error, fallback: fallback);
}

String outletDeleteErrorMessage(Object error) {
  if (error is! DioException) {
    return 'Unable to delete outlet. Please try again.';
  }

  final statusCode = error.response?.statusCode;
  if (statusCode == 401) {
    return outletErrorMessage(
      error,
      fallback: 'Your session has expired. Please sign in again.',
    );
  }

  if (statusCode == 403) {
    return outletErrorMessage(
      error,
      fallback: 'You do not have permission to delete outlets.',
    );
  }

  if (statusCode == 404) {
    return outletErrorMessage(
      error,
      fallback: 'Outlet was not found.',
    );
  }

  if (statusCode == 409) {
    return outletErrorMessage(
      error,
      fallback:
          'Outlet cannot be deleted while it has active tills, open sessions, or sales history.',
    );
  }

  return outletErrorMessage(
    error,
    fallback: 'Unable to delete outlet. Please try again.',
  );
}

String outletLoadErrorMessage(Object error) {
  if (error is DioException && error.response?.statusCode == 401) {
    return 'Your session has expired. Please sign in again.';
  }

  return 'Please try again.';
}

const outletFieldSteps = {
  'outletName': 0,
  'outletCode': 0,
  'outletType': 0,
  'status': 0,
  'mainPhoneNumber': 1,
  'emailAddress': 1,
  'managerId': 0,
  'addressLine1': 1,
  'addressLine2': 1,
  'city': 1,
  'state': 1,
  'country': 1,
  'postalCode': 1,
};

int? outletErrorStep(Map<String, String> fieldErrors) {
  var step = 2;

  for (final field in fieldErrors.keys) {
    final fieldStep = outletFieldSteps[field];
    if (fieldStep != null && fieldStep < step) {
      step = fieldStep;
    }
  }

  return step == 2 ? null : step;
}

import 'package:dio/dio.dart';

import '../../../../../core/network/dio_error_message.dart';

const outletBackendFieldAliases = {
  'outletName': 'outletName',
  'OutletName': 'outletName',
  'name': 'outletName',
  'code': 'outletCode',
  'outletType': 'outletType',
  'phone': 'mainPhoneNumber',
  'contactPhone': 'mainPhoneNumber',
  'email': 'emailAddress',
  'contactEmail': 'emailAddress',
  'status': 'status',
  'addressLine1': 'addressLine1',
  'addressLine2': 'addressLine2',
  'city': 'city',
  'state': 'state',
  'stateOrProvince': 'state',
  'districtOrProvince': 'state',
  'country': 'country',
  'countryCode': 'country',
  'postalCode': 'postalCode',
  'timezone': 'timezone',
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
    for (final entry in errors.entries) {
      final field = entry.key.toString();
      final message = entry.value is List && (entry.value as List).isNotEmpty
          ? (entry.value as List).first.toString()
          : entry.value.toString();
      final key = outletBackendFieldAliases[field] ?? field;
      mapped[key] = message;
    }

    if (mapped.isNotEmpty) {
      return mapped;
    }
  }

  final message = data['message']?.toString() ?? '';
  final lowerMessage = message.toLowerCase();
  if (lowerMessage.contains('timezone')) {
    mapped['timezone'] = message;
  } else if (lowerMessage.contains('outletname') ||
      lowerMessage.contains('outlet name')) {
    mapped['outletName'] = message;
  }

  return mapped;
}

String outletErrorMessage(DioException error,
    {String fallback = 'Request failed'}) {
  final data = error.response?.data;
  if (data is Map && data['message'] != null) {
    return data['message'].toString();
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
  'timezone': 1,
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

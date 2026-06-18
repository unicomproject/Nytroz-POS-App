import 'package:dio/dio.dart';

import '../../../../../core/network/dio_error_message.dart';

const outletBackendFieldAliases = {
  'name': 'outletName',
  'code': 'outletCode',
  'phone': 'mainPhoneNumber',
  'email': 'emailAddress',
  'addressLine1': 'addressLine1',
  'addressLine2': 'addressLine2',
  'city': 'city',
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

const outletFieldSteps = {
  'outletName': 0,
  'outletCode': 0,
  'outletType': 0,
  'mainPhoneNumber': 0,
  'emailAddress': 0,
  'managerId': 0,
  'addressLine1': 1,
  'addressLine2': 1,
  'city': 1,
  'country': 1,
  'postalCode': 1,
};

int? outletErrorStep(Map<String, String> fieldErrors) {
  var step = 3;

  for (final field in fieldErrors.keys) {
    final fieldStep = outletFieldSteps[field];
    if (fieldStep != null && fieldStep < step) {
      step = fieldStep;
    }
  }

  return step == 3 ? null : step;
}

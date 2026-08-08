import 'package:dio/dio.dart';

import '../../../../../core/network/dio_error_message.dart';

const outletBackendFieldAliases = {
  'outletName': 'outletName',
  'OutletName': 'outletName',
  'name': 'outletName',
  'code': 'outletCode',
  'outletType': 'outletType',
  'phone': 'mainPhoneNumber',
  'contactPhone': 'contactPhone',
  'email': 'emailAddress',
  'contactEmail': 'contactEmail',
  'contactName': 'contactName',
  'address.contactName': 'contactName',
  'address.contactPhone': 'contactPhone',
  'address.contactEmail': 'contactEmail',
  'imageMediaAssetId': 'outletImage',
  'imageOperation': 'outletImage',
  'status': 'status',
  'addressLine1': 'addressLine1',
  'address.addressLine1': 'addressLine1',
  'addressLine2': 'addressLine2',
  'address.addressLine2': 'addressLine2',
  'city': 'city',
  'address.city': 'city',
  'state': 'state',
  'stateOrProvince': 'state',
  'address.stateOrProvince': 'state',
  'districtOrProvince': 'state',
  'country': 'country',
  'countryCode': 'country',
  'address.countryCode': 'country',
  'postalCode': 'postalCode',
  'address.postalCode': 'postalCode',
  'timezone': 'timezone',
};

Map<String, String> outletValidationErrors(DioException error) {
  final data = error.response?.data;
  if (data is! Map) {
    return const {};
  }

  final mapped = <String, String>{};

  final errors = data['errors'];
  _addFieldErrors(mapped, errors);
  if (mapped.isNotEmpty) {
    return mapped;
  }

  final details = data['details'];
  _addFieldErrors(mapped, details);
  if (mapped.isNotEmpty) {
    return mapped;
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

void _addFieldErrors(Map<String, String> mapped, Object? source) {
  if (source is List) {
    for (final item in source) {
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
    return;
  }

  if (source is Map) {
    for (final entry in source.entries) {
      final field = entry.key.toString();
      final value = entry.value;
      final message = value is List && value.isNotEmpty
          ? value.first.toString()
          : value.toString();
      final key = outletBackendFieldAliases[field] ?? field;
      mapped[key] = message;
    }
  }
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
  'mainPhoneNumber': 0,
  'emailAddress': 0,
  'managerId': 0,
  'contactName': 1,
  'contactPhone': 1,
  'contactEmail': 1,
  'outletImage': 1,
  'addressLine1': 1,
  'addressLine2': 1,
  'city': 1,
  'state': 1,
  'country': 1,
  'postalCode': 1,
  'timezone': 1,
  'businessHours': 2,
  'businessHours.dayOfWeek': 2,
  'businessHours.openingTime': 2,
  'businessHours.closingTime': 2,
};

int? outletErrorStep(Map<String, String> fieldErrors) {
  var step = 3;

  for (final field in fieldErrors.keys) {
    final fieldStep =
        field.startsWith('businessHours') ? 2 : outletFieldSteps[field];
    if (fieldStep != null && fieldStep < step) {
      step = fieldStep;
    }
  }

  return step == 3 ? null : step;
}

import 'package:dio/dio.dart';

import '../../../../../core/network/dio_error_message.dart';

String inventoryApiErrorMessage(
  Object error, {
  String fallback = 'Unable to complete inventory request.',
}) {
  if (error is DioException) {
    return messageFromDioException(
      error,
      contextPrefix: 'Inventory request failed',
      fallback: fallback,
    );
  }

  return error.toString();
}

Map<String, String> inventoryValidationErrors(DioException error) {
  final data = error.response?.data;
  if (data is! Map) {
    return const {};
  }

  final mapped = <String, String>{};
  _addFieldErrors(mapped, data['details']);
  if (mapped.isNotEmpty) {
    return mapped;
  }

  _addFieldErrors(mapped, data['errors']);
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

      mapped[field] = message;
    }
  }
}

String stockStatusLabel(String status) {
  switch (status.toUpperCase()) {
    case 'IN_STOCK':
      return 'In stock';
    case 'LOW_STOCK':
      return 'Low stock';
    case 'OUT_OF_STOCK':
      return 'Out of stock';
    default:
      return 'Unknown';
  }
}

String expiryStatusLabel(String status) {
  switch (status.toUpperCase()) {
    case 'NOT_APPLICABLE':
      return 'Not applicable';
    case 'VALID':
      return 'Valid';
    case 'EXPIRING_SOON':
      return 'Expiring soon';
    case 'EXPIRED':
      return 'Expired';
    default:
      return 'Unknown';
  }
}

String formatInventoryQuantity(double value) {
  if (value == value.roundToDouble()) {
    return value.toStringAsFixed(0);
  }

  return value.toStringAsFixed(2);
}

String? nullableTrimmed(String? value) {
  if (value == null) {
    return null;
  }

  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}

import 'package:dio/dio.dart';

import '../../domain/repositories/inventory_repository.dart';

const inventoryBackendFieldAliases = {
  'productId': 'productId',
  'variantId': 'variantId',
  'inventoryLocationId': 'inventoryLocationId',
  'quantity': 'quantity',
  'unitCost': 'unitCost',
  'batchNumber': 'batchNumber',
  'expiryDate': 'expiryDate',
  'manufacturedDate': 'manufacturedDate',
  'reason': 'reason',
};

Map<String, String> inventoryValidationErrors(DioException error) {
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

      mapped[inventoryBackendFieldAliases[field] ?? field] = message;
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
      return MapEntry(inventoryBackendFieldAliases[field] ?? field, message);
    });
  }

  return const {};
}

String inventoryLoadErrorMessage(Object error) {
  if (error is InventoryApiUnavailable) {
    return 'Inventory data is not available yet (${error.endpoint}).';
  }

  if (error is DioException) {
    if (error.response?.statusCode == 401) {
      return 'Your session has expired. Please sign in again.';
    }

    if (error.response?.statusCode == 403) {
      return 'You do not have permission to view inventory.';
    }
  }

  return 'Please try again.';
}

String inventorySubmitErrorMessage(
  DioException error,
  Map<String, String> fieldErrors, {
  String fallback = 'Failed to save stock',
}) {
  if (fieldErrors.isNotEmpty) {
    return fieldErrors.values.first;
  }

  final statusCode = error.response?.statusCode;
  if (statusCode == 401) {
    return 'Your session has expired. Please sign in again.';
  }

  if (statusCode == 403) {
    return 'You do not have permission to adjust stock.';
  }

  if (statusCode == 409) {
    final data = error.response?.data;
    if (data is Map && data['message'] != null) {
      return data['message'].toString();
    }

    return 'Stock-in conflict. Please review the details and try again.';
  }

  if (statusCode == 400) {
    final data = error.response?.data;
    if (data is Map && data['message'] != null) {
      return data['message'].toString();
    }

    return 'Please check the stock details and try again.';
  }

  final data = error.response?.data;
  if (data is Map && data['message'] != null) {
    return data['message'].toString();
  }

  return fallback;
}

String formatInventoryQuantity(num? value) {
  if (value == null) {
    return '—';
  }

  if (value == value.roundToDouble()) {
    return value.toStringAsFixed(0);
  }

  return value.toStringAsFixed(2);
}

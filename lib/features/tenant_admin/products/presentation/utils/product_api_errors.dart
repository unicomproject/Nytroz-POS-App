import 'package:dio/dio.dart';

import '../../../../../core/network/dio_error_message.dart';
import '../../../presentation/widgets/tenant_admin_status_badge.dart';

const productBackendFieldAliases = {
  'name': 'name',
  'sku': 'sku',
  'barcode': 'barcode',
  'categoryName': 'categoryName',
  'sellingPrice': 'sellingPrice',
};

Map<String, String> productValidationErrors(DioException error) {
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

      mapped[productBackendFieldAliases[field] ?? field] = message;
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
      return MapEntry(productBackendFieldAliases[field] ?? field, message);
    });
  }

  return const {};
}

String productErrorMessage(
  DioException error, {
  String fallback = 'Request failed',
}) {
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

String productLoadErrorMessage(Object error) {
  if (error is DioException) {
    if (error.response?.statusCode == 401) {
      return 'Your session has expired. Please sign in again.';
    }

    if (error.response?.statusCode == 403) {
      return 'You do not have permission to view products.';
    }
  }

  return 'Please try again.';
}

String productSubmitErrorMessage(
  DioException error,
  Map<String, String> fieldErrors, {
  String fallback = 'Failed to save product',
}) {
  if (fieldErrors.isNotEmpty) {
    return fieldErrors.values.first;
  }

  final statusCode = error.response?.statusCode;
  if (statusCode == 401) {
    return productErrorMessage(
      error,
      fallback: 'Your session has expired. Please sign in again.',
    );
  }

  if (statusCode == 403) {
    return productErrorMessage(
      error,
      fallback: 'You do not have permission to create products.',
    );
  }

  if (statusCode == 409) {
    return productErrorMessage(
      error,
      fallback: 'A product with this SKU or barcode already exists.',
    );
  }

  if (statusCode == 400) {
    return productErrorMessage(
      error,
      fallback: 'Please check the product details and try again.',
    );
  }

  return productErrorMessage(error, fallback: fallback);
}

String formatProductPrice(double? amount, {String currency = 'LKR'}) {
  if (amount == null) {
    return '-';
  }

  final formatted = amount == amount.roundToDouble()
      ? amount.toStringAsFixed(0)
      : amount.toStringAsFixed(2);

  return '$currency $formatted';
}

String displayProductStatus(String status) {
  if (status.trim().isEmpty) {
    return '-';
  }

  final normalized = status.trim();
  return normalized[0].toUpperCase() + normalized.substring(1);
}

TenantAdminStatusType productStatusType(String status) {
  switch (status.toLowerCase()) {
    case 'active':
      return TenantAdminStatusType.active;
    case 'inactive':
      return TenantAdminStatusType.inactive;
    case 'draft':
      return TenantAdminStatusType.pending;
    default:
      return TenantAdminStatusType.warning;
  }
}

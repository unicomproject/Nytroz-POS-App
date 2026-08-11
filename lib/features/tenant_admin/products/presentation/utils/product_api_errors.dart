import 'package:dio/dio.dart';

const productBackendFieldAliases = {
  'productName': 'productName',
  'productCode': 'productCode',
  'shortName': 'productCode',
  'internalCode': 'productCode',
  'sku': 'sku',
  'barcode': 'barcode',
  'categoryId': 'categoryId',
  'subCategoryId': 'subCategoryId',
  'brandId': 'brandId',
  'unitType': 'unitType',
  'shortDescription': 'shortDescription',
  'sellingPrice': 'sellingPrice',
  'costPrice': 'costPrice',
  'discountPrice': 'discountPrice',
  'taxId': 'taxId',
  'outletIds': 'outletIds',
  'openingStockQuantity': 'openingStockQuantity',
  'minimumStockAlertQuantity': 'minimumStockAlertQuantity',
  'stockUnit': 'stockUnit',
  'status': 'status',
};

String? _errorCode(DioException error) {
  final data = error.response?.data;
  if (data is Map && data['code'] != null) {
    return data['code'].toString();
  }

  return null;
}

String productErrorMessage(DioException error,
    {String fallback = 'Request failed'}) {
  final data = error.response?.data;
  if (data is Map && data['message'] != null) {
    return data['message'].toString();
  }

  return error.message ?? fallback;
}

Map<String, String> productValidationErrors(DioException error) {
  final data = error.response?.data;
  if (data is! Map) {
    return const {};
  }

  final mapped = <String, String>{};
  final message = data['message']?.toString() ?? 'Validation failed.';

  final details = data['details'];
  if (details is List) {
    for (final item in details) {
      if (item is! Map) {
        continue;
      }

      final field = item['field']?.toString() ?? '';
      final fieldMessage = item['message']?.toString() ?? '';
      if (field.isEmpty || fieldMessage.isEmpty) {
        continue;
      }

      final key = productBackendFieldAliases[field] ?? field;
      mapped[key] = fieldMessage;
    }

    if (mapped.isNotEmpty) {
      return mapped;
    }
  }

  final code = _errorCode(error);
  switch (code) {
    case 'product.duplicate_sku':
      return {'sku': message};
    case 'product.duplicate_barcode':
      return {'barcode': message};
    case 'product.duplicate_code':
    case 'product.duplicate_product_code':
      return {'productCode': message};
    case 'product.invalid_category':
      return {'categoryId': message};
    case 'product.invalid_brand':
      return {'brandId': message};
    case 'product.validation_failed':
      return mapped;
    default:
      return const {};
  }
}

int? productErrorStep(Map<String, String> fieldErrors) {
  const stepZero = {
    'productName',
    'sku',
    'barcode',
    'categoryId',
    'subCategoryId',
    'brandId',
    'unitType',
    'shortDescription',
  };
  const stepOne = {'sellingPrice', 'taxId'};
  const stepTwo = {
    'outletIds',
    'openingStockQuantity',
    'minimumStockAlertQuantity',
    'stockUnit',
  };

  for (final field in fieldErrors.keys) {
    if (stepZero.contains(field)) {
      return 0;
    }
  }

  for (final field in fieldErrors.keys) {
    if (stepOne.contains(field)) {
      return 1;
    }
  }

  for (final field in fieldErrors.keys) {
    if (stepTwo.contains(field)) {
      return 2;
    }
  }

  return null;
}

String productSubmitErrorMessage(
  DioException error, {
  String fallback = 'Failed to save product',
}) {
  return _productActionErrorMessage(error, fallback: fallback);
}

String productDeleteErrorMessage(
  DioException error, {
  String fallback = 'Failed to delete product',
}) {
  final code = _errorCode(error);
  if (code == 'product.delete_blocked' || code == 'product.not_found') {
    return productErrorMessage(error, fallback: fallback);
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
      fallback: 'You do not have permission to delete products.',
    );
  }

  return productErrorMessage(error, fallback: fallback);
}

String _productActionErrorMessage(
  DioException error, {
  required String fallback,
}) {
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
      fallback: 'You do not have permission to save products.',
    );
  }

  return productErrorMessage(error, fallback: fallback);
}

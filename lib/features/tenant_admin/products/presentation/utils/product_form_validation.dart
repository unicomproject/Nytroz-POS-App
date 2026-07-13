import '../../domain/entities/tenant_product_create_options.dart';

Map<String, String> validateProductForm({
  required String productName,
  required String sku,
  required String? barcode,
  required String? categoryId,
  required String? unitCode,
  required String sellingPriceText,
  required bool trackInventory,
  required String openingStockText,
  required String minimumStockText,
  required Set<String> selectedOutletIds,
}) {
  final errors = <String, String>{};

  if (productName.trim().isEmpty) {
    errors['productName'] = 'Product name is required.';
  } else if (productName.trim().length > 200) {
    errors['productName'] = 'Product name cannot exceed 200 characters.';
  }

  if (sku.trim().isEmpty) {
    errors['sku'] = 'SKU is required.';
  } else if (sku.trim().length > 255) {
    errors['sku'] = 'SKU cannot exceed 255 characters.';
  }

  if (barcode != null && barcode.trim().length > 255) {
    errors['barcode'] = 'Barcode cannot exceed 255 characters.';
  }

  if (categoryId == null || categoryId.trim().isEmpty) {
    errors['categoryId'] = 'Category is required.';
  }

  if (unitCode == null || unitCode.trim().isEmpty) {
    errors['unitType'] = 'Unit type is required.';
  }

  final sellingPrice = _parseDecimal(sellingPriceText);
  if (sellingPrice == null || sellingPrice <= 0) {
    errors['sellingPrice'] = 'Selling price is required.';
  }

  if (trackInventory) {
    if (selectedOutletIds.isEmpty) {
      errors['outletIds'] =
          'At least one outlet is required when tracking inventory.';
    }

    final openingStock = _parseDecimal(openingStockText);
    if (openingStock == null) {
      errors['openingStockQuantity'] =
          'Opening stock quantity is required when tracking inventory.';
    } else if (openingStock < 0) {
      errors['openingStockQuantity'] =
          'Opening stock quantity cannot be negative.';
    }

    final minimumStock = _parseDecimal(minimumStockText);
    if (minimumStock == null) {
      errors['minimumStockAlertQuantity'] =
          'Minimum stock alert quantity is required when tracking inventory.';
    } else if (minimumStock < 0) {
      errors['minimumStockAlertQuantity'] =
          'Minimum stock alert quantity cannot be negative.';
    }

    if (unitCode == null || unitCode.trim().isEmpty) {
      errors['stockUnit'] = 'Stock unit is required when tracking inventory.';
    }
  }

  return errors;
}

Map<String, String> validateProductUpdateForm({
  required String productName,
  required String sku,
  required String? barcode,
  required String? categoryId,
  required String? unitCode,
  required String sellingPriceText,
  required String costPriceText,
  required String discountPriceText,
  required bool trackInventory,
  required String openingStockText,
  required String minimumStockText,
  required Set<String> selectedOutletIds,
}) {
  final errors = <String, String>{};

  if (productName.trim().isEmpty) {
    errors['productName'] = 'Product name is required.';
  } else if (productName.trim().length > 200) {
    errors['productName'] = 'Product name cannot exceed 200 characters.';
  }

  if (sku.trim().isEmpty) {
    errors['sku'] = 'SKU is required.';
  } else if (sku.trim().length > 255) {
    errors['sku'] = 'SKU cannot exceed 255 characters.';
  }

  if (barcode != null && barcode.trim().length > 255) {
    errors['barcode'] = 'Barcode cannot exceed 255 characters.';
  }

  if (categoryId == null || categoryId.trim().isEmpty) {
    errors['categoryId'] = 'Category is required.';
  }

  if (unitCode == null || unitCode.trim().isEmpty) {
    errors['unitType'] = 'Unit type is required.';
  }

  final sellingPrice = _parseDecimal(sellingPriceText);
  if (sellingPrice == null || sellingPrice < 0) {
    errors['sellingPrice'] = 'Selling price must be zero or greater.';
  }

  final costPrice = _parseDecimal(costPriceText);
  if (costPrice != null && costPrice < 0) {
    errors['costPrice'] = 'Cost price cannot be negative.';
  }

  final discountPrice = _parseDecimal(discountPriceText);
  if (discountPrice != null && discountPrice < 0) {
    errors['discountPrice'] = 'Discount price cannot be negative.';
  } else if (discountPrice != null &&
      sellingPrice != null &&
      discountPrice > sellingPrice) {
    errors['discountPrice'] = 'Discount price cannot exceed selling price.';
  }

  if (trackInventory) {
    if (selectedOutletIds.isEmpty) {
      errors['outletIds'] =
          'At least one outlet is required when tracking inventory.';
    }

    final openingStock = _parseDecimal(openingStockText);
    if (openingStock == null) {
      errors['openingStockQuantity'] =
          'Opening stock quantity is required when tracking inventory.';
    } else if (openingStock < 0) {
      errors['openingStockQuantity'] =
          'Opening stock quantity cannot be negative.';
    }

    final minimumStock = _parseDecimal(minimumStockText);
    if (minimumStock == null) {
      errors['minimumStockAlertQuantity'] =
          'Minimum stock alert quantity is required when tracking inventory.';
    } else if (minimumStock < 0) {
      errors['minimumStockAlertQuantity'] =
          'Minimum stock alert quantity cannot be negative.';
    }

    if (unitCode == null || unitCode.trim().isEmpty) {
      errors['stockUnit'] = 'Stock unit is required when tracking inventory.';
    }
  }

  return errors;
}

Map<String, String> validateBasicStep({
  required String productName,
  required String sku,
  required String? barcode,
  required String? categoryId,
  required String? unitCode,
}) {
  final errors = <String, String>{};

  if (productName.trim().isEmpty) {
    errors['productName'] = 'Product name is required.';
  } else if (productName.trim().length > 200) {
    errors['productName'] = 'Product name cannot exceed 200 characters.';
  }

  if (sku.trim().isEmpty) {
    errors['sku'] = 'SKU is required.';
  } else if (sku.trim().length > 255) {
    errors['sku'] = 'SKU cannot exceed 255 characters.';
  }

  if (barcode != null && barcode.trim().length > 255) {
    errors['barcode'] = 'Barcode cannot exceed 255 characters.';
  }

  if (categoryId == null || categoryId.trim().isEmpty) {
    errors['categoryId'] = 'Category is required.';
  }

  if (unitCode == null || unitCode.trim().isEmpty) {
    errors['unitType'] = 'Unit type is required.';
  }

  return errors;
}

Map<String, String> validatePriceStep({required String sellingPriceText}) {
  final errors = <String, String>{};
  final sellingPrice = _parseDecimal(sellingPriceText);
  if (sellingPrice == null || sellingPrice <= 0) {
    errors['sellingPrice'] = 'Selling price is required.';
  }
  return errors;
}

Map<String, String> validateStockStep({
  required bool trackInventory,
  required String openingStockText,
  required String minimumStockText,
  required Set<String> selectedOutletIds,
  required String? unitCode,
}) {
  if (!trackInventory) {
    return const {};
  }

  final errors = <String, String>{};

  if (selectedOutletIds.isEmpty) {
    errors['outletIds'] =
        'At least one outlet is required when tracking inventory.';
  }

  final openingStock = _parseDecimal(openingStockText);
  if (openingStock == null) {
    errors['openingStockQuantity'] =
        'Opening stock quantity is required when tracking inventory.';
  } else if (openingStock < 0) {
    errors['openingStockQuantity'] =
        'Opening stock quantity cannot be negative.';
  }

  final minimumStock = _parseDecimal(minimumStockText);
  if (minimumStock == null) {
    errors['minimumStockAlertQuantity'] =
        'Minimum stock alert quantity is required when tracking inventory.';
  } else if (minimumStock < 0) {
    errors['minimumStockAlertQuantity'] =
        'Minimum stock alert quantity cannot be negative.';
  }

  if (unitCode == null || unitCode.trim().isEmpty) {
    errors['stockUnit'] = 'Stock unit is required when tracking inventory.';
  }

  return errors;
}

String? unitCodeForId(TenantProductCreateOptions options, String? unitId) {
  if (unitId == null) {
    return null;
  }

  for (final unit in options.units) {
    if (unit.id == unitId) {
      return unit.code;
    }
  }

  return null;
}

String? unitIdForCode(TenantProductCreateOptions options, String? unitCode) {
  if (unitCode == null || unitCode.trim().isEmpty) {
    return null;
  }

  for (final unit in options.units) {
    if (unit.code == unitCode) {
      return unit.id;
    }
  }

  return null;
}

double? _parseDecimal(String value) {
  if (value.trim().isEmpty) {
    return null;
  }

  return double.tryParse(value.trim());
}

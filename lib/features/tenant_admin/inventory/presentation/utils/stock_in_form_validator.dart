import '../../domain/entities/inventory.dart';
import '../config/inventory_api_capabilities.dart';

class StockInValidationOptions {
  const StockInValidationOptions({
    this.requiresBatchNumber = false,
    this.requiresExpiryDate = false,
    this.requiresReason = false,
    this.requiresUnitCost = false,
    this.hasVariants = true,
  });

  final bool requiresBatchNumber;
  final bool requiresExpiryDate;
  final bool requiresReason;
  final bool requiresUnitCost;
  final bool hasVariants;
}

class StockInFormValidator {
  const StockInFormValidator._();

  static Map<String, String> validate({
    required StockInFormData? data,
    required StockInValidationOptions options,
  }) {
    if (data == null) {
      return const {
        'productId': 'Product is required.',
      };
    }

    final errors = <String, String>{};

    if (data.productId.trim().isEmpty) {
      errors['productId'] = 'Product is required.';
    }

    if (options.hasVariants && data.variantId.trim().isEmpty) {
      errors['variantId'] = 'Variant is required.';
    }

    if (data.inventoryLocationId.trim().isEmpty) {
      errors['inventoryLocationId'] = 'Outlet / location is required.';
    }

    if (data.quantity <= 0) {
      errors['quantity'] = 'Quantity must be greater than 0.';
    }

    if (options.requiresUnitCost) {
      if (data.unitCost == null) {
        errors['unitCost'] = 'Unit cost is required.';
      } else if (data.unitCost! < 0) {
        errors['unitCost'] = 'Unit cost must be 0 or greater.';
      }
    } else if (data.unitCost != null && data.unitCost! < 0) {
      errors['unitCost'] = 'Unit cost must be 0 or greater.';
    }

    if (options.requiresBatchNumber && (data.batchNumber?.trim().isEmpty ?? true)) {
      errors['batchNumber'] = 'Batch number is required.';
    }

    if (options.requiresExpiryDate && data.expiryDate == null) {
      errors['expiryDate'] = 'Expiry date is required.';
    }

    if (data.manufacturedDate != null &&
        data.expiryDate != null &&
        data.expiryDate!.isBefore(data.manufacturedDate!)) {
      errors['expiryDate'] =
          'Expiry date must be on or after manufactured date.';
    }

    if (options.requiresReason && (data.reason?.trim().isEmpty ?? true)) {
      errors['reason'] = 'Reason is required.';
    }

    return errors;
  }

  static StockInValidationOptions defaultOptions({
    bool hasVariants = true,
  }) {
    return StockInValidationOptions(
      requiresBatchNumber: false,
      requiresExpiryDate: false,
      requiresReason: InventoryApiCapabilities.stockInReasons,
      requiresUnitCost: false,
      hasVariants: hasVariants,
    );
  }
}

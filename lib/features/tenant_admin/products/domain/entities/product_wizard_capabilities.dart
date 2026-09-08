import '../../../domain/services/tenant_admin_access_checker.dart';

class ProductWizardCapabilities {
  const ProductWizardCapabilities({
    required this.canViewProduct,
    required this.canCreateProduct,
    required this.canUpdateProduct,
    required this.canPublishProduct,
    required this.canManageProductMedia,
    required this.canManageProductChannels,
    required this.canManageVariants,
    required this.canManageBundleComponents,
    required this.canManageBarcodes,
    required this.canManagePricing,
    required this.canViewProductCost,
    required this.canLookupTaxClasses,
    required this.canViewStock,
    required this.canUseAdvancedInventoryTracking,
  });

  final bool canViewProduct;
  final bool canCreateProduct;
  final bool canUpdateProduct;
  final bool canPublishProduct;
  final bool canManageProductMedia;
  final bool canManageProductChannels;
  final bool canManageVariants;
  final bool canManageBundleComponents;
  final bool canManageBarcodes;
  final bool canManagePricing;
  final bool canViewProductCost;
  final bool canLookupTaxClasses;
  final bool canViewStock;
  final bool canUseAdvancedInventoryTracking;

  bool get canStartWizard =>
      canCreateProduct &&
      canManageBarcodes &&
      canManagePricing &&
      canLookupTaxClasses;

  factory ProductWizardCapabilities.fromAccess(TenantAdminAccessChecker access) {
    return ProductWizardCapabilities(
      canViewProduct:
          access.canViewProductDetail() || access.canAccessProductModule(),
      canCreateProduct: access.canCreateProduct(),
      canUpdateProduct: access.canUpdateProduct(),
      canPublishProduct: access.canPublishProduct(),
      canManageProductMedia: access.canManageProductMedia(),
      canManageProductChannels: access.canManageProductChannels(),
      canManageVariants: access.canManageVariants(),
      canManageBundleComponents: access.canManageBundleComponents(),
      canManageBarcodes: access.canManageBarcodes(),
      canManagePricing: access.canManagePricing(),
      canViewProductCost: access.canViewProductCost(),
      canLookupTaxClasses: access.canLookupTaxClasses(),
      canViewStock: access.canViewStockForProductSetup(),
      canUseAdvancedInventoryTracking: access.canUseAdvancedInventoryTracking(),
    );
  }
}

class InitialTrackingCompatibility {
  const InitialTrackingCompatibility._();

  static bool hasAnyValues({
    String? batch,
    DateTime? expiry,
    String? serial,
  }) {
    return (batch != null && batch.trim().isNotEmpty) ||
        expiry != null ||
        (serial != null && serial.trim().isNotEmpty);
  }

  static InitialTrackingClearPlan evaluate({
    required String productStructure,
    required bool trackInventory,
    required bool batchTracking,
    required bool expiryTracking,
    required bool serialTracking,
    String? batch,
    DateTime? expiry,
    String? serial,
  }) {
    final structure = productStructure.trim().toUpperCase();
    final keepBatch = _trimOrNull(batch);
    final keepSerial = _trimOrNull(serial);
    final isBundle = structure == 'BUNDLE';
    final quantityOnly = !trackInventory || isBundle;

    if (quantityOnly) {
      if (!hasAnyValues(batch: keepBatch, expiry: expiry, serial: keepSerial)) {
        return InitialTrackingClearPlan.unchanged(
            keepBatch, expiry, keepSerial);
      }
      return InitialTrackingClearPlan.requiresConfirmation(null, null, null);
    }

    if (serialTracking) {
      if (keepBatch != null || expiry != null) {
        return InitialTrackingClearPlan.requiresConfirmation(
            null, null, keepSerial);
      }
      return InitialTrackingClearPlan.unchanged(null, null, keepSerial);
    }

    if (batchTracking && expiryTracking) {
      if (keepSerial != null) {
        return InitialTrackingClearPlan.requiresConfirmation(
            keepBatch, expiry, null);
      }
      return InitialTrackingClearPlan.unchanged(keepBatch, expiry, null);
    }

    if (batchTracking) {
      if (expiry != null || keepSerial != null) {
        return InitialTrackingClearPlan.requiresConfirmation(
            keepBatch, null, null);
      }
      return InitialTrackingClearPlan.unchanged(keepBatch, null, null);
    }

    if (hasAnyValues(batch: keepBatch, expiry: expiry, serial: keepSerial)) {
      return InitialTrackingClearPlan.requiresConfirmation(null, null, null);
    }

    return InitialTrackingClearPlan.unchanged(keepBatch, expiry, keepSerial);
  }

  static String? _trimOrNull(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    return value.trim();
  }
}

class InitialTrackingClearPlan {
  const InitialTrackingClearPlan({
    required this.batchNumber,
    required this.expiryDate,
    required this.serialNumber,
    required this.requiresConfirmation,
  });

  final String? batchNumber;
  final DateTime? expiryDate;
  final String? serialNumber;
  final bool requiresConfirmation;

  factory InitialTrackingClearPlan.unchanged(
    String? batch,
    DateTime? expiry,
    String? serial,
  ) =>
      InitialTrackingClearPlan(
        batchNumber: batch,
        expiryDate: expiry,
        serialNumber: serial,
        requiresConfirmation: false,
      );

  factory InitialTrackingClearPlan.requiresConfirmation(
    String? batch,
    DateTime? expiry,
    String? serial,
  ) =>
      InitialTrackingClearPlan(
        batchNumber: batch,
        expiryDate: expiry,
        serialNumber: serial,
        requiresConfirmation: true,
      );
}

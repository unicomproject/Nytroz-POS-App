// ignore_for_file: unused_local_variable, unused_field, unused_element, prefer_const_literals_to_create_immutables, unused_import, use_super_parameters
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

  factory ProductWizardCapabilities.fromAccess(
      TenantAdminAccessChecker access) {
    return ProductWizardCapabilities(
      canViewProduct:
          access.canViewProductDetail() || access.canAccessProductModule(),
      canCreateProduct: access.canCreateProduct(),
      canUpdateProduct: access.canUpdateProduct(),
      canPublishProduct: access.canPublishProduct(),
      canManageProductMedia: access.canManageProductMedia(),
      canManageProductChannels: access.canManageProductChannels(),
      canManageVariants: access.canManageVariants(),
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
    /// When false (toggle edits), keep provisional values so the user can turn
    /// on matching Batch/Expiry/Serial rules. When true (Save & Continue),
    /// incompatible values require an explicit clear confirmation.
    bool forContinue = false,
  }) {
    final structure = productStructure.trim().toUpperCase();
    final keepBatch = _trimOrNull(batch);
    final keepSerial = _trimOrNull(serial);
    final skipTracking = !trackInventory && !batchTracking && !expiryTracking && !serialTracking;
    final quantityOnly = trackInventory && !batchTracking && !expiryTracking && !serialTracking;

    // If completely skipping tracking, clear all initial values
    if (skipTracking) {
      if (!hasAnyValues(batch: keepBatch, expiry: expiry, serial: keepSerial)) {
        return InitialTrackingClearPlan.unchanged(
            keepBatch, expiry, keepSerial);
      }
      return InitialTrackingClearPlan.requiresConfirmation(null, null, null);
    }

    if (quantityOnly) {
      // Keep provisional Initial Tracking values even when Track Inventory is
      // off or structure is BUNDLE — never prompt to wipe them on toggle/continue.
      return InitialTrackingClearPlan.unchanged(keepBatch, expiry, keepSerial);
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
      if (keepSerial != null) {
        return InitialTrackingClearPlan.requiresConfirmation(
          keepBatch,
          expiry,
          null,
        );
      }
      return InitialTrackingClearPlan.unchanged(keepBatch, expiry, null);
    }

    // Track Inventory on, specialized toggles off — keep all provisional values.
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

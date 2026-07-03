import 'package:flutter_test/flutter_test.dart';
import 'package:nytroz_pos/core/access/tenant_admin_access_codes.dart';
import 'package:nytroz_pos/features/tenant_admin/domain/entities/tenant_admin_context.dart';
import 'package:nytroz_pos/features/tenant_admin/domain/services/tenant_admin_access_checker.dart';
import 'package:nytroz_pos/features/tenant_admin/inventory/domain/entities/inventory.dart';
import 'package:nytroz_pos/features/tenant_admin/inventory/presentation/utils/stock_in_form_validator.dart';

void main() {
  group('StockInFormValidator', () {
    const validData = StockInFormData(
      productId: 'product-1',
      variantId: 'variant-1',
      inventoryLocationId: 'location-1',
      quantity: 10,
      unitCost: 5,
    );

    test('returns productId error when product is missing', () {
      final errors = StockInFormValidator.validate(
        data: const StockInFormData(
          productId: '',
          variantId: 'variant-1',
          inventoryLocationId: 'location-1',
          quantity: 10,
        ),
        options: StockInFormValidator.defaultOptions(),
      );

      expect(errors['productId'], isNotNull);
    });

    test('returns variantId error when variants are required', () {
      final errors = StockInFormValidator.validate(
        data: const StockInFormData(
          productId: 'product-1',
          variantId: '',
          inventoryLocationId: 'location-1',
          quantity: 10,
        ),
        options: StockInFormValidator.defaultOptions(hasVariants: true),
      );

      expect(errors['variantId'], isNotNull);
    });

    test('returns inventoryLocationId error when location is missing', () {
      final errors = StockInFormValidator.validate(
        data: const StockInFormData(
          productId: 'product-1',
          variantId: 'variant-1',
          inventoryLocationId: '',
          quantity: 10,
        ),
        options: StockInFormValidator.defaultOptions(),
      );

      expect(errors['inventoryLocationId'], isNotNull);
    });

    test('returns quantity error when quantity is zero', () {
      final errors = StockInFormValidator.validate(
        data: const StockInFormData(
          productId: 'product-1',
          variantId: 'variant-1',
          inventoryLocationId: 'location-1',
          quantity: 0,
        ),
        options: StockInFormValidator.defaultOptions(),
      );

      expect(errors['quantity'], 'Quantity must be greater than 0.');
    });

    test('returns unitCost error when unit cost is negative', () {
      final errors = StockInFormValidator.validate(
        data: const StockInFormData(
          productId: 'product-1',
          variantId: 'variant-1',
          inventoryLocationId: 'location-1',
          quantity: 2,
          unitCost: -1,
        ),
        options: StockInFormValidator.defaultOptions(),
      );

      expect(errors['unitCost'], 'Unit cost must be 0 or greater.');
    });

    test('returns expiryDate error when expiry is before manufactured date', () {
      final errors = StockInFormValidator.validate(
        data: StockInFormData(
          productId: 'product-1',
          variantId: 'variant-1',
          inventoryLocationId: 'location-1',
          quantity: 2,
          manufacturedDate: DateTime(2026, 6, 10),
          expiryDate: DateTime(2026, 6, 1),
        ),
        options: StockInFormValidator.defaultOptions(),
      );

      expect(
        errors['expiryDate'],
        'Expiry date must be on or after manufactured date.',
      );
    });

    test('returns no errors for valid stock-in data', () {
      final errors = StockInFormValidator.validate(
        data: validData,
        options: StockInFormValidator.defaultOptions(),
      );

      expect(errors, isEmpty);
    });
  });

  group('Inventory visibility', () {
    test('AddStockVisibility allows page with inventory.view but read-only', () {
      final access = _checker(
        permissions: [TenantAdminPermissionCodes.inventoryView],
        features: [
          TenantAdminFeatureCodes.inventoryManagement,
          TenantAdminFeatureCodes.productManagement,
        ],
      );

      final visibility = AddStockVisibility.resolve(access: access);
      expect(visibility.showPage, isTrue);
      expect(visibility.canEditFields, isFalse);
      expect(visibility.showSaveButton, isFalse);
    });

    test('AddStockVisibility enables form fields when adjust permission exists', () {
      final access = _checker(
        permissions: [TenantAdminPermissionCodes.inventoryStockAdjust],
        features: [
          TenantAdminFeatureCodes.inventoryManagement,
          TenantAdminFeatureCodes.productManagement,
        ],
      );

      final visibility = AddStockVisibility.resolve(access: access);
      expect(visibility.showPage, isTrue);
      expect(visibility.canEditFields, isTrue);
      expect(visibility.showProductSelect, isTrue);
    });

    test('AddStockVisibility hides page when inventory_management disabled', () {
      final access = _checker(
        permissions: [TenantAdminPermissionCodes.inventoryStockAdjust],
        features: [TenantAdminFeatureCodes.productManagement],
      );

      expect(AddStockVisibility.resolve(access: access).showPage, isFalse);
    });

    test('AddStockVisibility hides save when stock-in API is unavailable', () {
      final access = _checker(
        permissions: [TenantAdminPermissionCodes.inventoryStockAdjust],
        features: [TenantAdminFeatureCodes.inventoryManagement],
      );

      final visibility = AddStockVisibility.resolve(access: access);
      expect(visibility.showPage, isTrue);
      expect(visibility.showSaveButton, isFalse);
      expect(visibility.stockInApiAvailable, isFalse);
    });

    test('AddStockVisibility allows view-only page without adjust permission', () {
      final access = _checker(
        permissions: [TenantAdminPermissionCodes.inventoryStockView],
        features: [TenantAdminFeatureCodes.inventoryManagement],
      );

      final visibility = AddStockVisibility.resolve(access: access);
      expect(visibility.showPage, isTrue);
      expect(visibility.canEditFields, isFalse);
      expect(visibility.showSaveButton, isFalse);
    });

    test('CurrentStockVisibility hides export when export API is unavailable', () {
      final access = _checker(
        permissions: [TenantAdminPermissionCodes.inventoryStockView],
        features: [TenantAdminFeatureCodes.inventoryManagement],
      );

      final visibility = CurrentStockVisibility.resolve(access: access);
      expect(visibility.showPage, isTrue);
      expect(visibility.showExport, isFalse);
      expect(visibility.showFilters, isTrue);
    });

    test('CurrentStockVisibility hides page without view permission', () {
      final access = _checker(
        permissions: [],
        features: [TenantAdminFeatureCodes.inventoryManagement],
      );

      expect(CurrentStockVisibility.resolve(access: access).showPage, isFalse);
    });
  });
}

TenantAdminAccessChecker _checker({
  required List<String> permissions,
  required List<String> features,
}) {
  return TenantAdminAccessChecker(
    TenantAdminContext(
      tenantId: 'tenant-test',
      tenantName: 'Coffee Corner Ltd',
      userId: 'user-test',
      userDisplayName: 'Tenant Admin 001',
      roles: const [
        TenantAdminRoleScope(roleId: 'role-owner', roleName: 'Owner'),
      ],
      roleNames: const ['Owner'],
      outletScope: const [],
      featureEntitlements: [
        for (final featureCode in features)
          TenantAdminFeatureEntitlement(
            featureCode: featureCode,
            featureName: featureCode,
            enabled: true,
          ),
      ],
      permissions: [
        for (final permissionCode in permissions)
          TenantAdminPermission(
            permissionCode: permissionCode,
            permissionName: permissionCode,
          ),
      ],
      runtimeFlags: [
        for (final featureCode in features)
          TenantAdminRuntimeFlag(featureCode: featureCode, enabled: true),
      ],
    ),
  );
}

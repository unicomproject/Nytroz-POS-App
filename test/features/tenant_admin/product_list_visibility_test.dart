import 'package:flutter_test/flutter_test.dart';
import 'package:nytroz_pos/core/access/tenant_admin_access_codes.dart';
import 'package:nytroz_pos/features/tenant_admin/products/presentation/config/product_api_capabilities.dart';
import 'package:nytroz_pos/features/tenant_admin/domain/entities/tenant_admin_context.dart';
import 'package:nytroz_pos/features/tenant_admin/domain/services/tenant_admin_access_checker.dart';

void main() {
  group('ProductListVisibility', () {
    test('ProductsMenu_Hidden_WhenProductFeatureMissing', () {
      final access = _checker(
        permissions: [TenantAdminPermissionCodes.productView],
        features: [TenantAdminFeatureCodes.dashboard],
      );

      expect(access.canAccessProductModule(), isFalse);
      expect(
        ProductListVisibility.resolve(access: access).showPage,
        isFalse,
      );
    });

    test('ProductsMenu_Hidden_WhenProductViewPermissionMissing', () {
      final access = _checker(
        permissions: [TenantAdminPermissionCodes.tenantAdminDashboardView],
        features: [TenantAdminFeatureCodes.productManagement],
      );

      expect(access.canAccessProductModule(), isFalse);
      expect(
        ProductListVisibility.resolve(access: access).showPage,
        isFalse,
      );
    });

    test('ProductsMenu_Visible_WhenFeatureAndProductViewExist', () {
      final access = _checker(
        permissions: [TenantAdminPermissionCodes.productView],
        features: [TenantAdminFeatureCodes.productManagement],
      );

      final visibility = ProductListVisibility.resolve(access: access);

      expect(access.canAccessProductModule(), isTrue);
      expect(visibility.showPage, isTrue);
      expect(visibility.showList, isTrue);
    });

    test('AddProductButton_Hidden_WhenProductCreatePermissionMissing', () {
      final access = _checker(
        permissions: [TenantAdminPermissionCodes.productView],
        features: [TenantAdminFeatureCodes.productManagement],
      );

      expect(
        ProductListVisibility.resolve(access: access).showAddProduct,
        isFalse,
      );
    });

    test('AddProductButton_Visible_WhenProductCreatePermissionExists', () {
      final access = _checker(
        permissions: [
          TenantAdminPermissionCodes.productView,
          TenantAdminPermissionCodes.productCreate,
        ],
        features: [TenantAdminFeatureCodes.productManagement],
      );

      expect(
        ProductListVisibility.resolve(access: access).showAddProduct,
        isTrue,
      );
    });

    test('EditProductAction_Hidden_WhenUpdateApiMissing', () {
      final access = _checker(
        permissions: [
          TenantAdminPermissionCodes.productView,
          'catalog.product.update',
        ],
        features: [TenantAdminFeatureCodes.productManagement],
      );

      final visibility = ProductListVisibility.resolve(access: access);

      expect(ProductApiCapabilities.updateProduct, isFalse);
      expect(visibility.visibleRowActions, isEmpty);
      expect(visibility.showActionsColumn, isFalse);
    });

    test('EditProductAction_Hidden_WhenProductUpdatePermissionMissing', () {
      final access = _checker(
        permissions: [TenantAdminPermissionCodes.productView],
        features: [TenantAdminFeatureCodes.productManagement],
      );

      final visibility = ProductListVisibility.resolve(access: access);

      expect(visibility.visibleRowActions, isEmpty);
      expect(visibility.showActionsColumn, isFalse);
    });

    test('EditProductAction_Hidden_WhenProductUpdatePermissionExistsButApiMissing',
        () {
      final access = _checker(
        permissions: [
          TenantAdminPermissionCodes.productView,
          'catalog.product.update',
        ],
        features: [TenantAdminFeatureCodes.productManagement],
      );

      final visibility = ProductListVisibility.resolve(access: access);

      expect(visibility.visibleRowActions, isEmpty);
      expect(visibility.showActionsColumn, isFalse);
    });

    test('InventorySection_Visible_WhenTrackStockCreateApiExists', () {
      final access = _checker(
        permissions: [
          TenantAdminPermissionCodes.productCreate,
        ],
        features: [TenantAdminFeatureCodes.productManagement],
      );

      expect(
        AddProductFormVisibility.resolve(access: access).showInventorySection,
        isTrue,
      );
    });

    test('VariantSection_Hidden_WhenVariantCreateApiMissing', () {
      final access = _checker(
        permissions: [
          TenantAdminPermissionCodes.productCreate,
          'catalog.product.update',
        ],
        features: [TenantAdminFeatureCodes.productManagement],
      );

      expect(
        AddProductFormVisibility.resolve(access: access).showVariantSection,
        isFalse,
      );
    });

    test('ExpirySection_Hidden_WhenExpiryCreateApiMissing', () {
      final access = _checker(
        permissions: [TenantAdminPermissionCodes.productCreate],
        features: [TenantAdminFeatureCodes.productManagement],
      );

      expect(
        AddProductFormVisibility.resolve(access: access).showExpirySection,
        isFalse,
      );
    });

    test('TopSellingProducts_Hidden_WhenReportApiMissing', () {
      final access = _checker(
        permissions: [TenantAdminPermissionCodes.productView],
        features: [TenantAdminFeatureCodes.productManagement],
      );

      expect(
        ProductListVisibility.resolve(access: access).showTopSelling,
        isFalse,
      );
    });

    test('ProductsMenu_Visible_WhenMatrixPermissionCodeExists', () {
      final access = _checker(
        permissions: [TenantAdminPermissionCodes.catalogProductsView],
        features: [TenantAdminFeatureCodes.productManagement],
      );

      expect(access.canAccessProductModule(), isTrue);
      expect(
        ProductListVisibility.resolve(access: access).showPage,
        isTrue,
      );
    });

    test('ImportCsv_Hidden_WhenImportApiMissing', () {
      final access = _checker(
        permissions: [
          TenantAdminPermissionCodes.catalogProductsView,
          TenantAdminPermissionCodes.tenantProductImport,
        ],
        features: [TenantAdminFeatureCodes.productManagement],
      );

      expect(
        ProductListVisibility.resolve(access: access).showImportCsv,
        isFalse,
      );
    });

    test('VariantStep_Hidden_WhenVariantPermissionMissing', () {
      final access = _checker(
        permissions: [TenantAdminPermissionCodes.catalogProductsCreate],
        features: [TenantAdminFeatureCodes.productManagement],
      );

      expect(
        AddProductFormVisibility.resolve(access: access).showVariantSection,
        isFalse,
      );
    });

    test('CurrentStockPage_Visible_WhenPermissionExists_EvenIfBalancesApiMissing', () {
      final access = _checker(
        permissions: [
          TenantAdminPermissionCodes.inventoryStockView,
        ],
        features: [TenantAdminFeatureCodes.inventoryManagement],
      );

      final visibility = CurrentStockVisibility.resolve(access: access);
      expect(visibility.showPage, isTrue);
      expect(visibility.balancesApiAvailable, isFalse);
      expect(visibility.showSummaryCards, isFalse);
      expect(visibility.showTable, isFalse);
    });

    test('ExpiryAlertsPage_Hidden_WhenAlertsApiMissing', () {
      final access = _checker(
        permissions: [TenantAdminPermissionCodes.inventoryAlertsView],
        features: [TenantAdminFeatureCodes.inventoryManagement],
      );

      expect(ExpiryAlertsVisibility.resolve(access: access).showPage, isFalse);
    });

    test('ProductImageSection_Visible_WhenCreatePermissionExists', () {
      final access = _checker(
        permissions: [TenantAdminPermissionCodes.productCreate],
        features: [TenantAdminFeatureCodes.productManagement],
      );

      expect(
        AddProductFormVisibility.resolve(access: access).showImageSection,
        isTrue,
      );
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

import 'package:flutter_test/flutter_test.dart';
import 'package:nytroz_pos/core/access/tenant_admin_access_codes.dart';
import 'package:nytroz_pos/features/tenant_admin/domain/entities/tenant_admin_context.dart';
import 'package:nytroz_pos/features/tenant_admin/domain/services/tenant_admin_access_checker.dart';

void main() {
  group('TillListVisibility', () {
    test('TillsMenu_Hidden_WhenTillManagementFeatureMissing', () {
      final access = _checker(
        permissions: [TenantAdminPermissionCodes.tillView],
        features: [TenantAdminFeatureCodes.dashboard],
      );

      expect(access.canAccessTillModule(), isFalse);
      expect(
        TillListVisibility.resolve(access: access).showPage,
        isFalse,
      );
    });

    test('TillsMenu_Hidden_WhenTillViewPermissionMissing', () {
      final access = _checker(
        permissions: [TenantAdminPermissionCodes.tenantAdminDashboardView],
        features: [TenantAdminFeatureCodes.tillManagement],
      );

      expect(access.canAccessTillModule(), isFalse);
      expect(
        TillListVisibility.resolve(access: access).showPage,
        isFalse,
      );
    });

    test('TillsMenu_Visible_WhenFeatureAndTillViewExist', () {
      final access = _checker(
        permissions: [TenantAdminPermissionCodes.tillView],
        features: [TenantAdminFeatureCodes.tillManagement],
      );

      final visibility = TillListVisibility.resolve(access: access);

      expect(access.canAccessTillModule(), isTrue);
      expect(visibility.showPage, isTrue);
      expect(visibility.showList, isTrue);
    });

    test('AddTillButton_Hidden_WhenTillCreatePermissionMissing', () {
      final access = _checker(
        permissions: [TenantAdminPermissionCodes.tillView],
        features: [TenantAdminFeatureCodes.tillManagement],
      );

      expect(
        TillListVisibility.resolve(access: access).showAddTill,
        isFalse,
      );
    });

    test('AddTillButton_Visible_WhenTillCreatePermissionExists', () {
      final access = _checker(
        permissions: [
          TenantAdminPermissionCodes.tillView,
          TenantAdminPermissionCodes.tillCreate,
        ],
        features: [TenantAdminFeatureCodes.tillManagement],
      );

      expect(
        TillListVisibility.resolve(access: access).showAddTill,
        isTrue,
      );
    });

    test('EditButton_Hidden_WhenTillUpdatePermissionMissing', () {
      final access = _checker(
        permissions: [TenantAdminPermissionCodes.tillView],
        features: [TenantAdminFeatureCodes.tillManagement],
      );

      final visibility = TillListVisibility.resolve(access: access);

      expect(
        visibility.visibleRowActions.any((action) => action.id == 'edit'),
        isFalse,
      );
    });

    test('EditButton_Visible_WhenTillUpdatePermissionExists', () {
      final access = _checker(
        permissions: [
          TenantAdminPermissionCodes.tillView,
          TenantAdminPermissionCodes.tillUpdate,
        ],
        features: [TenantAdminFeatureCodes.tillManagement],
      );

      final visibility = TillListVisibility.resolve(access: access);

      expect(
        visibility.visibleRowActions.any((action) => action.id == 'edit'),
        isTrue,
      );
    });

    test('MoreMenu_Hidden_WhenNoPermittedActionsExist', () {
      final access = _checker(
        permissions: [TenantAdminPermissionCodes.tillView],
        features: [TenantAdminFeatureCodes.tillManagement],
      );

      expect(
        TillListVisibility.resolve(access: access).showMoreMenu,
        isFalse,
      );
    });

    test('DeleteAction_Visible_OnlyWithTillDeletePermission', () {
      final withDelete = _checker(
        permissions: [
          TenantAdminPermissionCodes.tillView,
          TenantAdminPermissionCodes.tillDelete,
        ],
        features: [TenantAdminFeatureCodes.tillManagement],
      );
      final withoutDelete = _checker(
        permissions: [TenantAdminPermissionCodes.tillView],
        features: [TenantAdminFeatureCodes.tillManagement],
      );

      expect(
        TillListVisibility.resolve(access: withDelete)
            .visibleMoreMenuActions
            .any((action) => action.id == 'delete'),
        isTrue,
      );
      expect(
        TillListVisibility.resolve(access: withoutDelete)
            .visibleMoreMenuActions
            .any((action) => action.id == 'delete'),
        isFalse,
      );
    });

    test('ActivationCodeAction_Visible_OnlyWithActivationPermission', () {
      final withActivation = _checker(
        permissions: [
          TenantAdminPermissionCodes.tillView,
          TenantAdminPermissionCodes.tillActivationCodeGenerate,
        ],
        features: [TenantAdminFeatureCodes.tillManagement],
      );
      final withoutActivation = _checker(
        permissions: [TenantAdminPermissionCodes.tillView],
        features: [TenantAdminFeatureCodes.tillManagement],
      );

      expect(
        TillListVisibility.resolve(access: withActivation)
            .visibleMoreMenuActions
            .any((action) => action.id == 'activation_code'),
        isTrue,
      );
      expect(
        TillListVisibility.resolve(access: withoutActivation)
            .visibleMoreMenuActions
            .any((action) => action.id == 'activation_code'),
        isFalse,
      );
    });

    test('TodaySales_Hidden_WhenSalesPermissionMissing', () {
      final access = _checker(
        permissions: [TenantAdminPermissionCodes.tillView],
        features: [TenantAdminFeatureCodes.tillManagement],
      );

      expect(
        TillListVisibility.resolve(access: access).showTodaySales,
        isFalse,
      );
    });

    test('TodaySales_Visible_WhenSalesPermissionExists', () {
      final access = _checker(
        permissions: [
          TenantAdminPermissionCodes.tillView,
          'sales.summary.view',
        ],
        features: [TenantAdminFeatureCodes.tillManagement],
      );

      expect(
        TillListVisibility.resolve(access: access).showTodaySales,
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
      userDisplayName: 'Sarah Ahmed',
      roleNames: const ['Owner'],
      outletScope: const [
        TenantAdminOutletScope(
          outletId: 'outlet-1',
          outletName: 'High Street Store',
          isDefault: true,
        ),
      ],
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

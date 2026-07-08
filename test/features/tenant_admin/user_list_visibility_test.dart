import 'package:flutter_test/flutter_test.dart';
import 'package:nytroz_pos/core/access/tenant_admin_access_codes.dart';
import 'package:nytroz_pos/features/tenant_admin/domain/entities/tenant_admin_context.dart';
import 'package:nytroz_pos/features/tenant_admin/domain/services/tenant_admin_access_checker.dart';

void main() {
  group('UserListVisibility', () {
    test(
        'UsersMenu_Visible_WhenUserViewPermissionExists_WithoutExplicitFeatureEntitlement',
        () {
      // No explicit feature-entitlement data should not hard-block access;
      // it falls back to permission-based checks, consistent with every
      // other tenant admin module (dashboard, outlets, tills, etc.).
      final access = _checker(
        permissions: [TenantAdminPermissionCodes.tenantUsersView],
        features: [TenantAdminFeatureCodes.dashboard],
      );

      expect(access.canAccessUserModule(), isTrue);
      expect(
        UserListVisibility.resolve(access: access).showPage,
        isTrue,
      );
    });

    test('UsersMenu_Hidden_WhenUserViewPermissionMissing', () {
      final access = _checker(
        permissions: [TenantAdminPermissionCodes.tenantAdminDashboardView],
        features: [TenantAdminFeatureCodes.staffManagement],
      );

      expect(access.canAccessUserModule(), isFalse);
      expect(
        UserListVisibility.resolve(access: access).showPage,
        isFalse,
      );
    });

    test('UsersMenu_Visible_WhenFeatureAndUserViewExist', () {
      final access = _checker(
        permissions: [TenantAdminPermissionCodes.tenantUsersView],
        features: [TenantAdminFeatureCodes.staffManagement],
      );

      final visibility = UserListVisibility.resolve(access: access);

      expect(access.canAccessUserModule(), isTrue);
      expect(visibility.showPage, isTrue);
      expect(visibility.showList, isTrue);
    });

    test('AddUserButton_Hidden_WhenCreateAndInvitePermissionsMissing', () {
      final access = _checker(
        permissions: [TenantAdminPermissionCodes.tenantUsersView],
        features: [TenantAdminFeatureCodes.staffManagement],
      );

      expect(
        UserListVisibility.resolve(access: access).showAddUser,
        isFalse,
      );
    });

    test('AddUserButton_Visible_WhenUserCreatePermissionExists', () {
      final access = _checker(
        permissions: [
          TenantAdminPermissionCodes.tenantUsersView,
          TenantAdminPermissionCodes.tenantUsersCreate,
        ],
        features: [TenantAdminFeatureCodes.staffManagement],
      );

      expect(
        UserListVisibility.resolve(access: access).showAddUser,
        isTrue,
      );
    });

    test('AddUserButton_Visible_WhenUserInvitePermissionExists', () {
      final access = _checker(
        permissions: [
          TenantAdminPermissionCodes.tenantUsersView,
          TenantAdminPermissionCodes.tenantUsersInvite,
        ],
        features: [TenantAdminFeatureCodes.staffManagement],
      );

      expect(
        UserListVisibility.resolve(access: access).showAddUser,
        isTrue,
      );
    });

    test('EditAction_Hidden_WhenUserUpdatePermissionMissing', () {
      final access = _checker(
        permissions: [TenantAdminPermissionCodes.tenantUsersView],
        features: [TenantAdminFeatureCodes.staffManagement],
      );

      final visibility = UserListVisibility.resolve(access: access);

      expect(
        visibility.visibleRowActions.any((action) => action.id == 'edit'),
        isFalse,
      );
    });

    test('EditAction_Visible_WhenUserUpdatePermissionExists', () {
      final access = _checker(
        permissions: [
          TenantAdminPermissionCodes.tenantUsersView,
          TenantAdminPermissionCodes.tenantUsersUpdate,
        ],
        features: [TenantAdminFeatureCodes.staffManagement],
      );

      final visibility = UserListVisibility.resolve(access: access);

      expect(
        visibility.visibleRowActions.any((action) => action.id == 'edit'),
        isTrue,
      );
    });

    test('DeleteAction_Visible_OnlyWithUserDeletePermission', () {
      final withDelete = _checker(
        permissions: [
          TenantAdminPermissionCodes.tenantUsersView,
          TenantAdminPermissionCodes.tenantUsersDelete,
        ],
        features: [TenantAdminFeatureCodes.staffManagement],
      );
      final withoutDelete = _checker(
        permissions: [TenantAdminPermissionCodes.tenantUsersView],
        features: [TenantAdminFeatureCodes.staffManagement],
      );

      expect(
        UserListVisibility.resolve(access: withDelete)
            .visibleRowActions
            .any((action) => action.id == 'delete'),
        isTrue,
      );
      expect(
        UserListVisibility.resolve(access: withoutDelete)
            .visibleRowActions
            .any((action) => action.id == 'delete'),
        isFalse,
      );
    });

    test('ViewDetailsAction_Visible_OnlyWithViewPermission', () {
      final access = _checker(
        permissions: [TenantAdminPermissionCodes.tenantUsersView],
        features: [TenantAdminFeatureCodes.staffManagement],
      );

      final visibility = UserListVisibility.resolve(access: access);

      expect(
        visibility.visibleRowActions
            .any((action) => action.id == 'view_details'),
        isTrue,
      );
    });

    test('PermissionOverride_HiddenByDefault_RequiresExplicitPermission', () {
      final access = _checker(
        permissions: [
          TenantAdminPermissionCodes.tenantUsersView,
          TenantAdminPermissionCodes.tenantUsersCreate,
        ],
        features: [TenantAdminFeatureCodes.staffManagement],
      );

      expect(access.canOverrideUserPermissions(), isFalse);

      final withOverride = _checker(
        permissions: [
          TenantAdminPermissionCodes.tenantUsersView,
          TenantAdminPermissionCodes.tenantUsersCreate,
          TenantAdminPermissionCodes.tenantUsersPermissionOverride,
        ],
        features: [TenantAdminFeatureCodes.staffManagement],
      );

      expect(withOverride.canOverrideUserPermissions(), isTrue);
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
      roles: const [
        TenantAdminRoleScope(roleId: 'role-1', roleName: 'Owner'),
      ],
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

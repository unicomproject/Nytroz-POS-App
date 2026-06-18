import 'package:flutter_test/flutter_test.dart';
import 'package:nytroz_pos/core/access/tenant_admin_access_codes.dart';
import 'package:nytroz_pos/features/tenant_admin/domain/entities/tenant_admin_context.dart';
import 'package:nytroz_pos/features/tenant_admin/domain/entities/tenant_admin_menu_item.dart';
import 'package:nytroz_pos/features/tenant_admin/domain/services/tenant_admin_access_checker.dart';

void main() {
  group('Tenant admin navigation access', () {
    test('user with tenant_admin.dashboard.view can access dashboard route', () {
      final access = _access(
        permissions: [TenantAdminPermissionCodes.tenantAdminDashboardView],
        features: [TenantAdminFeatureCodes.dashboard],
      );

      expect(access.canAccessDashboardRoute(), isTrue);
    });

    test('user without tenant_admin.dashboard.view cannot access dashboard route',
        () {
      final access = _access(
        permissions: [TenantAdminPermissionCodes.outletView],
        features: [TenantAdminFeatureCodes.outletManagement],
      );

      expect(access.canAccessDashboardRoute(), isFalse);
    });

    test('sidebar menu excludes dashboard without tenant_admin.dashboard.view', () {
      final access = _access(
        permissions: [TenantAdminPermissionCodes.outletView],
        features: [TenantAdminFeatureCodes.outletManagement],
      );

      final visibleItems =
          _menuItems.where(access.canAccessMenuItem).toList(growable: false);

      expect(visibleItems.any((item) => item.key == 'dashboard'), isFalse);
      expect(visibleItems.any((item) => item.key == 'outlets'), isTrue);
    });

    test('first permitted route is outlets when dashboard is denied', () {
      final access = _access(
        permissions: [TenantAdminPermissionCodes.outletView],
        features: [TenantAdminFeatureCodes.outletManagement],
      );

      final visibleItems =
          _menuItems.where(access.canAccessMenuItem).toList(growable: false)
            ..sort((first, second) => first.order.compareTo(second.order));

      expect(visibleItems.first.route, '/tenant-admin/outlets');
    });
  });
}

TenantAdminAccessChecker _access({
  required List<String> permissions,
  required List<String> features,
}) {
  return TenantAdminAccessChecker(
    TenantAdminContext(
      tenantId: 'tenant-test',
      tenantName: 'Coffee Corner Ltd',
      userId: 'user-test',
      userDisplayName: 'Sarah Ahmed',
      roleNames: ['Owner'],
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

const _menuItems = [
  TenantAdminMenuItem(
    key: 'dashboard',
    label: 'Dashboard',
    route: '/tenant-admin/dashboard',
    iconKey: 'dashboard',
    featureCode: TenantAdminFeatureCodes.dashboard,
    permissionCode: TenantAdminPermissionCodes.tenantAdminDashboardView,
    visible: true,
    order: 1,
  ),
  TenantAdminMenuItem(
    key: 'outlets',
    label: 'Outlets',
    route: '/tenant-admin/outlets',
    iconKey: 'store',
    featureCode: TenantAdminFeatureCodes.outletManagement,
    permissionCode: TenantAdminPermissionCodes.outletView,
    visible: true,
    order: 2,
  ),
];

import 'package:flutter_test/flutter_test.dart';
import 'package:nytroz_pos/core/access/tenant_admin_access_codes.dart';
import 'package:nytroz_pos/features/tenant_admin/data/catalog/tenant_admin_menu_catalog.dart';
import 'package:nytroz_pos/features/tenant_admin/domain/entities/tenant_admin_context.dart';
import 'package:nytroz_pos/features/tenant_admin/domain/services/tenant_admin_access_checker.dart';

void main() {
  test('tenant.outlets.manage shows Outlets menu and create action', () {
    const context = TenantAdminContext(
      tenantId: 'tenant-1',
      tenantName: 'SCS-TIX',
      userId: 'user-1',
      userDisplayName: 'Tenant Admin',
      roles: [],
      roleNames: ['Tenant Admin'],
      outletScope: [],
      featureEntitlements: [],
      permissions: [
        TenantAdminPermission(
          permissionCode: 'tenant.outlets.manage',
          permissionName: 'Manage Outlets',
        ),
        TenantAdminPermission(
          permissionCode: 'tenant.dashboard.view',
          permissionName: 'View Tenant Dashboard',
        ),
      ],
      runtimeFlags: [],
    );

    const access = TenantAdminAccessChecker(context);
    final outletsMenu = tenantAdminMenuCatalog.firstWhere(
      (item) => item.key == 'outlets',
    );

    expect(access.canAccessFeature(TenantAdminFeatureCodes.outletManagement),
        isTrue);
    expect(access.can(TenantAdminPermissionCodes.outletView), isTrue);
    expect(access.canCreateOutlet(), isTrue);
    expect(access.canAccessMenuItem(outletsMenu), isTrue);
  });
}

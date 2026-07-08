import 'package:flutter_test/flutter_test.dart';
import 'package:nytroz_pos/features/tenant_admin/dashboard/data/mappers/tenant_dashboard_mapper.dart';
import 'package:nytroz_pos/features/tenant_admin/dashboard/data/catalog/tenant_admin_dashboard_catalog.dart';
import 'package:nytroz_pos/features/tenant_admin/domain/entities/tenant_admin_context.dart';
import 'package:nytroz_pos/features/tenant_admin/domain/services/tenant_admin_access_checker.dart';

void main() {
  test('tenant.dashboard.view shows dashboard widgets from catalog fallback', () {
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
          permissionCode: 'tenant.dashboard.view',
          permissionName: 'View Tenant Dashboard',
        ),
        TenantAdminPermission(
          permissionCode: 'tenant.settings.manage',
          permissionName: 'Manage Tenant Settings',
        ),
      ],
      runtimeFlags: [],
    );

    final access = TenantAdminAccessChecker(context);
    final dashboard = tenantAdminDashboardCatalogFallback.toEntity();
    final visibility = TenantDashboardVisibility.resolve(
      access: access,
      dashboard: dashboard,
    );

    expect(access.canLoadDashboardData(), isTrue);
    expect(visibility.showTitle, isTrue);
    expect(visibility.showKpiSection, isTrue);
    expect(visibility.visibleMetrics, isNotEmpty);
    expect(visibility.showQuickActionsSection, isTrue);
    expect(visibility.showNeedsAttentionSection, isTrue);
  });
}

import '../../../../../core/access/tenant_admin_access_codes.dart';
import 'dashboard_permission_config.dart';

const dashboardQuickActionConfigs = <DashboardWidgetPermissionConfig>[
  DashboardWidgetPermissionConfig(
    id: 'add-outlet',
    permission: TenantAdminPermissionCodes.outletCreate,
    legacyIds: ['add_outlet'],
  ),
  DashboardWidgetPermissionConfig(
    id: 'add-till',
    permission: TenantAdminPermissionCodes.tillCreate,
    legacyIds: ['add_till'],
  ),
  DashboardWidgetPermissionConfig(
    id: 'add-staff',
    permissionsAny: [
      TenantAdminPermissionCodes.userCreate,
      TenantAdminPermissionCodes.userInviteCreate,
    ],
    legacyIds: ['add_staff'],
  ),
  DashboardWidgetPermissionConfig(
    id: 'add-product',
    permission: TenantAdminPermissionCodes.productCreate,
    legacyIds: ['add_product'],
  ),
  DashboardWidgetPermissionConfig(
    id: 'view-reports',
    permission: TenantAdminPermissionCodes.reportView,
    legacyIds: ['view_reports'],
  ),
];

DashboardWidgetPermissionConfig? quickActionConfigForKey(String key) {
  return findDashboardWidgetConfig(key, dashboardQuickActionConfigs);
}

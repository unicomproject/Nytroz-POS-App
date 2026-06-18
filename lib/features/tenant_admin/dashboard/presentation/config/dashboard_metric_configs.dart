import '../../../../../core/access/tenant_admin_access_codes.dart';
import 'dashboard_permission_config.dart';

const dashboardMetricConfigs = <DashboardWidgetPermissionConfig>[
  DashboardWidgetPermissionConfig(
    id: 'sales',
    permission: TenantAdminPermissionCodes.dashboardSalesSummaryView,
    legacyIds: ['todays_sales'],
  ),
  DashboardWidgetPermissionConfig(
    id: 'orders',
    permission: TenantAdminPermissionCodes.dashboardOrdersSummaryView,
  ),
  DashboardWidgetPermissionConfig(
    id: 'outlets',
    permission: TenantAdminPermissionCodes.dashboardOutletSummaryView,
    legacyIds: ['active_outlets'],
  ),
  DashboardWidgetPermissionConfig(
    id: 'stock',
    permission: TenantAdminPermissionCodes.dashboardStockAlertsView,
    legacyIds: ['stock_alerts'],
  ),
  DashboardWidgetPermissionConfig(
    id: 'tills',
    permission: TenantAdminPermissionCodes.dashboardTillStatusView,
  ),
];

DashboardWidgetPermissionConfig? metricConfigForKey(String key) {
  return findDashboardWidgetConfig(key, dashboardMetricConfigs);
}

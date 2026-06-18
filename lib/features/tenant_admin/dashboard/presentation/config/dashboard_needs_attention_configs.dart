import '../../../../../core/access/tenant_admin_access_codes.dart';
import 'dashboard_permission_config.dart';

const dashboardNeedsAttentionConfigs = <DashboardWidgetPermissionConfig>[
  DashboardWidgetPermissionConfig(
    id: 'offline_tills',
    permission: TenantAdminPermissionCodes.tillStatusView,
  ),
  DashboardWidgetPermissionConfig(
    id: 'low_stock',
    permission: TenantAdminPermissionCodes.inventoryAlertView,
  ),
  DashboardWidgetPermissionConfig(
    id: 'pending_invites',
    permission: TenantAdminPermissionCodes.userInviteView,
  ),
  DashboardWidgetPermissionConfig(
    id: 'payment_due',
    permissionsAny: [
      TenantAdminPermissionCodes.billingView,
      TenantAdminPermissionCodes.subscriptionView,
    ],
  ),
];

DashboardWidgetPermissionConfig? needsAttentionConfigForKey(String key) {
  return findDashboardWidgetConfig(key, dashboardNeedsAttentionConfigs);
}

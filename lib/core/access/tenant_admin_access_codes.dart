class TenantAdminFeatureCodes {
  const TenantAdminFeatureCodes._();

  static const dashboard = 'tenant_admin.dashboard';
  static const outletManagement = 'tenant_admin.outlets';
  static const tillManagement = 'tenant.tills';
  static const staffManagement = 'tenant.users';
  static const rolePermission = 'tenant.roles';
  static const productManagement = 'catalog.product';
  static const inventoryManagement = 'inventory.stock';
  static const reportsAnalytics = 'reports';
  static const sales = 'sales';
  static const billingSubscription = 'subscription.billing';
  static const tenantSettings = 'tenant.settings';
  static const activityAudit = 'tenant.activity';
  static const support = 'support';
}

class TenantAdminPermissionCodes {
  const TenantAdminPermissionCodes._();

  // Page access
  static const tenantAdminDashboardView = 'tenant_admin.dashboard.view';

  // Dashboard widgets
  static const dashboardSalesSummaryView = 'dashboard.sales_summary.view';
  static const dashboardOrdersSummaryView = 'dashboard.orders_summary.view';
  static const dashboardOutletSummaryView = 'dashboard.outlet_summary.view';
  static const dashboardStockAlertsView = 'dashboard.stock_alerts.view';
  static const dashboardTillStatusView = 'dashboard.till_status.view';
  static const dashboardSalesChartView = 'dashboard.sales_chart.view';
  static const dashboardAttentionView = 'dashboard.attention.view';
  static const dashboardAttentionViewAll = 'dashboard.attention.view_all';
  static const dashboardFilterDate = 'dashboard.filter.date';
  static const dashboardFilterOutlet = 'dashboard.filter.outlet';

  // Module navigation
  static const outletView = 'outlet.view';
  static const outletCreate = 'outlet.create';
  static const outletSummaryView = 'outlet.summary.view';
  static const outletLocationSummaryView = 'outlet.location_summary.view';
  static const outletFilterView = 'outlet.filter.view';
  static const outletDetailView = 'outlet.detail.view';
  static const outletLocationView = 'outlet.location.view';
  static const outletStatusView = 'outlet.status.view';
  static const outletSalesSummaryView = 'outlet.sales_summary.view';
  static const outletTillSummaryView = 'outlet.till_summary.view';
  static const outletStaffSummaryView = 'outlet.staff_summary.view';
  static const outletUpdate = 'outlet.update';
  static const outletStatusUpdate = 'outlet.status.update';
  static const outletDelete = 'outlet.delete';
  static const tillView = 'till.view';
  static const tillCreate = 'till.create';
  static const tillUpdate = 'till.update';
  static const tillDelete = 'till.delete';
  static const tillActivationCodeGenerate = 'till.activation_code.generate';
  static const tillStatusView = 'till.status.view';
  static const userView = 'user.view';
  static const userCreate = 'user.create';
  static const userInviteView = 'user.invite.view';
  static const userInviteCreate = 'user.invite.create';
  static const roleView = 'role.view';
  static const permissionView = 'permission.view';
  static const productView = 'product.view';
  static const productCreate = 'product.create';
  static const inventoryView = 'inventory.view';
  static const inventoryAlertView = 'inventory.alert.view';
  static const reportView = 'report.view';
  static const reportSalesView = 'report.sales.view';
  static const billingView = 'billing.view';
  static const subscriptionView = 'subscription.view';
  static const tenantSettingsView = 'tenant_settings.view';
  static const activityLogView = 'activity_log.view';
  static const activityLogDetailView = 'activity_log.detail.view';
  static const supportView = 'support.view';
  static const notificationView = 'notification.view';
  static const notificationRead = 'notification.read';
  static const tenantContextView = 'tenant.context.view';
  static const profileView = 'profile.view';

  // Legacy codes retained for backward compatibility with existing API responses.
  static const dashboardView = tenantAdminDashboardView;
  static const dashboardSummaryView = 'dashboard.summary.view';
  static const dashboardAlertsView = dashboardAttentionView;
  static const salesSummaryView = dashboardSalesSummaryView;
  static const salesOrdersView = dashboardOrdersSummaryView;
  static const ordersView = dashboardOrdersSummaryView;
  static const analyticsSalesView = dashboardSalesChartView;
  static const analyticsSalesTrendView = dashboardSalesChartView;
  static const outletsView = outletView;
  static const outletsCreate = outletCreate;
  static const outletsUpdate = outletUpdate;
  static const outletsActivityView = activityLogView;
  static const tillsView = tillView;
  static const tillsCreate = tillCreate;
  static const tillsStatusView = tillStatusView;
  static const usersView = userView;
  static const usersCreate = userCreate;
  static const usersInvite = userInviteCreate;
  static const usersInvitesView = userInviteView;
  static const usersActivityView = activityLogView;
  static const rolesView = roleView;
  static const permissionsView = permissionView;
  static const productsView = productView;
  static const productsCreate = productCreate;
  static const inventoryStockAlertsView = dashboardStockAlertsView;
  static const inventoryActivityView = activityLogView;
  static const reportsView = reportView;
  static const reportsSalesView = reportSalesView;
  static const subscriptionBillingView = subscriptionView;
  static const activityView = activityLogView;
  static const auditLogsView = activityLogView;
  static const notificationsView = notificationView;
  static const settingsView = tenantSettingsView;
  static const tenantTillManage = 'tenant.till.manage';
  static const tenantUserManage = 'tenant.user.manage';
  static const tenantRoleManage = 'tenant.role.manage';
  static const catalogProductView = 'catalog.product.view';
  static const catalogProductCreate = 'catalog.product.create';
  static const tenantBillingView = 'tenant.billing.view';
  static const tenantSettingsManage = 'tenant.settings.manage';
  static const tenantActivityView = 'tenant.activity.view';
}

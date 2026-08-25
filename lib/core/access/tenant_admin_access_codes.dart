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
  static const onlineStore = 'online_store';
  static const clickCollect = 'click_collect';
  static const billingSubscription = 'subscription.billing';
  static const tenantSettings = 'tenant.settings';
  static const activityAudit = 'tenant.activity';
  static const support = 'support';
}

class TenantAdminPermissionCodes {
  const TenantAdminPermissionCodes._();

  static const tenantStockOpening = 'tenant.stock.opening';

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
  static const rolesPermissionsView = 'roles.permissions.view';
  static const rolesPermissionsUpdate = 'roles.permissions.update';
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

  // Tenant Admin Online Store
  static const onlineStoreView = 'tenant.online_store.view';
  static const onlineStoreManage = 'tenant.online_store.manage';
  static const onlineStorePublish = 'tenant.online_store.publish';
  static const onlineStoreDomainsManage = 'tenant.online_store.domains.manage';
  static const onlineStoreBrandingManage =
      'tenant.online_store.branding.manage';
  static const onlineStoreSupportManage = 'tenant.online_store.support.manage';
  static const onlineStoreFulfillmentManage =
      'tenant.online_store.fulfillment.manage';
  static const onlineStoreCatalogManage = 'tenant.online_store.catalog.manage';
  static const onlineStorePoliciesManage =
      'tenant.online_store.policies.manage';

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
  static const tenantRolesCreate = 'tenant.roles.create';
  static const tenantOutletsView = 'tenant.outlets.view';
  static const tenantOutletsManage = 'tenant.outlets.manage';
  static const tenantOutletsDetailsView = 'tenant.outlets.details.view';
  static const tenantOutletsRevenueView = 'tenant.outlets.revenue.view';
  static const tenantOutletsUsersView = 'tenant.outlets.users.view';
  static const tenantOutletsTillsView = 'tenant.outlets.tills.view';
  static const tenantOutletsUpdate = 'tenant.outlets.update';
  static const tenantUsersView = 'tenant.users.view';
  static const tenantUsersCreate = 'tenant.users.create';
  static const tenantUsersInvite = 'tenant.users.invite';
  static const tenantUsersUpdate = 'tenant.users.update';
  static const tenantUsersDelete = 'tenant.users.delete';
  static const tenantUsersDisable = 'tenant.users.disable';
  static const tenantUsersDetailsView = 'tenant.users.details.view';
  static const tenantUsersPermissionOverride =
      'tenant.users.permission_override';
  static const tenantRolesView = 'tenant.roles.view';
  static const tenantPermissionsView = 'tenant.permissions.view';
  static const tenantProductsView = 'tenant.products.view';
  static const tenantProductsDashboardView = 'tenant.products.dashboard.view';
  static const tenantProductsCreate = 'tenant.products.create';
  static const tenantProductsUpdate = 'tenant.products.update';
  static const tenantProductsDelete = 'tenant.products.delete';
  static const tenantProductsDetailsView = 'tenant.products.details.view';

  // Inventory Permissions
  static const tenantStockDashboardView = 'tenant.stock.dashboard.view';
  static const tenantStockView = 'tenant.stock.view';
  static const tenantStockIn = 'tenant.stock.in';
  static const tenantStockOut = 'tenant.stock.out';
  static const tenantStockValueView = 'tenant.stock.value.view';
  static const tenantStockMovementsView = 'tenant.stock.movements.view';
  static const tenantStockExpiryView = 'tenant.stock.expiry.view';
  static const tenantStockAdjustmentsView = 'tenant.stock.adjustments.view';
  static const tenantStockTransfersView = 'tenant.stock.transfers.view';

  // Locked Inventory permission codes (frontend UX aliases until API grants them).
  static const inventoryStockView = 'inventory.stock.view';
  static const inventoryOpeningStockManage = 'inventory.opening_stock.manage';
  static const inventoryReceivingManage = 'inventory.receiving.manage';
  static const inventorySerialsView = 'inventory.serials.view';
  static const inventoryChannelAllocationView =
      'inventory.channel_allocation.view';
  static const inventoryChannelAllocationManage =
      'inventory.channel_allocation.manage';
  static const inventoryStockAdjust = 'inventory.stock.adjust';
  static const inventoryAlertsView = 'inventory.alerts.view';
  static const inventoryMovementsView = 'inventory.movements.view';
  static const tenantReportsProductsView = 'tenant.reports.products.view';
  static const tenantCategoriesView = 'tenant.categories.view';
  static const tenantBrandsView = 'tenant.brands.view';
  static const tenantBrandsCreate = 'tenant.brands.create';
  static const tenantBrandsUpdate = 'tenant.brands.update';
  static const tenantBrandsDelete = 'tenant.brands.delete';
  static const tenantVariantTemplatesView = 'tenant.variant.templates.view';
  static const tenantTillsView = 'tenant.tills.view';
  static const tenantTillsCreate = 'tenant.tills.create';
  static const tenantTillsUpdate = 'tenant.tills.update';
  static const tenantTillsDelete = 'tenant.tills.delete';
  static const tenantTillsDetailsView = 'tenant.tills.details.view';
  static const tenantHardwareView = 'tenant.hardware.view';
  static const tenantHardwareManage = 'tenant.hardware.manage';
  static const tenantReportsSalesView = 'tenant.reports.sales.view';
  static const tenantReportsDashboardView = 'tenant.reports.dashboard.view';
  static const tenantReportsPaymentsView = 'tenant.reports.payments.view';
  static const tenantReportsTaxView = 'tenant.reports.tax.view';
  static const tenantReportsDiscountsView = 'tenant.reports.discounts.view';
  static const tenantReportsReturnsView = 'tenant.reports.returns.view';
  static const tenantReportsCashiersView = 'tenant.reports.cashiers.view';
  static const tenantReportsOutletsView = 'tenant.reports.outlets.view';
  static const tenantReportsTillsView = 'tenant.reports.tills.view';
  static const tenantReportsDailySalesView = 'tenant.reports.daily-sales.view';
  static const tenantReportsExport = 'tenant.reports.export';
  static const tenantReportsCustomerPiiView =
      'tenant.reports.customer-pii.view';
  static const catalogProductView = 'catalog.product.view';
  static const catalogProductCreate = 'catalog.product.create';
  static const catalogProductsCreate = 'catalog.products.create';
  static const catalogProductsUpdate = 'catalog.products.update';
  static const catalogProductsView = 'catalog.products.view';
  static const catalogProductsPublish = 'catalog.products.publish';
  static const catalogProductMediaManage = 'catalog.product_media.manage';
  static const catalogProductChannelsManage = 'catalog.product_channels.manage';
  static const catalogVariantsManage = 'catalog.variants.manage';
  static const catalogComboComponentsManage = 'catalog.combo_components.manage';
  static const catalogBarcodesManage = 'catalog.barcodes.manage';
  static const catalogProductPricingManage = 'catalog.product_pricing.manage';
  static const catalogProductCostView = 'catalog.product_cost.view';
  static const pricingTaxClassesView = 'pricing.tax_classes.view';
  static const taxClassesView = 'tax.classes.view';
  static const tenantBillingView = 'tenant.billing.view';
  static const tenantSettingsManage = 'tenant.settings.manage';
  static const tenantActivityView = 'tenant.activity.view';
  static const tenantDashboardView = 'tenant.dashboard.view';
  static const tenantProductImport = 'tenant.product.import';
  static const catalogCollectionsView = 'catalog.collections.view';
  static const catalogCollectionsUpdate = 'catalog.collections.update';
  static const catalogCollectionsManage = 'catalog.collections.manage';
}

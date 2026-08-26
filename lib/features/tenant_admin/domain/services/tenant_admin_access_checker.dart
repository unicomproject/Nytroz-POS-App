import '../../../../core/access/tenant_admin_access_codes.dart';
import '../../../../core/access/tenant_admin_permission_aliases.dart';
import '../../dashboard/presentation/config/dashboard_metric_configs.dart';
import '../../dashboard/presentation/config/dashboard_needs_attention_configs.dart';
import '../../dashboard/presentation/config/dashboard_permission_config.dart';
import '../../dashboard/presentation/config/dashboard_quick_action_configs.dart';
import '../../outlets/presentation/config/outlet_row_action_configs.dart';
import '../../outlets/presentation/config/outlet_summary_card_configs.dart';
import '../../outlets/presentation/config/outlet_table_column_configs.dart';
import '../../tills/presentation/config/till_row_action_configs.dart';
import '../../users/presentation/config/user_row_action_configs.dart';
import '../entities/tenant_admin_context.dart';
import '../entities/tenant_admin_menu_item.dart';
import '../../dashboard/domain/entities/tenant_dashboard.dart';

class TenantAdminAccessChecker {
  const TenantAdminAccessChecker(this._context);

  final TenantAdminContext _context;

  TenantAdminContext get context => _context;

  int get accessibleOutletCount => _context.outletScope.length;

  bool can(String permissionCode) => canUsePermission(permissionCode);

  bool canAny(Iterable<String> permissionCodes) {
    for (final code in permissionCodes) {
      if (can(code)) {
        return true;
      }
    }

    return false;
  }

  bool canAll(Iterable<String> permissionCodes) {
    for (final code in permissionCodes) {
      if (!can(code)) {
        return false;
      }
    }

    return true;
  }

  bool hasFeature(String featureCode) => canAccessFeature(featureCode);

  bool hasAnyFeature(Iterable<String> featureCodes) {
    for (final code in featureCodes) {
      if (hasFeature(code)) {
        return true;
      }
    }

    return false;
  }

  bool hasRuntimeFlag(String flagKey) {
    if (flagKey.trim().isEmpty) {
      return false;
    }

    final matchingFlags = _context.runtimeFlags.where(
      (flag) => flag.featureCode == flagKey || flag.scope == flagKey,
    );

    if (matchingFlags.isEmpty) {
      return true;
    }

    return matchingFlags.every((flag) => flag.enabled);
  }

  bool canAccessFeature(String featureCode) {
    if (featureCode.trim().isEmpty) {
      return false;
    }

    final hasEntitlement = _context.featureEntitlements.any(
      (feature) => feature.featureCode == featureCode && feature.enabled,
    );

    if (hasEntitlement) {
      return hasRuntimeFlag(featureCode);
    }

    return _canAccessFeatureViaPermissions(featureCode);
  }

  bool _canAccessFeatureViaPermissions(String featureCode) {
    switch (featureCode) {
      case TenantAdminFeatureCodes.dashboard:
        return can(TenantAdminPermissionCodes.tenantAdminDashboardView) ||
            can(TenantAdminPermissionCodes.tenantContextView);
      case TenantAdminFeatureCodes.outletManagement:
        return canAny([
          TenantAdminPermissionCodes.outletView,
          TenantAdminPermissionCodes.tenantOutletsView,
          TenantAdminPermissionCodes.tenantOutletsManage,
        ]);
      case TenantAdminFeatureCodes.staffManagement:
        return canAny([
          TenantAdminPermissionCodes.userView,
          TenantAdminPermissionCodes.tenantUserManage,
        ]);
      case TenantAdminFeatureCodes.rolePermission:
        return canAny([
          TenantAdminPermissionCodes.roleView,
          TenantAdminPermissionCodes.permissionView,
          TenantAdminPermissionCodes.tenantRoleManage,
        ]);
      case TenantAdminFeatureCodes.productManagement:
        return canAny([
          TenantAdminPermissionCodes.productView,
          TenantAdminPermissionCodes.catalogProductView,
        ]);
      case TenantAdminFeatureCodes.inventoryManagement:
        return can(TenantAdminPermissionCodes.tenantStockView);
      case TenantAdminFeatureCodes.reportsAnalytics:
        return can(TenantAdminPermissionCodes.reportView);
      case TenantAdminFeatureCodes.sales:
        return canAny([
          TenantAdminPermissionCodes.dashboardSalesSummaryView,
          TenantAdminPermissionCodes.dashboardOrdersSummaryView,
        ]);
      case TenantAdminFeatureCodes.onlineStore:
        return canAny([
          TenantAdminPermissionCodes.onlineStoreView,
          TenantAdminPermissionCodes.onlineStoreManage,
          TenantAdminPermissionCodes.onlineStorePublish,
          TenantAdminPermissionCodes.onlineStoreDomainsManage,
          TenantAdminPermissionCodes.onlineStoreBrandingManage,
          TenantAdminPermissionCodes.onlineStoreSupportManage,
          TenantAdminPermissionCodes.onlineStoreFulfillmentManage,
          TenantAdminPermissionCodes.onlineStoreCatalogManage,
          TenantAdminPermissionCodes.onlineStorePoliciesManage,
        ]);
      case TenantAdminFeatureCodes.clickCollect:
        return can(TenantAdminPermissionCodes.onlineStoreFulfillmentManage);
      case TenantAdminFeatureCodes.billingSubscription:
        return canAny([
          TenantAdminPermissionCodes.billingView,
          TenantAdminPermissionCodes.subscriptionView,
          TenantAdminPermissionCodes.tenantBillingView,
        ]);
      case TenantAdminFeatureCodes.tenantSettings:
        return canAny([
          TenantAdminPermissionCodes.tenantSettingsView,
          TenantAdminPermissionCodes.tenantSettingsManage,
        ]);
      case TenantAdminFeatureCodes.activityAudit:
        return canAny([
          TenantAdminPermissionCodes.activityLogView,
          TenantAdminPermissionCodes.tenantActivityView,
        ]);
      case TenantAdminFeatureCodes.support:
        return can(TenantAdminPermissionCodes.supportView);
      case TenantAdminFeatureCodes.tillManagement:
        return canAny([
          TenantAdminPermissionCodes.tillView,
          TenantAdminPermissionCodes.tenantTillsView,
          TenantAdminPermissionCodes.tillCreate,
          TenantAdminPermissionCodes.tenantTillsCreate,
          TenantAdminPermissionCodes.tillUpdate,
          TenantAdminPermissionCodes.tenantTillsUpdate,
          TenantAdminPermissionCodes.tillDelete,
          TenantAdminPermissionCodes.tenantTillsDelete,
        ]);
      default:
        return false;
    }
  }

  bool canUsePermission(String permissionCode) {
    if (permissionCode.trim().isEmpty) {
      return false;
    }

    final acceptedCodes = TenantAdminPermissionAliases.expand(permissionCode);

    return _context.permissions.any(
      (permission) => acceptedCodes.contains(permission.permissionCode),
    );
  }

  bool canAccessOutlet(String outletId) {
    if (outletId.trim().isEmpty) {
      return false;
    }

    return _context.outletScope.any((outlet) => outlet.outletId == outletId);
  }

  bool canShowAction(
    String featureCode,
    String permissionCode, {
    String? outletId,
  }) {
    final hasFeatureAndPermission =
        canAccessFeature(featureCode) && canUsePermission(permissionCode);

    if (!hasFeatureAndPermission) {
      return false;
    }

    if (outletId == null) {
      return true;
    }

    return canAccessOutlet(outletId);
  }

  bool canShowActionWithAnyPermission(
    String featureCode,
    Iterable<String> permissionCodes, {
    String? outletId,
  }) {
    if (!canAccessFeature(featureCode)) {
      return false;
    }

    if (!canAny(permissionCodes)) {
      return false;
    }

    if (outletId == null) {
      return true;
    }

    return canAccessOutlet(outletId);
  }

  bool canShowActionWithAnyFeature(
    Iterable<String> featureCodes,
    Iterable<String> permissionCodes, {
    String? outletId,
  }) {
    if (!hasAnyFeature(featureCodes)) {
      return false;
    }

    if (!canAny(permissionCodes)) {
      return false;
    }

    if (outletId == null) {
      return true;
    }

    return canAccessOutlet(outletId);
  }

  bool canShowActionWithAllPermissions(
    String featureCode,
    Iterable<String> permissionCodes, {
    String? outletId,
  }) {
    if (!canAccessFeature(featureCode)) {
      return false;
    }

    if (!canAll(permissionCodes)) {
      return false;
    }

    if (outletId == null) {
      return true;
    }

    return canAccessOutlet(outletId);
  }

  bool canAccessMenuItem(TenantAdminMenuItem menuItem) {
    if (!menuItem.visible) {
      return false;
    }

    switch (menuItem.key) {
      case 'roles-access':
        return canAccessFeature(menuItem.featureCode) &&
            canAny([
              TenantAdminPermissionCodes.roleView,
              TenantAdminPermissionCodes.permissionView,
              TenantAdminPermissionCodes.tenantRoleManage,
            ]);
      case 'billing':
        return canAccessFeature(menuItem.featureCode) &&
            canAny([
              TenantAdminPermissionCodes.billingView,
              TenantAdminPermissionCodes.subscriptionView,
              TenantAdminPermissionCodes.tenantBillingView,
            ]);
      case 'tills':
        return canAccessTillModule();
      case 'staff':
        return canAccessUserModule();
      case 'products':
        return canAccessProductsSidebar();
      case 'inventory':
      case 'stock':
        return canShowAction(
          menuItem.featureCode,
          menuItem.permissionCode,
        );
      case 'online-store':
        return canAccessOnlineStoreModule();
      case 'hardware':
        return canAny([
          TenantAdminPermissionCodes.tenantHardwareView,
          TenantAdminPermissionCodes.tenantHardwareManage,
        ]);
      default:
        return canShowAction(menuItem.featureCode, menuItem.permissionCode);
    }
  }

  bool canAccessDashboardRoute() {
    return canShowAction(
      TenantAdminFeatureCodes.dashboard,
      TenantAdminPermissionCodes.tenantAdminDashboardView,
    );
  }

  bool canAccessOnlineStoreModule() =>
      _hasEnabledFeatureEntitlement(TenantAdminFeatureCodes.onlineStore) &&
      hasRuntimeFlag(TenantAdminFeatureCodes.onlineStore) &&
      can(TenantAdminPermissionCodes.onlineStoreView);

  bool canViewOnlineStore() => canAccessOnlineStoreModule();

  bool canManageOnlineStore() => _canUseOnlineStorePermission(
      TenantAdminPermissionCodes.onlineStoreManage);

  bool canManageOnlineStoreDomains() => _canUseOnlineStorePermission(
        TenantAdminPermissionCodes.onlineStoreDomainsManage,
      );

  bool canManageOnlineStoreBranding() => _canUseOnlineStorePermission(
        TenantAdminPermissionCodes.onlineStoreBrandingManage,
      );

  bool canManageOnlineStoreSupport() => _canUseOnlineStorePermission(
        TenantAdminPermissionCodes.onlineStoreSupportManage,
      );

  bool canManageOnlineStoreFulfillment() {
    if (!_hasEnabledFeatureEntitlement(TenantAdminFeatureCodes.onlineStore) ||
        !hasRuntimeFlag(TenantAdminFeatureCodes.onlineStore)) {
      return false;
    }

    if (!_hasEnabledFeatureEntitlement(TenantAdminFeatureCodes.clickCollect) ||
        !hasRuntimeFlag(TenantAdminFeatureCodes.clickCollect)) {
      return false;
    }

    return can(TenantAdminPermissionCodes.onlineStoreFulfillmentManage);
  }

  bool canManageOnlineStoreCatalog() => _canUseOnlineStorePermission(
        TenantAdminPermissionCodes.onlineStoreCatalogManage,
      );

  bool canManageOnlineStorePolicies() => _canUseOnlineStorePermission(
        TenantAdminPermissionCodes.onlineStorePoliciesManage,
      );

  bool canPublishOnlineStore() => _canUseOnlineStorePermission(
        TenantAdminPermissionCodes.onlineStorePublish,
      );

  bool _canUseOnlineStorePermission(String permissionCode) =>
      _hasEnabledFeatureEntitlement(TenantAdminFeatureCodes.onlineStore) &&
      hasRuntimeFlag(TenantAdminFeatureCodes.onlineStore) &&
      can(permissionCode);

  bool _hasEnabledFeatureEntitlement(String featureCode) {
    return _context.featureEntitlements.any(
      (feature) => feature.featureCode == featureCode && feature.enabled,
    );
  }

  bool canFetchDashboardSummary() => canLoadDashboardData();

  bool get _hasFullDashboardAccess =>
      can(TenantAdminPermissionCodes.tenantAdminDashboardView);

  bool _canViewDashboardWidget(DashboardWidgetPermissionConfig config) {
    if (_hasFullDashboardAccess) {
      return true;
    }

    return dashboardWidgetAllowed(config, can, canAny);
  }

  /// Returns true when any dashboard widget permission requires API payload data.
  bool canLoadDashboardData() {
    if (_hasFullDashboardAccess) {
      return true;
    }

    return canAny([
      TenantAdminPermissionCodes.dashboardSalesSummaryView,
      TenantAdminPermissionCodes.dashboardOrdersSummaryView,
      TenantAdminPermissionCodes.dashboardOutletSummaryView,
      TenantAdminPermissionCodes.dashboardStockAlertsView,
      TenantAdminPermissionCodes.dashboardTillStatusView,
      TenantAdminPermissionCodes.dashboardSalesChartView,
      TenantAdminPermissionCodes.dashboardAttentionView,
      TenantAdminPermissionCodes.activityLogView,
      TenantAdminPermissionCodes.notificationView,
      TenantAdminPermissionCodes.dashboardSummaryView,
    ]);
  }

  bool canViewNotifications() =>
      can(TenantAdminPermissionCodes.notificationView);

  bool canReadNotifications() =>
      can(TenantAdminPermissionCodes.notificationRead);

  bool canViewProfile() => can(TenantAdminPermissionCodes.profileView);

  bool canViewTenantContext() =>
      can(TenantAdminPermissionCodes.tenantContextView);

  bool canViewSubscription() {
    return canAccessFeature(TenantAdminFeatureCodes.billingSubscription) &&
        canAny([
          TenantAdminPermissionCodes.billingView,
          TenantAdminPermissionCodes.subscriptionView,
          TenantAdminPermissionCodes.tenantBillingView,
        ]);
  }

  bool canViewDateFilter() =>
      can(TenantAdminPermissionCodes.dashboardFilterDate);

  bool canViewOutletFilter() {
    return can(TenantAdminPermissionCodes.dashboardFilterOutlet) &&
        can(TenantAdminPermissionCodes.outletView) &&
        accessibleOutletCount > 1;
  }

  bool canViewSalesTrend() =>
      can(TenantAdminPermissionCodes.dashboardSalesChartView);

  bool canViewReportsLink() {
    return canAny([
      TenantAdminPermissionCodes.reportSalesView,
      TenantAdminPermissionCodes.reportView,
    ]);
  }

  bool canAccessReportsModule() {
    return canAccessFeature(TenantAdminFeatureCodes.reportsAnalytics) &&
        canAny([
          TenantAdminPermissionCodes.reportView,
          TenantAdminPermissionCodes.reportSalesView,
          TenantAdminPermissionCodes.tenantReportsSalesView,
        ]);
  }

  bool canViewReportsDashboard() {
    return canAccessReportsModule() &&
        canAny([
          TenantAdminPermissionCodes.tenantReportsDashboardView,
          TenantAdminPermissionCodes.reportView,
        ]);
  }

  bool canViewSalesReport() {
    return canAccessReportsModule() &&
        canAny([
          TenantAdminPermissionCodes.tenantReportsSalesView,
          TenantAdminPermissionCodes.reportSalesView,
        ]);
  }

  bool canViewSalesTransactions() => canViewSalesReport();

  bool canViewProductSalesReport() {
    return canAccessReportsModule() &&
        canAny([
          TenantAdminPermissionCodes.tenantReportsProductsView,
          TenantAdminPermissionCodes.tenantReportsSalesView,
        ]);
  }

  bool canViewCategorySalesReport() => canViewProductSalesReport();

  bool canViewPaymentReport() {
    return canAccessReportsModule() &&
        can(TenantAdminPermissionCodes.tenantReportsPaymentsView);
  }

  bool canViewTaxReport() {
    return canAccessReportsModule() &&
        can(TenantAdminPermissionCodes.tenantReportsTaxView);
  }

  bool canViewDiscountReport() {
    return canAccessReportsModule() &&
        can(TenantAdminPermissionCodes.tenantReportsDiscountsView);
  }

  bool canViewReturnRefundReport() {
    return canAccessReportsModule() &&
        can(TenantAdminPermissionCodes.tenantReportsReturnsView);
  }

  bool canViewCashierPerformance() {
    return canAccessReportsModule() &&
        can(TenantAdminPermissionCodes.tenantReportsCashiersView);
  }

  bool canViewDailySalesReport() {
    return canAccessReportsModule() &&
        can(TenantAdminPermissionCodes.tenantReportsDailySalesView);
  }

  bool canViewStockReport() {
    return canAccessReportsModule() &&
        can(TenantAdminPermissionCodes.tenantStockView);
  }

  bool canViewLowStockReport() => canViewStockReport();

  bool canViewOutOfStockReport() => canViewStockReport();

  bool canViewBatchExpiryReport() {
    return canViewStockReport() &&
        can(TenantAdminPermissionCodes.tenantStockExpiryView);
  }

  bool canViewStockMovements() {
    return canViewStockReport() &&
        can(TenantAdminPermissionCodes.tenantStockMovementsView);
  }

  bool canViewInventoryValuation() {
    return canViewStockReport() &&
        can(TenantAdminPermissionCodes.tenantStockValueView);
  }

  bool canViewStockValue() => canViewInventoryValuation();

  bool canViewOutletReport() {
    return canAccessReportsModule() &&
        canAny([
          TenantAdminPermissionCodes.tenantReportsOutletsView,
          TenantAdminPermissionCodes.tenantOutletsRevenueView,
          TenantAdminPermissionCodes.tenantReportsSalesView,
        ]);
  }

  bool canViewTillSummary() {
    return canViewOutletReport() &&
        canAny([
          TenantAdminPermissionCodes.tenantReportsTillsView,
          TenantAdminPermissionCodes.tenantTillsView,
        ]);
  }

  bool canViewSalesTransactionDetail() => canViewSalesTransactions();

  bool canExportReports() {
    return canAccessReportsModule() &&
        can(TenantAdminPermissionCodes.tenantReportsExport);
  }

  bool canViewCustomerPii() {
    return canAccessReportsModule() &&
        can(TenantAdminPermissionCodes.tenantReportsCustomerPiiView);
  }

  bool canViewNeedsAttentionSection() {
    return _hasFullDashboardAccess ||
        can(TenantAdminPermissionCodes.dashboardAttentionView);
  }

  bool canViewNeedsAttentionViewAll({required bool hasVisibleItems}) {
    if (can(TenantAdminPermissionCodes.dashboardAttentionViewAll)) {
      return true;
    }

    return hasVisibleItems && canViewNeedsAttentionSection();
  }

  bool canViewAllActivityLink() =>
      can(TenantAdminPermissionCodes.activityLogView);

  bool canViewRecentActivitySection() {
    return _hasFullDashboardAccess ||
        can(TenantAdminPermissionCodes.activityLogView);
  }

  bool canViewSalesChart() {
    return _hasFullDashboardAccess ||
        can(TenantAdminPermissionCodes.dashboardSalesChartView);
  }

  bool canViewMetric(TenantDashboardMetric metric) {
    final config = metricConfigForKey(metric.key);
    if (config == null) {
      return false;
    }

    return _canViewDashboardWidget(config);
  }

  bool canViewAttentionItem(TenantDashboardAttentionItem item) {
    if (!canViewNeedsAttentionSection()) {
      return false;
    }

    final config = needsAttentionConfigForKey(item.key);
    if (config == null) {
      return false;
    }

    return _canViewDashboardWidget(config);
  }

  bool canViewQuickAction(TenantDashboardQuickAction action) {
    if (action.key == 'add-product' || action.key == 'add_product') {
      return canCreateProduct();
    }

    final config = quickActionConfigForKey(action.key);
    if (config != null) {
      if (_hasFullDashboardAccess) {
        return true;
      }

      return _canViewDashboardWidget(config);
    }

    return canShowAction(action.featureCode, action.permissionCode);
  }

  bool canViewActivityItem(TenantDashboardActivity activity) {
    if (!canViewRecentActivitySection()) {
      return false;
    }

    if (!can(TenantAdminPermissionCodes.activityLogDetailView)) {
      return true;
    }

    switch (activity.key) {
      case 'outlet':
        return can(TenantAdminPermissionCodes.outletView);
      case 'stock':
      case 'inventory':
        return can(TenantAdminPermissionCodes.inventoryView);
      case 'staff':
      case 'users':
        return can(TenantAdminPermissionCodes.userView);
      default:
        return true;
    }
  }

  bool canAccessOutletListPage() {
    return canShowAction(
      TenantAdminFeatureCodes.outletManagement,
      TenantAdminPermissionCodes.outletView,
    );
  }

  bool canFetchOutletList() => canAccessOutletListPage();

  bool canFetchOutletSummary() {
    return canAccessOutletListPage() &&
        can(TenantAdminPermissionCodes.outletSummaryView);
  }

  bool canViewOutletListFilter() {
    return can(TenantAdminPermissionCodes.outletFilterView) ||
        can(TenantAdminPermissionCodes.outletView);
  }

  bool canCreateOutlet() {
    return canShowAction(
      TenantAdminFeatureCodes.outletManagement,
      TenantAdminPermissionCodes.outletCreate,
    );
  }

  bool hasTillManagementEntitlement() {
    return canAccessFeature(TenantAdminFeatureCodes.tillManagement);
  }

  bool canAccessTillModule() {
    return hasTillManagementEntitlement() &&
        canAny([
          TenantAdminPermissionCodes.tillView,
          TenantAdminPermissionCodes.tenantTillsView,
        ]);
  }

  bool canAccessTillListPage() => canAccessTillModule();

  bool canFetchTillList() => canAccessTillListPage();

  bool canCreateTill() {
    return hasTillManagementEntitlement() &&
        canAny([
          TenantAdminPermissionCodes.tillCreate,
          TenantAdminPermissionCodes.tenantTillsCreate,
        ]);
  }

  bool canUpdateTill() {
    return hasTillManagementEntitlement() &&
        canAny([
          TenantAdminPermissionCodes.tillUpdate,
          TenantAdminPermissionCodes.tenantTillsUpdate,
        ]);
  }

  bool canDeleteTill() {
    return hasTillManagementEntitlement() &&
        canAny([
          TenantAdminPermissionCodes.tillDelete,
          TenantAdminPermissionCodes.tenantTillsDelete,
        ]);
  }

  bool canViewTillHardware() {
    return canAny([
      TenantAdminPermissionCodes.tenantHardwareView,
      TenantAdminPermissionCodes.tenantHardwareManage,
    ]);
  }

  bool canManageTillHardware() {
    return can(TenantAdminPermissionCodes.tenantHardwareManage);
  }

  bool canGenerateTillActivationCode() {
    return hasTillManagementEntitlement() &&
        can(TenantAdminPermissionCodes.tillActivationCodeGenerate);
  }

  bool canViewTillSales() {
    return canAny([
      TenantAdminPermissionCodes.salesSummaryView,
      TenantAdminPermissionCodes.outletSalesSummaryView,
    ]);
  }

  bool hasUserManagementEntitlement() {
    return canAccessFeature(TenantAdminFeatureCodes.staffManagement);
  }

  bool canAccessUserModule() {
    return hasUserManagementEntitlement() &&
        canAny([
          TenantAdminPermissionCodes.userView,
          TenantAdminPermissionCodes.tenantUsersView,
        ]);
  }

  bool canAccessUserListPage() => canAccessUserModule();

  bool canFetchUserList() => canAccessUserListPage();

  bool canCreateUser() {
    return hasUserManagementEntitlement() &&
        canAny([
          TenantAdminPermissionCodes.userCreate,
          TenantAdminPermissionCodes.tenantUsersCreate,
        ]);
  }

  bool canInviteUser() {
    return hasUserManagementEntitlement() &&
        canAny([
          TenantAdminPermissionCodes.userInviteCreate,
          TenantAdminPermissionCodes.tenantUsersInvite,
        ]);
  }

  bool canAddUser() => canCreateUser() || canInviteUser();

  bool canViewUserDetail() {
    return hasUserManagementEntitlement() &&
        canAny([
          TenantAdminPermissionCodes.tenantUsersDetailsView,
          TenantAdminPermissionCodes.userView,
          TenantAdminPermissionCodes.tenantUsersView,
        ]);
  }

  bool canUpdateUser() {
    // Deliberately does not fall back to the coarse `tenant.user.manage`
    // code: its alias expansion includes granular view permissions (see
    // tenant_admin_permission_aliases.dart), which would let view-only
    // users incorrectly pass an update check. Mirrors canUpdateTill()'s
    // precise-permission pattern.
    return hasUserManagementEntitlement() &&
        can(TenantAdminPermissionCodes.tenantUsersUpdate);
  }

  bool canDeleteUser() {
    // See canUpdateUser() for why `tenant.user.manage` is intentionally
    // excluded here.
    return hasUserManagementEntitlement() &&
        can(TenantAdminPermissionCodes.tenantUsersDelete);
  }

  bool canOverrideUserPermissions() {
    return can(TenantAdminPermissionCodes.tenantUsersPermissionOverride);
  }

  bool hasProductManagementEntitlement() {
    return canAccessFeature(TenantAdminFeatureCodes.productManagement);
  }

  bool canViewProductDashboard() {
    return can(TenantAdminPermissionCodes.tenantProductsDashboardView);
  }

  bool canFetchProductDashboard() => canViewProductDashboard();

  bool canViewProductDashboardDateFilter() => canViewProductDashboard();

  bool canViewProductDashboardOutletFilter() {
    return canViewProductDashboard() &&
        can(TenantAdminPermissionCodes.outletView) &&
        accessibleOutletCount > 1;
  }

  bool canViewProductDashboardSummarySection() {
    return canViewProductDashboard() &&
        canAny([
          TenantAdminPermissionCodes.tenantStockView,
          TenantAdminPermissionCodes.tenantProductsView,
        ]);
  }

  bool canViewProductDashboardTotalProducts() {
    return canViewProductDashboard() &&
        can(TenantAdminPermissionCodes.tenantProductsView);
  }

  bool canViewProductDashboardLowStock() {
    return canViewProductDashboard() &&
        can(TenantAdminPermissionCodes.tenantStockView);
  }

  bool canViewProductDashboardOutOfStock() {
    return canViewProductDashboard() &&
        can(TenantAdminPermissionCodes.tenantStockView);
  }

  bool canViewProductDashboardExpiryAlerts() {
    return canViewProductDashboard() &&
        can(TenantAdminPermissionCodes.tenantStockExpiryView);
  }

  bool canViewProductDashboardStockAdded() {
    return canViewProductDashboard() &&
        can(TenantAdminPermissionCodes.tenantStockView);
  }

  bool canViewProductDashboardFastMoving() {
    return canViewProductDashboard() &&
        can(TenantAdminPermissionCodes.tenantReportsProductsView);
  }

  bool canNavigateProductDashboardTotalProducts() => canViewProductListNav();

  bool canNavigateProductDashboardLowStock() =>
      can(TenantAdminPermissionCodes.tenantStockView);

  bool canNavigateProductDashboardOutOfStock() =>
      can(TenantAdminPermissionCodes.tenantStockView);

  bool canNavigateProductDashboardExpiryAlerts() =>
      can(TenantAdminPermissionCodes.tenantStockExpiryView);

  bool canNavigateProductDashboardStockAdded() =>
      can(TenantAdminPermissionCodes.tenantStockIn);

  bool canNavigateProductDashboardFastMoving() =>
      can(TenantAdminPermissionCodes.tenantReportsProductsView);

  bool canNavigateProductDashboardStockInMovement() =>
      can(TenantAdminPermissionCodes.tenantStockIn);

  bool canNavigateProductDashboardStockOutMovement() =>
      can(TenantAdminPermissionCodes.tenantStockOut);

  bool canNavigateProductDashboardAdjustments() =>
      can(TenantAdminPermissionCodes.tenantStockAdjustmentsView);

  bool canNavigateProductDashboardTransfers() =>
      can(TenantAdminPermissionCodes.tenantStockTransfersView);

  bool canViewProductDashboardStockValue() {
    return canViewProductDashboard() &&
        can(TenantAdminPermissionCodes.tenantStockValueView);
  }

  bool canViewProductDashboardStockMovement() {
    return canViewProductDashboard() &&
        can(TenantAdminPermissionCodes.tenantStockMovementsView);
  }

  bool canViewProductListNav() {
    return can(TenantAdminPermissionCodes.tenantProductsView);
  }

  bool canViewCategoriesNav() {
    return can(TenantAdminPermissionCodes.tenantCategoriesView);
  }

  bool canViewBrandsNav() {
    return can(TenantAdminPermissionCodes.tenantBrandsView);
  }

  bool canFetchBrandList() => canViewBrandsNav();

  bool canCreateBrand() {
    return canAny([
      TenantAdminPermissionCodes.tenantBrandsCreate,
      'catalog.brands.create',
      'catalog.brands.manage',
    ]);
  }

  bool canUpdateBrand() {
    return canAny([
      TenantAdminPermissionCodes.tenantBrandsUpdate,
      'catalog.brands.update',
      'catalog.brands.manage',
    ]);
  }

  bool canDeleteBrand() {
    return canAny([
      TenantAdminPermissionCodes.tenantBrandsDelete,
      'catalog.brands.delete',
      'catalog.brands.manage',
    ]);
  }

  bool canViewVariantTemplatesNav() {
    return can(TenantAdminPermissionCodes.tenantVariantTemplatesView);
  }

  bool canViewCurrentStock() {
    return canAny([
      TenantAdminPermissionCodes.inventoryStockView,
      TenantAdminPermissionCodes.tenantStockView,
    ]);
  }

  bool canStockIn() {
    return canAny([
      TenantAdminPermissionCodes.inventoryReceivingManage,
      TenantAdminPermissionCodes.tenantStockIn,
    ]);
  }

  bool canAccessCurrentStockPage() => canViewCurrentStock();

  bool canAccessStockInPage() => canStockIn();

  bool canAccessInventoryDashboard() {
    return canAny([
      TenantAdminPermissionCodes.inventoryStockView,
      TenantAdminPermissionCodes.tenantStockDashboardView,
      TenantAdminPermissionCodes.tenantStockView,
    ]);
  }

  bool canAccessOpeningStockPage() {
    return canAny([
      TenantAdminPermissionCodes.inventoryOpeningStockManage,
      TenantAdminPermissionCodes.tenantStockOpening,
      TenantAdminPermissionCodes.tenantStockIn,
      TenantAdminPermissionCodes.tenantStockView,
    ]);
  }

  bool canAccessReceivingPage() => canStockIn();

  bool canManageReceiving() => canStockIn();

  bool canAccessSerialsPage() {
    return canAny([
      TenantAdminPermissionCodes.inventorySerialsView,
      TenantAdminPermissionCodes.inventoryStockView,
      TenantAdminPermissionCodes.tenantStockView,
    ]);
  }

  bool canAccessAdjustmentPage() {
    return canAny([
      TenantAdminPermissionCodes.inventoryStockView,
      TenantAdminPermissionCodes.inventoryStockAdjust,
      TenantAdminPermissionCodes.tenantStockAdjustmentsView,
      TenantAdminPermissionCodes.tenantStockView,
    ]);
  }

  bool canCreateStockAdjustment() {
    return canAny([
      TenantAdminPermissionCodes.inventoryStockAdjust,
      TenantAdminPermissionCodes.tenantStockAdjustmentsView,
    ]);
  }

  bool canAccessChannelAllocationPage() {
    return canAny([
      TenantAdminPermissionCodes.inventoryChannelAllocationView,
      TenantAdminPermissionCodes.inventoryChannelAllocationManage,
      TenantAdminPermissionCodes.inventoryStockView,
      TenantAdminPermissionCodes.tenantStockView,
    ]);
  }

  bool canManageChannelAllocation() {
    return can(TenantAdminPermissionCodes.inventoryChannelAllocationManage);
  }

  bool canViewInventoryAlerts() {
    return canAny([
      TenantAdminPermissionCodes.inventoryAlertsView,
      TenantAdminPermissionCodes.inventoryAlertView,
      TenantAdminPermissionCodes.inventoryStockAlertsView,
    ]);
  }

  bool canViewStockNav() => canViewCurrentStock();

  bool canFetchCurrentStockList() => canViewCurrentStock();

  bool canFetchCurrentStockSummary() => canViewCurrentStock();

  bool canCreateProductNav() {
    return can(TenantAdminPermissionCodes.tenantProductsCreate);
  }

  bool canAccessProductsSidebar() {
    return canAny([
      TenantAdminPermissionCodes.tenantProductsDashboardView,
      TenantAdminPermissionCodes.tenantProductsView,
      TenantAdminPermissionCodes.tenantProductsCreate,
      TenantAdminPermissionCodes.tenantCategoriesView,
      TenantAdminPermissionCodes.tenantBrandsView,
      TenantAdminPermissionCodes.tenantVariantTemplatesView,
      TenantAdminPermissionCodes.tenantProductImport,
      TenantAdminPermissionCodes.tenantStockView,
      TenantAdminPermissionCodes.catalogCollectionsView,
      TenantAdminPermissionCodes.catalogCollectionsManage,
    ]);
  }

  bool canImportProductsNav() {
    return can(TenantAdminPermissionCodes.tenantProductImport);
  }

  bool canViewPopularProductsNav() {
    return can(TenantAdminPermissionCodes.catalogCollectionsView) ||
        can(TenantAdminPermissionCodes.catalogCollectionsManage);
  }

  bool canManagePopularProducts() {
    return can(TenantAdminPermissionCodes.catalogCollectionsUpdate) ||
        can(TenantAdminPermissionCodes.catalogCollectionsManage);
  }

  /// Products → Inventory child visibility (product stock setup).
  /// Distinct from top-level Inventory module navigation.
  bool canViewProductInventoryNav() {
    return can(TenantAdminPermissionCodes.tenantStockView);
  }

  bool canViewStock() {
    return can(TenantAdminPermissionCodes.tenantStockView);
  }

  bool canAccessProductModule() {
    return hasProductManagementEntitlement() &&
        can(TenantAdminPermissionCodes.tenantProductsView);
  }

  bool canAccessProductListPage() => canAccessProductModule();

  bool canFetchProductList() => canAccessProductListPage();

  bool canFetchProductSummary() => canAccessProductListPage();

  bool canCreateProduct() {
    return hasProductManagementEntitlement() &&
        canAny([
          TenantAdminPermissionCodes.tenantProductsCreate,
          TenantAdminPermissionCodes.catalogProductsCreate,
          TenantAdminPermissionCodes.productCreate,
          TenantAdminPermissionCodes.catalogProductCreate,
        ]);
  }

  /// Page entry matches the Products sidebar and route guard: product create.
  /// Specialized catalog codes (`barcodes.manage`, `product_pricing.manage`,
  /// tax lookup) remain capability flags for in-wizard disablement; the backend
  /// is authoritative. Do not block the whole Add Product page on grants that
  /// Tenant Admin historically never received.
  bool canAccessAddProductPage() {
    return canCreateProduct();
  }

  List<String> missingProductWizardStartCapabilities() {
    final missing = <String>[];
    if (!canCreateProduct()) {
      missing.add('catalog.products.create');
    }
    if (!canManageBarcodes()) {
      missing.add('catalog.barcodes.manage');
    }
    if (!canManagePricing()) {
      missing.add('catalog.product_pricing.manage');
    }
    if (!canLookupTaxClasses()) {
      missing.add('pricing.tax_classes.view');
    }
    return missing;
  }

  bool canViewProductDetail() {
    return hasProductManagementEntitlement() &&
        canAny([
          TenantAdminPermissionCodes.tenantProductsDetailsView,
          TenantAdminPermissionCodes.tenantProductsView,
          TenantAdminPermissionCodes.productView,
          TenantAdminPermissionCodes.catalogProductView,
        ]);
  }

  bool canUpdateProduct() {
    return hasProductManagementEntitlement() &&
        canAny([
          TenantAdminPermissionCodes.tenantProductsUpdate,
          'catalog.product.update',
        ]);
  }

  bool canDeleteProduct() {
    return hasProductManagementEntitlement() &&
        can(TenantAdminPermissionCodes.tenantProductsDelete);
  }

  bool canPublishProduct() {
    return hasProductManagementEntitlement() &&
        can(TenantAdminPermissionCodes.catalogProductsPublish);
  }

  bool canManageProductMedia() {
    return hasProductManagementEntitlement() &&
        can(TenantAdminPermissionCodes.catalogProductMediaManage);
  }

  bool canManageProductChannels() {
    return hasProductManagementEntitlement() &&
        can(TenantAdminPermissionCodes.catalogProductChannelsManage);
  }

  bool canManageVariants() {
    return hasProductManagementEntitlement() &&
        can(TenantAdminPermissionCodes.catalogVariantsManage);
  }

  bool canManageBundleComponents() {
    return hasProductManagementEntitlement() &&
        can(TenantAdminPermissionCodes.catalogComboComponentsManage);
  }

  bool canManageBarcodes() {
    return hasProductManagementEntitlement() &&
        can(TenantAdminPermissionCodes.catalogBarcodesManage);
  }

  bool canManagePricing() {
    return hasProductManagementEntitlement() &&
        can(TenantAdminPermissionCodes.catalogProductPricingManage);
  }

  bool canViewProductCost() {
    return hasProductManagementEntitlement() &&
        can(TenantAdminPermissionCodes.catalogProductCostView);
  }

  bool canLookupTaxClasses() {
    return canAny([
      TenantAdminPermissionCodes.pricingTaxClassesView,
      TenantAdminPermissionCodes.taxClassesView,
    ]);
  }

  bool canViewStockForProductSetup() {
    return can(TenantAdminPermissionCodes.inventoryView) ||
        can(TenantAdminPermissionCodes.tenantStockView);
  }

  bool canUseAdvancedInventoryTracking() {
    return canAccessFeature('inventory_tracking') ||
        canAccessFeature(TenantAdminFeatureCodes.inventoryManagement);
  }

  bool canViewOutletDetail() {
    return canShowActionWithAnyPermission(
      TenantAdminFeatureCodes.outletManagement,
      [
        TenantAdminPermissionCodes.outletDetailView,
        TenantAdminPermissionCodes.outletView,
        TenantAdminPermissionCodes.tenantOutletsDetailsView,
        TenantAdminPermissionCodes.tenantOutletsView,
        TenantAdminPermissionCodes.tenantOutletsManage,
      ],
    );
  }

  bool canEditOutlet() {
    return canShowActionWithAnyPermission(
      TenantAdminFeatureCodes.outletManagement,
      [
        TenantAdminPermissionCodes.outletUpdate,
        TenantAdminPermissionCodes.tenantOutletsUpdate,
        TenantAdminPermissionCodes.tenantOutletsManage,
      ],
    );
  }

  bool canViewOutletSalesSummary() {
    return can(TenantAdminPermissionCodes.outletSalesSummaryView);
  }

  bool canViewOutletLocation() {
    return can(TenantAdminPermissionCodes.outletLocationView);
  }

  bool canViewOutletStatus() {
    return can(TenantAdminPermissionCodes.outletStatusView);
  }

  bool canViewOutletTillSummary() {
    return canAny([
      TenantAdminPermissionCodes.tillView,
      TenantAdminPermissionCodes.outletTillSummaryView,
    ]);
  }

  bool canViewOutletStaffSummary() {
    return canAny([
      TenantAdminPermissionCodes.userView,
      TenantAdminPermissionCodes.outletStaffSummaryView,
    ]);
  }
}

class TenantDashboardVisibility {
  const TenantDashboardVisibility({
    required this.showTitle,
    required this.showSubtitle,
    required this.showNotifications,
    required this.showNotificationReadAction,
    required this.showProfile,
    required this.showTenantContext,
    required this.showSubscription,
    required this.showDateFilter,
    required this.showOutletFilter,
    required this.showSalesTrend,
    required this.showReportsLink,
    required this.showNeedsAttentionViewAll,
    required this.showAllActivityLink,
    required this.showSalesChart,
    required this.showNeedsAttentionSection,
    required this.showQuickActionsSection,
    required this.showRecentActivitySection,
    required this.showKpiSection,
    required this.visibleMetrics,
    required this.visibleAttentionItems,
    required this.visibleQuickActions,
    required this.visibleActivities,
    required this.notificationCount,
    this.salesSummary,
  });

  final bool showTitle;
  final bool showSubtitle;
  final bool showNotifications;
  final bool showNotificationReadAction;
  final bool showProfile;
  final bool showTenantContext;
  final bool showSubscription;
  final bool showDateFilter;
  final bool showOutletFilter;
  final bool showSalesTrend;
  final bool showReportsLink;
  final bool showNeedsAttentionViewAll;
  final bool showAllActivityLink;
  final bool showSalesChart;
  final bool showNeedsAttentionSection;
  final bool showQuickActionsSection;
  final bool showRecentActivitySection;
  final bool showKpiSection;
  final List<TenantDashboardMetric> visibleMetrics;
  final List<TenantDashboardAttentionItem> visibleAttentionItems;
  final List<TenantDashboardQuickAction> visibleQuickActions;
  final List<TenantDashboardActivity> visibleActivities;
  final int? notificationCount;
  final TenantDashboardSalesSummary? salesSummary;

  static TenantDashboardVisibility resolve({
    required TenantAdminAccessChecker access,
    TenantDashboard? dashboard,
  }) {
    final metrics = dashboard == null
        ? const <TenantDashboardMetric>[]
        : dashboard.metrics.where(access.canViewMetric).toList(growable: false);

    final attentionItems = dashboard == null
        ? const <TenantDashboardAttentionItem>[]
        : dashboard.needsAttention
            .where(access.canViewAttentionItem)
            .toList(growable: false);

    final quickActions = dashboard == null
        ? const <TenantDashboardQuickAction>[]
        : dashboard.quickActions
            .where(access.canViewQuickAction)
            .toList(growable: false);

    final activities = dashboard == null
        ? const <TenantDashboardActivity>[]
        : dashboard.recentActivity
            .where(access.canViewActivityItem)
            .toList(growable: false);

    final showRecentActivity = access.canViewRecentActivitySection();

    return TenantDashboardVisibility(
      showTitle:
          access.can(TenantAdminPermissionCodes.tenantAdminDashboardView),
      showSubtitle:
          access.can(TenantAdminPermissionCodes.tenantAdminDashboardView),
      showNotifications: access.canViewNotifications(),
      showNotificationReadAction: access.canReadNotifications(),
      showProfile: access.canViewProfile(),
      showTenantContext: access.canViewTenantContext(),
      showSubscription: access.canViewSubscription(),
      showDateFilter: access.canViewDateFilter(),
      showOutletFilter: access.canViewOutletFilter(),
      showSalesTrend: access.canViewSalesTrend(),
      showReportsLink: access.canViewReportsLink(),
      showNeedsAttentionViewAll: access.canViewNeedsAttentionViewAll(
        hasVisibleItems: attentionItems.isNotEmpty,
      ),
      showAllActivityLink: access.canViewAllActivityLink(),
      showSalesChart:
          access.canViewSalesChart() && dashboard?.salesThisWeek != null,
      showNeedsAttentionSection:
          access.canViewNeedsAttentionSection() && attentionItems.isNotEmpty,
      showQuickActionsSection: quickActions.isNotEmpty,
      showRecentActivitySection: showRecentActivity && activities.isNotEmpty,
      showKpiSection: metrics.isNotEmpty,
      visibleMetrics: metrics,
      visibleAttentionItems: attentionItems,
      visibleQuickActions: quickActions,
      visibleActivities: activities,
      notificationCount:
          access.canViewNotifications() ? dashboard?.notificationCount : null,
      salesSummary:
          access.canViewSalesChart() ? dashboard?.salesThisWeek : null,
    );
  }
}

class OutletListVisibility {
  const OutletListVisibility({
    required this.showPage,
    required this.showTitle,
    required this.showSubtitle,
    required this.showSearch,
    required this.showFilter,
    required this.showAddOutlet,
    required this.showSummarySection,
    required this.showList,
    required this.showPagination,
    required this.showMobileStatusBadge,
    required this.showMobileLocation,
    required this.showMobileTillSummary,
    required this.showMobileStaffSummary,
    required this.showMobileSales,
    required this.showMobileActionsMenu,
    required this.showActionsColumn,
    required this.visibleSummaryCards,
    required this.visibleColumns,
    required this.visibleRowActions,
  });

  final bool showPage;
  final bool showTitle;
  final bool showSubtitle;
  final bool showSearch;
  final bool showFilter;
  final bool showAddOutlet;
  final bool showSummarySection;
  final bool showList;
  final bool showPagination;
  final bool showMobileStatusBadge;
  final bool showMobileLocation;
  final bool showMobileTillSummary;
  final bool showMobileStaffSummary;
  final bool showMobileSales;
  final bool showMobileActionsMenu;
  final bool showActionsColumn;
  final List<OutletSummaryCardConfig> visibleSummaryCards;
  final List<OutletTableColumnConfig> visibleColumns;
  final List<OutletRowActionConfig> visibleRowActions;

  static OutletListVisibility resolve({
    required TenantAdminAccessChecker access,
  }) {
    final showPage = access.canAccessOutletListPage();
    final rowActions = visibleOutletRowActions(access.can, access.canAny);
    final showActionsColumn = rowActions.isNotEmpty;
    final summaryCards = showPage
        ? visibleOutletSummaryCards(access.can, access.canAny)
        : const <OutletSummaryCardConfig>[];
    final columns = showPage
        ? visibleOutletTableColumns(
            access.can,
            access.canAny,
            showActionsColumn: showActionsColumn,
          )
        : const <OutletTableColumnConfig>[];

    return OutletListVisibility(
      showPage: showPage,
      showTitle: showPage,
      showSubtitle: showPage,
      showSearch: showPage,
      showFilter: showPage && access.canViewOutletListFilter(),
      showAddOutlet: access.canCreateOutlet(),
      showSummarySection: summaryCards.isNotEmpty,
      showList: showPage,
      showPagination: showPage,
      showMobileStatusBadge: showPage && access.canViewOutletStatus(),
      showMobileLocation: showPage && access.canViewOutletLocation(),
      showMobileTillSummary: showPage && access.canViewOutletTillSummary(),
      showMobileStaffSummary: showPage && access.canViewOutletStaffSummary(),
      showMobileSales: showPage && access.canViewOutletSalesSummary(),
      showMobileActionsMenu: showActionsColumn,
      showActionsColumn: showActionsColumn,
      visibleSummaryCards: summaryCards,
      visibleColumns: columns,
      visibleRowActions: rowActions,
    );
  }
}

class TillListVisibility {
  const TillListVisibility({
    required this.showPage,
    required this.showTitle,
    required this.showSubtitle,
    required this.showSearch,
    required this.showFilters,
    required this.showAddTill,
    required this.showSummarySection,
    required this.showList,
    required this.showPagination,
    required this.showTodaySales,
    required this.showMoreMenu,
    required this.showActionsColumn,
    required this.visibleSummaryCards,
    required this.visibleRowActions,
    required this.visibleMoreMenuActions,
  });

  final bool showPage;
  final bool showTitle;
  final bool showSubtitle;
  final bool showSearch;
  final bool showFilters;
  final bool showAddTill;
  final bool showSummarySection;
  final bool showList;
  final bool showPagination;
  final bool showTodaySales;
  final bool showMoreMenu;
  final bool showActionsColumn;
  final List<TillSummaryCardConfig> visibleSummaryCards;
  final List<TillRowActionConfig> visibleRowActions;
  final List<TillRowActionConfig> visibleMoreMenuActions;

  static TillListVisibility resolve({
    required TenantAdminAccessChecker access,
  }) {
    final showPage = access.canAccessTillListPage();
    final rowActions = showPage
        ? visibleTillRowActions(access.can, access.canAny)
        : const <TillRowActionConfig>[];
    final moreMenuActions = showPage
        ? visibleTillMoreMenuActions(access.can, access.canAny)
        : const <TillRowActionConfig>[];
    final summaryCards = showPage
        ? visibleTillSummaryCards(access.can, access.canAny)
        : const <TillSummaryCardConfig>[];

    return TillListVisibility(
      showPage: showPage,
      showTitle: showPage,
      showSubtitle: showPage,
      showSearch: showPage,
      showFilters: showPage,
      showAddTill: access.canCreateTill(),
      showSummarySection: summaryCards.isNotEmpty,
      showList: showPage,
      showPagination: showPage,
      showTodaySales: showPage && access.canViewTillSales(),
      showMoreMenu: moreMenuActions.isNotEmpty,
      showActionsColumn: rowActions.isNotEmpty || moreMenuActions.isNotEmpty,
      visibleSummaryCards: summaryCards,
      visibleRowActions: rowActions,
      visibleMoreMenuActions: moreMenuActions,
    );
  }
}

class UserListVisibility {
  const UserListVisibility({
    required this.showPage,
    required this.showTitle,
    required this.showSubtitle,
    required this.showSearch,
    required this.showStatusFilter,
    required this.showAddUser,
    required this.showList,
    required this.showPagination,
    required this.showActionsColumn,
    required this.visibleRowActions,
  });

  final bool showPage;
  final bool showTitle;
  final bool showSubtitle;
  final bool showSearch;
  final bool showStatusFilter;
  final bool showAddUser;
  final bool showList;
  final bool showPagination;
  final bool showActionsColumn;
  final List<UserRowActionConfig> visibleRowActions;

  static UserListVisibility resolve({
    required TenantAdminAccessChecker access,
  }) {
    final showPage = access.canAccessUserListPage();
    final rowActions = showPage
        ? visibleUserRowActions(access.can, access.canAny)
        : const <UserRowActionConfig>[];

    return UserListVisibility(
      showPage: showPage,
      showTitle: showPage,
      showSubtitle: showPage,
      showSearch: showPage,
      showStatusFilter: showPage,
      showAddUser: access.canAddUser(),
      showList: showPage,
      showPagination: showPage,
      showActionsColumn: rowActions.isNotEmpty,
      visibleRowActions: rowActions,
    );
  }
}

class ProductListVisibility {
  const ProductListVisibility({
    required this.showPage,
    required this.showTitle,
    required this.showSubtitle,
    required this.showSearch,
    required this.showAddProduct,
    required this.showSummarySection,
    required this.showList,
    required this.showPagination,
    required this.showActionsColumn,
    required this.showViewAction,
    required this.showEditAction,
    required this.showStatusAction,
    required this.showDeleteAction,
    required this.showStockColumn,
  });

  final bool showPage;
  final bool showTitle;
  final bool showSubtitle;
  final bool showSearch;
  final bool showAddProduct;
  final bool showSummarySection;
  final bool showList;
  final bool showPagination;
  final bool showActionsColumn;
  final bool showViewAction;
  final bool showEditAction;
  final bool showStatusAction;
  final bool showDeleteAction;
  final bool showStockColumn;

  static ProductListVisibility resolve({
    required TenantAdminAccessChecker access,
  }) {
    final showPage = access.canAccessProductListPage();
    final showViewAction = showPage && access.canViewProductDetail();
    final showEditAction = showPage && access.canUpdateProduct();
    final showStatusAction = showPage && access.canUpdateProduct();
    final showDeleteAction = showPage && access.canDeleteProduct();
    final showStockColumn = showPage && access.canViewStock();

    return ProductListVisibility(
      showPage: showPage,
      showTitle: showPage,
      showSubtitle: showPage,
      showSearch: showPage,
      showAddProduct: access.canCreateProduct(),
      showSummarySection: access.canFetchProductSummary(),
      showList: showPage,
      showPagination: showPage,
      showActionsColumn: showViewAction ||
          showEditAction ||
          showStatusAction ||
          showDeleteAction,
      showViewAction: showViewAction,
      showEditAction: showEditAction,
      showStatusAction: showStatusAction,
      showDeleteAction: showDeleteAction,
      showStockColumn: showStockColumn,
    );
  }
}

class BrandListVisibility {
  const BrandListVisibility({
    required this.showPage,
    required this.showTitle,
    required this.showSubtitle,
    required this.showSearch,
    required this.showAddBrand,
    required this.showList,
    required this.showEditBrand,
    required this.showDeleteBrand,
  });

  final bool showPage;
  final bool showTitle;
  final bool showSubtitle;
  final bool showSearch;
  final bool showAddBrand;
  final bool showList;
  final bool showEditBrand;
  final bool showDeleteBrand;

  static BrandListVisibility resolve({
    required TenantAdminAccessChecker access,
  }) {
    final showPage = access.canFetchBrandList();

    return BrandListVisibility(
      showPage: showPage,
      showTitle: showPage,
      showSubtitle: showPage,
      showSearch: showPage,
      showAddBrand: access.canCreateBrand(),
      showList: showPage,
      showEditBrand: access.canUpdateBrand(),
      showDeleteBrand: access.canDeleteBrand(),
    );
  }
}

class CurrentStockVisibility {
  const CurrentStockVisibility({
    required this.showPage,
    required this.showTitle,
    required this.showSubtitle,
    required this.showSummarySection,
    required this.showFilters,
    required this.showList,
    required this.showPagination,
    required this.showStockInAction,
  });

  final bool showPage;
  final bool showTitle;
  final bool showSubtitle;
  final bool showSummarySection;
  final bool showFilters;
  final bool showList;
  final bool showPagination;
  final bool showStockInAction;

  static CurrentStockVisibility resolve({
    required TenantAdminAccessChecker access,
  }) {
    final showPage = access.canAccessCurrentStockPage();

    return CurrentStockVisibility(
      showPage: showPage,
      showTitle: showPage,
      showSubtitle: showPage,
      showSummarySection: access.canFetchCurrentStockSummary(),
      showFilters: showPage,
      showList: showPage,
      showPagination: showPage,
      showStockInAction: access.canStockIn(),
    );
  }
}

class StockInVisibility {
  const StockInVisibility({
    required this.showPage,
    required this.showTitle,
    required this.showSubtitle,
    required this.showForm,
    required this.showSubmitAction,
  });

  final bool showPage;
  final bool showTitle;
  final bool showSubtitle;
  final bool showForm;
  final bool showSubmitAction;

  static StockInVisibility resolve({
    required TenantAdminAccessChecker access,
  }) {
    final showPage = access.canAccessStockInPage();

    return StockInVisibility(
      showPage: showPage,
      showTitle: showPage,
      showSubtitle: showPage,
      showForm: showPage,
      showSubmitAction: showPage,
    );
  }
}

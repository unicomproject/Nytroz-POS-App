import '../../../../core/access/tenant_admin_access_codes.dart';
import '../../../../core/access/tenant_admin_permission_aliases.dart';
import '../../dashboard/presentation/config/dashboard_metric_configs.dart';
import '../../dashboard/presentation/config/dashboard_needs_attention_configs.dart';
import '../../dashboard/presentation/config/dashboard_permission_config.dart';
import '../../dashboard/presentation/config/dashboard_quick_action_configs.dart';
import '../../outlets/presentation/config/outlet_row_action_configs.dart';
import '../../outlets/presentation/config/outlet_summary_card_configs.dart';
import '../../outlets/presentation/config/outlet_table_column_configs.dart';
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
        return can(TenantAdminPermissionCodes.outletView);
      case TenantAdminFeatureCodes.tillManagement:
        return canAny([
          TenantAdminPermissionCodes.tillView,
          TenantAdminPermissionCodes.tenantTillManage,
        ]);
      case TenantAdminFeatureCodes.staffManagement:
        return canAny([
          TenantAdminPermissionCodes.userView,
          TenantAdminPermissionCodes.tenantUserManage,
        ]);
      case TenantAdminFeatureCodes.rolePermission:
        return canAny([
          TenantAdminPermissionCodes.rolesPermissionsView,
          TenantAdminPermissionCodes.rolesPermissionsUpdate,
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
        return can(TenantAdminPermissionCodes.inventoryView);
      case TenantAdminFeatureCodes.reportsAnalytics:
        return can(TenantAdminPermissionCodes.reportView);
      case TenantAdminFeatureCodes.sales:
        return canAny([
          TenantAdminPermissionCodes.dashboardSalesSummaryView,
          TenantAdminPermissionCodes.dashboardOrdersSummaryView,
        ]);
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

  bool canFetchDashboardSummary() => canLoadDashboardData();

  /// Returns true when any dashboard widget permission requires API payload data.
  /// TODO: split dashboard API by section when backend supports field-level filtering.
  bool canLoadDashboardData() {
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

  bool canViewNeedsAttentionSection() {
    return can(TenantAdminPermissionCodes.dashboardAttentionView);
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
    return can(TenantAdminPermissionCodes.activityLogView);
  }

  bool canViewSalesChart() {
    return can(TenantAdminPermissionCodes.dashboardSalesChartView);
  }

  bool canViewMetric(TenantDashboardMetric metric) {
    final config = metricConfigForKey(metric.key);
    if (config == null) {
      return false;
    }

    return dashboardWidgetAllowed(config, can, canAny);
  }

  bool canViewAttentionItem(TenantDashboardAttentionItem item) {
    if (!canViewNeedsAttentionSection()) {
      return false;
    }

    final config = needsAttentionConfigForKey(item.key);
    if (config == null) {
      return false;
    }

    return dashboardWidgetAllowed(config, can, canAny);
  }

  bool canViewQuickAction(TenantDashboardQuickAction action) {
    final config = quickActionConfigForKey(action.key);
    if (config != null) {
      return dashboardWidgetAllowed(config, can, canAny);
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

  /// TODO: replace [outletView] fallback with [outletFilterView] only once seeded.
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

  bool canViewOutletDetail() {
    return canShowActionWithAnyPermission(
      TenantAdminFeatureCodes.outletManagement,
      [
        TenantAdminPermissionCodes.outletDetailView,
        TenantAdminPermissionCodes.outletView,
      ],
    );
  }

  bool canEditOutlet() {
    return canShowAction(
      TenantAdminFeatureCodes.outletManagement,
      TenantAdminPermissionCodes.outletUpdate,
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

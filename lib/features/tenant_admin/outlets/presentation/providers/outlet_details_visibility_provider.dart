import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/access/tenant_admin_access_codes.dart';
import '../../../domain/services/tenant_admin_access_checker.dart';
import '../../../presentation/providers/tenant_admin_access_provider.dart';
import '../config/outlet_details_metric_configs.dart';
import '../config/outlet_details_quick_action_configs.dart';
import '../config/outlet_details_tab_configs.dart';

class OutletDetailsVisibility {
  const OutletDetailsVisibility({
    required this.showSummaryMetrics,
    required this.showPerformance,
    required this.showAssignedTills,
    required this.showStaff,
    required this.showNeedsAttention,
    required this.showQuickActions,
    required this.visibleMetrics,
    required this.visibleTabs,
    required this.visibleQuickActions,
  });

  final bool showSummaryMetrics;
  final bool showPerformance;
  final bool showAssignedTills;
  final bool showStaff;
  final bool showNeedsAttention;
  final bool showQuickActions;
  final List<OutletDetailsMetricConfig> visibleMetrics;
  final List<OutletDetailsTabConfig> visibleTabs;
  final List<OutletDetailsQuickActionConfig> visibleQuickActions;

  static OutletDetailsVisibility resolve({
    required TenantAdminAccessChecker access,
  }) {
    final metrics = visibleOutletDetailsMetrics(access.can, access.canAny);
    final tabs = visibleOutletDetailsTabs(access.can, access.canAny);
    final quickActions =
        visibleOutletDetailsQuickActions(access.can, access.canAny);

    final canViewSales =
        access.can(TenantAdminPermissionCodes.outletSalesSummaryView);
    final canViewTills = access.canAny([
      TenantAdminPermissionCodes.tillView,
      TenantAdminPermissionCodes.outletTillSummaryView,
    ]);
    final canViewStaff = access.canAny([
      TenantAdminPermissionCodes.userView,
      TenantAdminPermissionCodes.outletStaffSummaryView,
    ]);

    return OutletDetailsVisibility(
      showSummaryMetrics: metrics.isNotEmpty,
      showPerformance: canViewSales,
      showAssignedTills: canViewTills,
      showStaff: canViewStaff,
      showNeedsAttention: canViewTills || canViewStaff,
      showQuickActions: quickActions.isNotEmpty,
      visibleMetrics: metrics,
      visibleTabs: tabs,
      visibleQuickActions: quickActions,
    );
  }
}

final outletDetailsVisibilityProvider =
    Provider<AsyncValue<OutletDetailsVisibility>>((ref) {
  final accessState = ref.watch(tenantAdminAccessCheckerProvider);

  return accessState.when(
    loading: () => const AsyncLoading(),
    error: AsyncError.new,
    data: (accessChecker) => AsyncData(
      OutletDetailsVisibility.resolve(access: accessChecker),
    ),
  );
});

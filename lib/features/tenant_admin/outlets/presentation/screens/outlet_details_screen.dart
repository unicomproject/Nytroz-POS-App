import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/entities/outlet_details.dart';
import '../../../presentation/theme/tenant_admin_theme.dart';
import '../../../presentation/widgets/tenant_admin_buttons.dart';
import '../../../presentation/widgets/tenant_admin_page_scaffold.dart';
import '../../../presentation/widgets/tenant_admin_states.dart';
import '../providers/outlet_details_visibility_provider.dart';
import '../providers/outlet_providers.dart';
import '../widgets/outlet_details_header.dart';
import '../widgets/outlet_details_overview_tab.dart';
import '../widgets/outlet_details_summary_row.dart';
import '../widgets/outlet_details_tills_card.dart';
import '../widgets/outlet_details_staff_card.dart';
import '../widgets/outlet_details_performance_card.dart';
import '../widgets/outlet_tabs.dart';

class OutletDetailsScreen extends ConsumerStatefulWidget {
  const OutletDetailsScreen({
    super.key,
    required this.outletId,
  });

  final String outletId;

  @override
  ConsumerState<OutletDetailsScreen> createState() =>
      _OutletDetailsScreenState();
}

class _OutletDetailsScreenState extends ConsumerState<OutletDetailsScreen> {
  var _selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    final detailsState = ref.watch(outletDetailsProvider(widget.outletId));
    final visibilityState = ref.watch(outletDetailsVisibilityProvider);

    return detailsState.when(
      loading: () => const TenantAdminPageScaffold(
        title: 'Outlet details',
        subtitle: 'View and manage this outlet in one place.',
        child: TenantAdminLoadingSkeleton(rowCount: 8),
      ),
      error: (error, stackTrace) => TenantAdminPageScaffold(
        title: 'Outlet details',
        subtitle: 'View and manage this outlet in one place.',
        child: TenantAdminErrorState(
          title: 'Unable to load outlet',
          message: 'Please try again.',
          onRetry: () => ref.refresh(outletDetailsProvider(widget.outletId)),
        ),
      ),
      data: (outlet) => visibilityState.when(
        loading: () => const TenantAdminPageScaffold(
          title: 'Outlet details',
          subtitle: 'View and manage this outlet in one place.',
          child: TenantAdminLoadingSkeleton(rowCount: 8),
        ),
        error: (error, stackTrace) => TenantAdminPageScaffold(
          title: 'Outlet details',
          subtitle: 'View and manage this outlet in one place.',
          child: TenantAdminErrorState(
            title: 'Unable to load permissions',
            message: 'Please try again.',
            onRetry: () => ref.refresh(outletDetailsVisibilityProvider),
          ),
        ),
        data: (visibility) {
          final tabs = visibility.visibleTabs;
          final selectedTab = tabs.isEmpty
              ? 0
              : _selectedTab.clamp(0, tabs.length - 1);

          return TenantAdminPageScaffold(
            title: 'Outlet details',
            subtitle: 'View and manage this outlet in one place.',
            actions: [
              TenantAdminSecondaryButton(
                label: 'Back to outlets',
                icon: Icons.arrow_back,
                onPressed: () => context.go('/tenant-admin/outlets'),
              ),
            ],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                OutletDetailsHeader(outlet: outlet),
                const SizedBox(height: TenantAdminSpacing.lg),
                if (visibility.showSummaryMetrics) ...[
                  OutletDetailsSummaryRow(
                    outlet: outlet,
                    metrics: visibility.visibleMetrics,
                  ),
                  const SizedBox(height: TenantAdminSpacing.lg),
                ],
                if (tabs.isNotEmpty) ...[
                  OutletTabs(
                    tabs: tabs,
                    selectedIndex: selectedTab,
                    onChanged: (index) => setState(() => _selectedTab = index),
                  ),
                  const SizedBox(height: TenantAdminSpacing.lg),
                  _TabContent(
                    tabId: tabs[selectedTab].id,
                    outlet: outlet,
                    visibility: visibility,
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _TabContent extends StatelessWidget {
  const _TabContent({
    required this.tabId,
    required this.outlet,
    required this.visibility,
  });

  final String tabId;
  final OutletDetails outlet;
  final OutletDetailsVisibility visibility;

  @override
  Widget build(BuildContext context) {
    switch (tabId) {
      case 'overview':
        return OutletDetailsOverviewTab(
          outlet: outlet,
          visibility: visibility,
        );
      case 'tills':
        return OutletDetailsTillsCard(tills: outlet.assignedTills);
      case 'staff':
        return OutletDetailsStaffCard(staff: outlet.staff);
      case 'sales':
        return OutletDetailsPerformanceCard(outlet: outlet);
      case 'settings':
        return const OutletDetailsPlaceholderTab(
          title: 'Outlet settings',
          message: 'Outlet settings will be available in a future update.',
        );
      default:
        return const SizedBox.shrink();
    }
  }
}

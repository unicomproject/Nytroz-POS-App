import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../presentation/providers/tenant_admin_access_provider.dart';
import '../../../presentation/theme/tenant_admin_theme.dart';
import '../../../presentation/widgets/tenant_admin_buttons.dart';
import '../../../presentation/widgets/tenant_admin_metric_card.dart';
import '../../../presentation/widgets/tenant_admin_page_scaffold.dart';
import '../../../presentation/widgets/tenant_admin_quick_action_card.dart';
import '../../../presentation/widgets/tenant_admin_states.dart';
import '../../../presentation/widgets/tenant_admin_status_badge.dart';
import '../providers/outlet_providers.dart';
import '../widgets/outlet_details_header.dart';
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
    final accessState = ref.watch(tenantAdminAccessCheckerProvider);
    final canUpdate = accessState.maybeWhen(
      data: (checker) => checker.canShowAction(
        'tenant_admin.outlets',
        'outlets.update',
      ),
      orElse: () => false,
    );
    final canAddTill = accessState.maybeWhen(
      data: (checker) =>
          checker.canShowAction('tenant_admin.tills', 'tills.create'),
      orElse: () => false,
    );
    final canAddStaff = accessState.maybeWhen(
      data: (checker) =>
          checker.canShowAction('tenant_admin.staff', 'staff.create'),
      orElse: () => false,
    );
    final canViewReports = accessState.maybeWhen(
      data: (checker) => checker.canShowAction('reports', 'reports.view'),
      orElse: () => false,
    );

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
      data: (outlet) => TenantAdminPageScaffold(
        title: 'Outlet details',
        subtitle: 'View and manage this outlet in one place.',
        actions: [
          TenantAdminSecondaryButton(
            label: 'Back to outlets',
            icon: Icons.arrow_back,
            onPressed: () => context.go('/tenant-admin/outlets'),
          ),
          if (canUpdate)
            TenantAdminPrimaryButton(
              label: 'Edit outlet',
              icon: Icons.edit,
              onPressed: () =>
                  context.go('/tenant-admin/outlets/${outlet.id}/edit'),
            ),
        ],
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            OutletDetailsHeader(outlet: outlet),
            const SizedBox(height: 16),
            GridView.count(
              crossAxisCount: MediaQuery.of(context).size.width < 700 ? 2 : 4,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio:
                  MediaQuery.of(context).size.width < 700 ? 1.08 : 1.55,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                for (final metric in outlet.metrics)
                  TenantAdminMetricCard(
                    title: metric.title,
                    value: metric.value,
                    subtitle: metric.subtitle,
                    icon: Icons.insert_chart,
                  ),
              ],
            ),
            const SizedBox(height: 16),
            OutletTabs(
              selectedIndex: _selectedTab,
              onChanged: (index) => setState(() => _selectedTab = index),
            ),
            const SizedBox(height: 16),
            _DetailsTabContent(selectedTab: _selectedTab, outletId: outlet.id),
            const SizedBox(height: 24),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                if (canUpdate)
                  SizedBox(
                    width: 220,
                    child: TenantAdminQuickActionCard(
                      title: 'Edit outlet',
                      icon: Icons.edit,
                      onTap: () =>
                          context.go('/tenant-admin/outlets/${outlet.id}/edit'),
                    ),
                  ),
                if (canAddTill)
                  SizedBox(
                    width: 220,
                    child: TenantAdminQuickActionCard(
                      title: 'Add till',
                      icon: Icons.payment,
                      onTap: () => context.go('/tenant-admin/tills/add'),
                    ),
                  ),
                if (canAddStaff)
                  SizedBox(
                    width: 220,
                    child: TenantAdminQuickActionCard(
                      title: 'Add staff',
                      icon: Icons.person_add,
                      onTap: () => context.go('/tenant-admin/staff/add'),
                    ),
                  ),
                if (canViewReports)
                  SizedBox(
                    width: 220,
                    child: TenantAdminQuickActionCard(
                      title: 'View sales report',
                      icon: Icons.insert_chart,
                      onTap: () => context.go('/tenant-admin/reports/sales'),
                    ),
                  ),
              ],
            ),
            if (outlet.needsAttention.isNotEmpty) ...[
              const SizedBox(height: 24),
              Text('Needs attention',
                  style: TenantAdminTextStyles.sectionTitle(context)),
              const SizedBox(height: 12),
              for (final item in outlet.needsAttention)
                ListTile(
                  leading: const Icon(Icons.warning,
                      color: TenantAdminColors.warning),
                  title: Text(item.title),
                  subtitle: Text(item.message),
                  trailing: TenantAdminStatusBadge(
                    label: item.status ?? 'Warning',
                    status: TenantAdminStatusType.warning,
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DetailsTabContent extends StatelessWidget {
  const _DetailsTabContent({
    required this.selectedTab,
    required this.outletId,
  });

  final int selectedTab;
  final String outletId;

  @override
  Widget build(BuildContext context) {
    const labels = OutletTabs.labels;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: TenantAdminColors.surface,
        border: Border.all(color: TenantAdminColors.border),
        borderRadius: BorderRadius.circular(TenantAdminRadius.lg),
      ),
      child: Text('${labels[selectedTab]} content for outlet $outletId'),
    );
  }
}

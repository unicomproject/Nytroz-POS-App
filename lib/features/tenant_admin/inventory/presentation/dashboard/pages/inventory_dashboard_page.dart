import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../presentation/theme/tenant_admin_theme.dart';
import '../../../../presentation/widgets/tenant_admin_page_scaffold.dart';
import '../../../../presentation/widgets/tenant_admin_states.dart';
import '../../../../presentation/providers/tenant_admin_access_provider.dart';
import '../../../../presentation/widgets/tenant_admin_metric_card.dart';
import '../../../../presentation/widgets/tenant_admin_status_badge.dart';
import '../providers/inventory_dashboard_providers.dart';
import '../widgets/inventory_activities_table.dart';
import '../widgets/inventory_alerts_table.dart';
import '../widgets/inventory_quick_actions.dart';

class InventoryDashboardPage extends ConsumerWidget {
  const InventoryDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return TenantAdminPageScaffold(
      title: 'Inventory Dashboard',
      subtitle: 'Get a quick overview of your inventory health and take action on priority items.',
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const InventoryHeader(),
                const SizedBox(height: TenantAdminSpacing.lg),
                _buildMetrics(ref, width),
                const SizedBox(height: TenantAdminSpacing.lg),
                const InventoryQuickActions(),
                const SizedBox(height: TenantAdminSpacing.lg),
                _buildTables(ref, width),
                const SizedBox(height: 24.0), // Bottom padding
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMetrics(WidgetRef ref, double width) {
    final metricsState = ref.watch(inventoryDashboardMetricsProvider);

    return metricsState.when(
      data: (metrics) {
        final cards = [
          TenantAdminMetricCard(
            title: 'Low Stock Items',
            value: metrics.lowStockCount.toString(),
            subtitle: 'Reorder soon',
            icon: Icons.warning_amber_rounded,
            status: TenantAdminStatusType.danger,
          ),
          TenantAdminMetricCard(
            title: 'Out of Stock',
            value: metrics.outOfStockCount.toString(),
            subtitle: 'Needs attention',
            icon: Icons.remove_shopping_cart_outlined,
            status: TenantAdminStatusType.danger,
          ),
          TenantAdminMetricCard(
            title: 'Near Expiry',
            value: metrics.nearExpiryCount.toString(),
            subtitle: 'Within 30 days',
            icon: Icons.hourglass_empty_outlined,
            status: TenantAdminStatusType.warning,
          ),
          TenantAdminMetricCard(
            title: 'Active Stock Counts',
            value: metrics.activeStockCounts.toString(),
            subtitle: 'Across all outlets',
            icon: Icons.fact_check_outlined,
            status: TenantAdminStatusType.success,
          ),
        ];

        if (width < 600) {
          return Column(
            children: cards
                .map((c) => Padding(
                      padding:
                          const EdgeInsets.only(bottom: TenantAdminSpacing.md),
                      child: c,
                    ))
                .toList(),
          );
        }

        if (width < 1200) {
          return Column(
            children: [
              Row(
                children: [
                  Expanded(child: cards[0]),
                  const SizedBox(width: TenantAdminSpacing.md),
                  Expanded(child: cards[1]),
                ],
              ),
              const SizedBox(height: TenantAdminSpacing.md),
              Row(
                children: [
                  Expanded(child: cards[2]),
                  const SizedBox(width: TenantAdminSpacing.md),
                  Expanded(child: cards[3]),
                ],
              ),
            ],
          );
        }

        return Row(
          children: [
            Expanded(child: cards[0]),
            const SizedBox(width: TenantAdminSpacing.lg),
            Expanded(child: cards[1]),
            const SizedBox(width: TenantAdminSpacing.lg),
            Expanded(child: cards[2]),
            const SizedBox(width: TenantAdminSpacing.lg),
            Expanded(child: cards[3]),
          ],
        );
      },
      loading: () => const Center(
          child: Padding(
        padding: EdgeInsets.all(TenantAdminSpacing.xxl),
        child: TenantAdminLoadingSkeleton(rowCount: 2),
      )),
      error: (error, stack) => TenantAdminErrorState(
        onRetry: () => ref.refresh(inventoryDashboardMetricsProvider),
        title: 'Error loading dashboard',
        message: error.toString(),
      ),
    );
  }

  Widget _buildTables(WidgetRef ref, double width) {
    final accessChecker =
        ref.watch(tenantAdminAccessCheckerProvider).valueOrNull;
    final showAlerts = accessChecker?.canViewInventoryAlerts() ?? true;
    final alertsState = ref.watch(inventoryDashboardAlertsProvider);
    final activitiesState = ref.watch(inventoryDashboardActivitiesProvider);

    final alertsWidget = alertsState.when(
      data: (data) => InventoryAlertsTable(alerts: data.items),
      loading: () => const Padding(
        padding: EdgeInsets.only(top: TenantAdminSpacing.lg),
        child: TenantAdminLoadingSkeleton(rowCount: 6),
      ),
      error: (error, stack) => const Text('Failed to load alerts'),
    );

    final activitiesWidget = activitiesState.when(
      data: (data) => InventoryActivitiesTable(activities: data.items),
      loading: () => const Padding(
        padding: EdgeInsets.only(top: TenantAdminSpacing.lg),
        child: TenantAdminLoadingSkeleton(rowCount: 6),
      ),
      error: (error, stack) => const Text('Failed to load activities'),
    );

    if (width < 1280) {
      return Column(
        children: [
          if (showAlerts) ...[
            alertsWidget,
            const SizedBox(height: TenantAdminSpacing.lg),
          ],
          activitiesWidget,
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showAlerts) ...[
          Expanded(child: alertsWidget),
          const SizedBox(width: TenantAdminSpacing.xl),
        ],
        Expanded(child: activitiesWidget),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../presentation/theme/tenant_admin_theme.dart';
import '../../../../presentation/widgets/tenant_admin_page_scaffold.dart';
import '../../../../presentation/widgets/tenant_admin_states.dart';
import '../../../../presentation/providers/tenant_admin_access_provider.dart';
import '../providers/inventory_dashboard_providers.dart';
import '../widgets/inventory_activities_table.dart';
import '../widgets/inventory_alerts_table.dart';
import '../widgets/inventory_header.dart';
import '../widgets/inventory_metric_cards.dart';
import '../widgets/inventory_quick_actions.dart';

class InventoryDashboardPage extends ConsumerWidget {
  const InventoryDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return TenantAdminPageScaffold(
      title: '',
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;

          return Column(
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
          InventoryMetricCard(
            title: 'Low Stock Items',
            value: metrics.lowStockCount.toString(),
            subtitle: 'Below reorder level',
            iconData: Icons.warning_amber_rounded,
            color: Colors.red,
          ),
          InventoryMetricCard(
            title: 'Out of Stock Items',
            value: metrics.outOfStockCount.toString(),
            subtitle: 'No sellable stock',
            iconData: Icons.remove_shopping_cart_outlined,
            color: Colors.red,
          ),
          InventoryMetricCard(
            title: 'Near Expiry Items',
            value: metrics.nearExpiryCount.toString(),
            subtitle: 'Within 30 days',
            iconData: Icons.hourglass_empty_outlined,
            color: Colors.orange,
          ),
          InventoryMetricCard(
            title: 'Active Stock Counts',
            value: metrics.activeStockCounts.toString(),
            subtitle: 'In progress',
            iconData: Icons.fact_check_outlined,
            color: Colors.green,
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

        if (width < 1100) {
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

    if (width < 1100) {
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

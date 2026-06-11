import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/tenant_admin_access_provider.dart';
import '../../../widgets/tenant_admin_page_scaffold.dart';
import '../../../widgets/tenant_admin_states.dart';
import '../../domain/entities/tenant_dashboard.dart';
import '../providers/tenant_dashboard_provider.dart';
import '../widgets/dashboard_metric_grid.dart';
import '../widgets/dashboard_quick_actions_card.dart';
import '../widgets/needs_attention_card.dart';
import '../widgets/recent_activity_card.dart';
import '../widgets/sales_this_week_card.dart';

class TenantDashboardScreen extends ConsumerWidget {
  const TenantDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardState = ref.watch(tenantDashboardProvider);
    final accessState = ref.watch(tenantAdminAccessCheckerProvider);

    return dashboardState.when(
      loading: () {
        return const TenantAdminPageScaffold(
          title: 'Dashboard',
          subtitle: 'Tenant operations overview',
          child: TenantAdminLoadingSkeleton(rowCount: 8),
        );
      },
      error: (error, stackTrace) {
        return TenantAdminPageScaffold(
          title: 'Dashboard',
          subtitle: 'Tenant operations overview',
          child: TenantAdminErrorState(
            title: 'Unable to load dashboard',
            message: 'Please try again. If the issue continues, contact support.',
            onRetry: () => ref.refresh(tenantDashboardProvider),
          ),
        );
      },
      data: (dashboard) {
        if (dashboard.isEmpty) {
          return const TenantAdminPageScaffold(
            title: 'Dashboard',
            subtitle: 'Tenant operations overview',
            child: TenantAdminEmptyState(
              title: 'Dashboard is empty',
              message: 'Dashboard data will appear here when available.',
            ),
          );
        }

        final quickActions = accessState.maybeWhen(
          data: (accessChecker) {
            return dashboard.quickActions.where((action) {
              return accessChecker.canShowAction(
                action.featureCode,
                action.permissionCode,
              );
            }).toList(growable: false);
          },
          orElse: () => <TenantDashboardQuickAction>[],
        );

        return LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth < 700;

            return TenantAdminPageScaffold(
              title: 'Dashboard',
              subtitle: 'Monitor today’s sales, operations, stock alerts, and recent activity.',
              child: isMobile
                  ? _MobileDashboard(
                      dashboard: dashboard,
                      quickActions: quickActions,
                    )
                  : _TabletDashboard(
                      dashboard: dashboard,
                      quickActions: quickActions,
                    ),
            );
          },
        );
      },
    );
  }
}

class _TabletDashboard extends StatelessWidget {
  const _TabletDashboard({
    required this.dashboard,
    required this.quickActions,
  });

  final TenantDashboard dashboard;
  final List<TenantDashboardQuickAction> quickActions;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        DashboardMetricGrid(
          metrics: dashboard.metrics,
          compact: false,
        ),
        const SizedBox(height: 24),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 2,
              child: SalesThisWeekCard(salesSummary: dashboard.salesThisWeek),
            ),
            const SizedBox(width: 24),
            Expanded(
              child: NeedsAttentionCard(items: dashboard.needsAttention),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: DashboardQuickActionsCard(actions: quickActions),
            ),
            const SizedBox(width: 24),
            Expanded(
              child: RecentActivityCard(items: dashboard.recentActivity),
            ),
          ],
        ),
      ],
    );
  }
}

class _MobileDashboard extends StatelessWidget {
  const _MobileDashboard({
    required this.dashboard,
    required this.quickActions,
  });

  final TenantDashboard dashboard;
  final List<TenantDashboardQuickAction> quickActions;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        DashboardMetricGrid(
          metrics: dashboard.metrics,
          compact: true,
        ),
        const SizedBox(height: 16),
        NeedsAttentionCard(items: dashboard.needsAttention),
        const SizedBox(height: 16),
        SalesThisWeekCard(salesSummary: dashboard.salesThisWeek),
        const SizedBox(height: 16),
        DashboardQuickActionsCard(actions: quickActions),
        const SizedBox(height: 16),
        RecentActivityCard(items: dashboard.recentActivity),
      ],
    );
  }
}

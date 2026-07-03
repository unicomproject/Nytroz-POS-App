import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../auth/presentation/providers/session_provider.dart';
import '../../../domain/services/tenant_admin_access_checker.dart';
import '../../../presentation/providers/tenant_admin_context_provider.dart';
import '../../../presentation/widgets/tenant_admin_page_scaffold.dart';
import '../../../presentation/widgets/tenant_admin_states.dart';
import '../providers/tenant_dashboard_provider.dart';
import '../widgets/dashboard_metric_grid.dart';
import '../widgets/dashboard_quick_actions_card.dart';
import '../widgets/needs_attention_card.dart';
import '../widgets/recent_activity_card.dart';
import '../widgets/sales_this_week_card.dart';
import '../widgets/tenant_admin_dashboard_header_actions.dart';

class TenantDashboardScreen extends ConsumerWidget {
  const TenantDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final visibilityState = ref.watch(tenantDashboardVisibilityProvider);
    final contextState = ref.watch(tenantAdminContextProvider);

    return visibilityState.when(
      loading: () {
        return const TenantAdminPageScaffold(
          title: 'Dashboard',
          subtitle: 'See how your business is doing today.',
          child: TenantAdminLoadingSkeleton(rowCount: 8),
        );
      },
      error: (error, stackTrace) {
        return TenantAdminPageScaffold(
          title: 'Dashboard',
          subtitle: 'See how your business is doing today.',
          child: TenantAdminErrorState(
            title: 'Unable to load dashboard',
            message:
                'Please try again. If the issue continues, contact support.',
            onRetry: () {
              ref.invalidate(tenantDashboardProvider);
              ref.invalidate(tenantAdminContextProvider);
            },
          ),
        );
      },
      data: (visibility) {
        if (!visibility.showTitle) {
          return const TenantAdminForbiddenScreenFallback();
        }

        final headerActions = contextState.maybeWhen(
          data: (tenantContext) => TenantAdminDashboardHeaderActions(
            visibility: visibility,
            context: tenantContext,
            onLogout: () => _logout(ref, context),
          ),
          orElse: () => TenantAdminDashboardHeaderActions(
            visibility: visibility,
            showLogoutOnly: true,
            onLogout: () => _logout(ref, context),
          ),
        );

        return LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth < 620;

            return TenantAdminPageScaffold(
              title: visibility.showTitle ? 'Dashboard' : '',
              subtitle: visibility.showSubtitle
                  ? 'See how your business is doing today.'
                  : null,
              actions: [headerActions],
              child: isMobile
                  ? _MobileDashboard(visibility: visibility)
                  : _TabletDashboard(visibility: visibility),
            );
          },
        );
      },
    );
  }
}

Future<void> _logout(WidgetRef ref, BuildContext context) async {
  await ref.read(authSessionProvider.notifier).clear();
  if (context.mounted) {
    context.go('/tenant-login');
  }
}

class TenantAdminForbiddenScreenFallback extends ConsumerWidget {
  const TenantAdminForbiddenScreenFallback({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const TenantAdminPageScaffold(
      title: 'No access to Dashboard',
      child: TenantAdminEmptyState(
        title: 'No access',
        message: 'You do not have permission to view the dashboard.',
      ),
    );
  }
}

class _TabletDashboard extends StatelessWidget {
  const _TabletDashboard({required this.visibility});

  final TenantDashboardVisibility visibility;

  @override
  Widget build(BuildContext context) {
    final sections = <Widget>[];
    final width = MediaQuery.sizeOf(context).width;
    final useStackedMiddle = width < 820;

    if (visibility.showKpiSection) {
      sections.add(
        DashboardMetricGrid(
          metrics: visibility.visibleMetrics.take(4).toList(growable: false),
          compact: false,
        ),
      );
    }

    final middleSections = <Widget>[];

    if (visibility.showSalesChart) {
      middleSections.add(
        SalesThisWeekCard(
          salesSummary: visibility.salesSummary,
          showTrend: visibility.showSalesTrend,
          showReportsLink: visibility.showReportsLink,
        ),
      );
    }

    if (visibility.showNeedsAttentionSection) {
      middleSections.add(
        NeedsAttentionCard(
          items: visibility.visibleAttentionItems,
          showViewAll: visibility.showNeedsAttentionViewAll,
        ),
      );
    }

    if (visibility.showQuickActionsSection) {
      middleSections.add(
        DashboardQuickActionsCard(
          actions: visibility.visibleQuickActions,
        ),
      );
    }

    if (middleSections.isNotEmpty) {
      if (sections.isNotEmpty) {
        sections.add(const SizedBox(height: 20));
      }

      if (useStackedMiddle) {
        for (var index = 0; index < middleSections.length; index++) {
          sections.add(middleSections[index]);
          if (index != middleSections.length - 1) {
            sections.add(const SizedBox(height: 20));
          }
        }
      } else {
        sections.add(
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (visibility.showSalesChart)
                Expanded(flex: width < 1040 ? 5 : 4, child: middleSections[0]),
              if (visibility.showSalesChart &&
                  (visibility.showNeedsAttentionSection ||
                      visibility.showQuickActionsSection))
                const SizedBox(width: 16),
              if (visibility.showNeedsAttentionSection)
                Expanded(
                  flex: width < 1040 ? 5 : 4,
                  child: middleSections[visibility.showSalesChart ? 1 : 0],
                ),
              if (visibility.showNeedsAttentionSection &&
                  visibility.showQuickActionsSection)
                const SizedBox(width: 16),
              if (visibility.showQuickActionsSection)
                Expanded(
                  flex: width < 1040 ? 4 : 3,
                  child: middleSections[(visibility.showSalesChart ? 1 : 0) +
                      (visibility.showNeedsAttentionSection ? 1 : 0)],
                ),
            ],
          ),
        );
      }
    }

    if (visibility.showRecentActivitySection) {
      if (sections.isNotEmpty) {
        sections.add(const SizedBox(height: 20));
      }

      sections.add(
        RecentActivityCard(
          items: visibility.visibleActivities,
          showViewAll: visibility.showAllActivityLink,
        ),
      );
    }

    if (sections.isEmpty) {
      return const TenantAdminEmptyState(
        title: 'Dashboard',
        message: 'No dashboard widgets available for your access.',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: sections,
    );
  }
}

class _MobileDashboard extends StatelessWidget {
  const _MobileDashboard({required this.visibility});

  final TenantDashboardVisibility visibility;

  @override
  Widget build(BuildContext context) {
    final sections = <Widget>[];

    void addSection(Widget section) {
      if (sections.isNotEmpty) {
        sections.add(const SizedBox(height: 16));
      }

      sections.add(section);
    }

    if (visibility.showKpiSection) {
      addSection(
        DashboardMetricGrid(
          metrics: visibility.visibleMetrics.take(4).toList(growable: false),
          compact: true,
        ),
      );
    }

    if (visibility.showNeedsAttentionSection) {
      addSection(
        NeedsAttentionCard(
          items: visibility.visibleAttentionItems,
          showViewAll: visibility.showNeedsAttentionViewAll,
        ),
      );
    }

    if (visibility.showSalesChart) {
      addSection(
        SalesThisWeekCard(
          salesSummary: visibility.salesSummary,
          showTrend: visibility.showSalesTrend,
          showReportsLink: visibility.showReportsLink,
        ),
      );
    }

    if (visibility.showQuickActionsSection) {
      addSection(
        DashboardQuickActionsCard(
          actions: visibility.visibleQuickActions,
        ),
      );
    }

    if (visibility.showRecentActivitySection) {
      addSection(
        RecentActivityCard(
          items: visibility.visibleActivities,
          showViewAll: visibility.showAllActivityLink,
        ),
      );
    }

    if (sections.isEmpty) {
      return const TenantAdminEmptyState(
        title: 'Dashboard',
        message: 'No dashboard widgets available for your access.',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: sections,
    );
  }
}

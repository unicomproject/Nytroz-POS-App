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
import '../widgets/operational_risks_card.dart';
import '../widgets/attention_and_exceptions_row.dart';
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

    if (visibility.showKpiSection) {
      sections.add(
        DashboardMetricGrid(
          metrics: visibility.visibleMetrics.take(4).toList(growable: false),
          compact: false,
        ),
      );
    }

    if (sections.isNotEmpty) {
      sections.add(const SizedBox(height: 24));
    }

    if (width < 820) {
      // Stacked for small tablets
      sections.add(
        SalesThisWeekCard(
          salesSummary: visibility.salesSummary,
          showTrend: visibility.showSalesTrend,
          showReportsLink: visibility.showReportsLink,
        ),
      );
      sections.add(const SizedBox(height: 24));
      sections.add(const OperationalRisksCard());
    } else {
      sections.add(
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 5,
              child: SalesThisWeekCard(
                salesSummary: visibility.salesSummary,
                showTrend: visibility.showSalesTrend,
                showReportsLink: visibility.showReportsLink,
              ),
            ),
            const SizedBox(width: 24),
            const Expanded(
              flex: 3,
              child: OperationalRisksCard(),
            ),
          ],
        ),
      );
    }

    sections.add(const SizedBox(height: 24));
    sections.add(const AttentionAndExceptionsRow());

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

    addSection(
      SalesThisWeekCard(
        salesSummary: visibility.salesSummary,
        showTrend: visibility.showSalesTrend,
        showReportsLink: visibility.showReportsLink,
      ),
    );

    addSection(const OperationalRisksCard());
    addSection(const AttentionAndExceptionsRow());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: sections,
    );
  }
}

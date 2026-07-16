import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../presentation/providers/tenant_admin_context_provider.dart';
import '../../../presentation/theme/tenant_admin_theme.dart';
import '../../domain/entities/report_models.dart';
import '../providers/report_providers.dart';
import '../utils/report_catalog.dart';
import '../utils/report_export_action.dart';
import '../utils/report_screen_helpers.dart';
import '../widgets/common/report_filter_components.dart';
import '../widgets/common/report_page_components.dart';
import '../widgets/common/report_result_content.dart';
import '../widgets/common/report_states.dart';

class ReportsDashboardScreen extends ConsumerWidget {
  const ReportsDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final permissionsState = ref.watch(reportPermissionProvider);
    final query = ref.watch(reportQueryProvider(ReportScope.dashboard));
    final notifier = ref.read(
      reportQueryProvider(ReportScope.dashboard).notifier,
    );
    final tenantContextState = ref.watch(tenantAdminContextProvider);

    return permissionsState.when(
      loading: () => const ReportPageScaffold(
        title: 'Reports Dashboard',
        subtitle:
            'Overview of sales, payments, inventory and outlet performance.',
        child: ReportLoadingState(),
      ),
      error: (error, stackTrace) => ReportPageScaffold(
        title: 'Reports Dashboard',
        subtitle:
            'Overview of sales, payments, inventory and outlet performance.',
        child: ReportRequestErrorState(error: error),
      ),
      data: (permissions) {
        if (!permissions.module) {
          return const ReportPageScaffold(
            title: 'Reports Dashboard',
            subtitle:
                'Overview of sales, payments, inventory and outlet performance.',
            child: ReportFeatureDisabledState(),
          );
        }

        if (!permissions.dashboard) {
          return const ReportPageScaffold(
            title: 'Reports Dashboard',
            subtitle:
                'Overview of sales, payments, inventory and outlet performance.',
            child: ReportPermissionDeniedState(),
          );
        }

        final actions = <Widget>[];
        if (permissions.export) {
          actions.add(
            ReportExportMenu(
              onSelected: (format) => requestReportExport(
                context,
                ref,
                reportType: 'dashboard',
                format: format,
                query: query,
              ),
            ),
          );
        }

        return tenantContextState.when(
          loading: () => ReportPageScaffold(
            title: 'Reports Dashboard',
            subtitle:
                'Overview of sales, payments, inventory and outlet performance.',
            actions: actions,
            child: const ReportLoadingState(),
          ),
          error: (error, stackTrace) => ReportPageScaffold(
            title: 'Reports Dashboard',
            subtitle:
                'Overview of sales, payments, inventory and outlet performance.',
            actions: actions,
            child: ReportRequestErrorState(error: error),
          ),
          data: (tenantContext) {
            final outlets = reportOutletOptions(tenantContext);
            final singleOutletPending =
                outlets.length == 1 && query.outletId == null;
            autoSelectSingleReportOutlet(outlets, query.outletId, notifier);
            final options = ref.watch(
              reportFilterOptionsProvider(ReportScope.dashboard),
            );
            final result = singleOutletPending
                ? const AsyncValue<ReportResult>.loading()
                : ref.watch(reportsDashboardProvider);

            return ReportPageScaffold(
                title: 'Reports Dashboard',
                subtitle:
                    'Overview of sales, payments, inventory and outlet performance.',
                actions: actions,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ReportFilterBar(
                      scope: ReportScope.dashboard,
                      query: query,
                      notifier: notifier,
                      outlets: outlets,
                      filterOptions: options.asData?.value,
                      onApply: () => ref.invalidate(reportsDashboardProvider),
                      onClear: () {
                        notifier.clearOptionalFilters();
                        ref.invalidate(reportsDashboardProvider);
                      },
                    ),
                    const SizedBox(height: TenantAdminSpacing.xl),
                    _DashboardQuickLinks(permissions: permissions),
                    const SizedBox(height: TenantAdminSpacing.xl),
                    result.when(
                      loading: () => const ReportLoadingState(),
                      error: (error, stackTrace) => ReportRequestErrorState(
                        error: error,
                        onRetry: () => ref.invalidate(reportsDashboardProvider),
                        fallbackActions: _DashboardUnavailableActions(
                          permissions: permissions,
                        ),
                      ),
                      data: (data) {
                        final visibleMetrics = data.metrics
                            .where(
                              (metric) =>
                                  metric.key != 'currentStockValue' ||
                                  permissions.inventoryValuation,
                            )
                            .toList();
                        final visibleData = ReportResult(
                          section: data.section,
                          metrics: visibleMetrics,
                          sections: data.sections,
                          records: data.records,
                          pagination: data.pagination,
                          currencyCode: data.currencyCode,
                          generatedAt: data.generatedAt,
                        );
                        return ReportResultContent(
                          result: visibleData,
                          queryHasFilters: false,
                          columns: _dashboardColumns,
                          onClearFilters: notifier.clearOptionalFilters,
                          onPageChanged: notifier.setPage,
                          onPageSizeChanged: notifier.setPageSize,
                          showSectionCharts: true,
                        );
                      },
                    ),
                  ],
                ));
          },
        );
      },
    );
  }
}

class _DashboardUnavailableActions extends StatelessWidget {
  const _DashboardUnavailableActions({required this.permissions});

  final ReportPermissionSnapshot permissions;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: TenantAdminSpacing.sm,
      runSpacing: TenantAdminSpacing.sm,
      alignment: WrapAlignment.center,
      children: [
        if (permissions.sales)
          const ReportQuickLinkButton(
            label: 'Open Sales Report',
            route: '/tenant-admin/reports/sales',
          ),
        if (permissions.stock)
          const ReportQuickLinkButton(
            label: 'Open Stock Report',
            route: '/tenant-admin/reports/stock',
          ),
        if (permissions.outlets)
          const ReportQuickLinkButton(
            label: 'Open Outlet Report',
            route: '/tenant-admin/reports/outlets',
          ),
      ],
    );
  }
}

class _DashboardQuickLinks extends StatelessWidget {
  const _DashboardQuickLinks({required this.permissions});

  final ReportPermissionSnapshot permissions;

  @override
  Widget build(BuildContext context) {
    final links = <Widget>[
      if (permissions.sales)
        const ReportQuickLinkCard(
          title: 'Sales Report',
          subtitle: 'Transactions, products, payments and sales performance',
          icon: Icons.receipt_long_outlined,
          route: '/tenant-admin/reports/sales',
        ),
      if (permissions.stock)
        const ReportQuickLinkCard(
          title: 'Stock Report',
          subtitle: 'Availability, movements, expiry and valuation',
          icon: Icons.inventory_2_outlined,
          route: '/tenant-admin/reports/stock',
        ),
      if (permissions.outlets)
        const ReportQuickLinkCard(
          title: 'Outlet Report',
          subtitle: 'Outlet, till and permitted cashier performance',
          icon: Icons.storefront_outlined,
          route: '/tenant-admin/reports/outlets',
        ),
    ];
    if (links.isEmpty) {
      return const SizedBox.shrink();
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth >= 900
            ? (constraints.maxWidth - ((links.length - 1) * 16)) / links.length
            : constraints.maxWidth;
        return Wrap(
          spacing: TenantAdminSpacing.lg,
          runSpacing: TenantAdminSpacing.lg,
          children:
              links.map((link) => SizedBox(width: width, child: link)).toList(),
        );
      },
    );
  }
}

const _dashboardColumns = [
  ReportColumnSpec(key: 'label', label: 'Item', primary: true),
  ReportColumnSpec(key: 'value', label: 'Value'),
];

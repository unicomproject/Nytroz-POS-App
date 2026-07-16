import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../presentation/providers/tenant_admin_context_provider.dart';
import '../../data/constants/report_api_paths.dart';
import '../providers/report_providers.dart';
import '../utils/report_catalog.dart';
import '../utils/report_export_action.dart';
import '../utils/report_screen_helpers.dart';
import '../widgets/common/report_page_components.dart';
import '../widgets/common/report_screen_frame.dart';
import '../widgets/common/report_states.dart';

class SalesReportScreen extends ConsumerStatefulWidget {
  const SalesReportScreen({super.key});

  @override
  ConsumerState<SalesReportScreen> createState() => _SalesReportScreenState();
}

class _SalesReportScreenState extends ConsumerState<SalesReportScreen> {
  bool _routeApplied = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_routeApplied) {
      return;
    }
    _routeApplied = true;
    try {
      final tab = GoRouterState.of(context).uri.queryParameters['tab'];
      if (tab != null &&
          ReportCatalog.salesTabs.any((item) => item.key == tab)) {
        ref
            .read(reportQueryProvider(ReportScope.sales).notifier)
            .setSection(tab);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final permissionsState = ref.watch(reportPermissionProvider);
    final query = ref.watch(reportQueryProvider(ReportScope.sales));
    final notifier = ref.read(reportQueryProvider(ReportScope.sales).notifier);
    final result = ref.watch(salesReportProvider);
    final options = ref.watch(reportFilterOptionsProvider(ReportScope.sales));
    final tenantContext = ref.watch(tenantAdminContextProvider).asData?.value;
    final outlets = reportOutletOptions(tenantContext);
    autoSelectSingleReportOutlet(outlets, query.outletId, notifier);

    return permissionsState.when(
      loading: () => const ReportPageScaffold(
        title: 'Sales Report',
        subtitle: 'Review completed sales and related financial activity.',
        child: ReportLoadingState(),
      ),
      error: (error, stackTrace) => ReportPageScaffold(
        title: 'Sales Report',
        subtitle: 'Review completed sales and related financial activity.',
        child: ReportRequestErrorState(error: error),
      ),
      data: (permissions) {
        final tabs = _visibleSalesTabs(permissions);
        _ensureSelectedTab(tabs, query.section, notifier);
        return ReportScreenFrame(
          title: 'Sales Report',
          subtitle: 'Review completed sales and related financial activity.',
          scope: ReportScope.sales,
          query: query,
          queryNotifier: notifier,
          outlets: outlets,
          filterOptions: options.asData?.value,
          result: result,
          permitted: permissions.sales,
          tabs: tabs,
          onTabSelected: (tab) {
            notifier.setSection(tab.key);
            context.go('/tenant-admin/reports/sales?tab=${tab.key}');
          },
          onRetry: () => ref.invalidate(salesReportProvider),
          onApply: () => ref.invalidate(salesReportProvider),
          onClear: () {
            notifier.clearFilters();
            ref.invalidate(salesReportProvider);
          },
          allowSensitiveColumns: permissions.customerPii,
          showSectionCharts: query.section == ReportSections.salesSummary,
          onOpenRecord: query.section == ReportSections.transactions
              ? (record) {
                  final orderId = record['orderId']?.toString() ?? '';
                  if (orderId.isNotEmpty) {
                    context.push('/tenant-admin/reports/sales/$orderId');
                  }
                }
              : null,
          actions: permissions.export
              ? [
                  ReportExportMenu(
                    onSelected: (format) => requestReportExport(
                      context,
                      ref,
                      reportType: 'sales',
                      format: format,
                      query: query,
                    ),
                  ),
                ]
              : const [],
        );
      },
    );
  }
}

List<ReportTabSpec> _visibleSalesTabs(ReportPermissionSnapshot permissions) {
  return ReportCatalog.salesTabs.where((tab) {
    return switch (tab.key) {
      ReportSections.salesSummary => permissions.sales,
      ReportSections.transactions => permissions.transactions,
      ReportSections.products => permissions.products,
      ReportSections.categories => permissions.categories,
      ReportSections.payments => permissions.payments,
      ReportSections.tax => permissions.tax,
      ReportSections.discounts => permissions.discounts,
      ReportSections.returns => permissions.returnsAndRefunds,
      ReportSections.cashiers => permissions.cashiers,
      ReportSections.daily => permissions.dailySales,
      _ => false,
    };
  }).toList();
}

void _ensureSelectedTab(
  List<ReportTabSpec> tabs,
  String selected,
  ReportQueryNotifier notifier,
) {
  if (tabs.isNotEmpty && !tabs.any((tab) => tab.key == selected)) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifier.setSection(tabs.first.key);
    });
  }
}

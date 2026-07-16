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

class OutletReportScreen extends ConsumerStatefulWidget {
  const OutletReportScreen({super.key});

  @override
  ConsumerState<OutletReportScreen> createState() => _OutletReportScreenState();
}

class _OutletReportScreenState extends ConsumerState<OutletReportScreen> {
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
          ReportCatalog.outletTabs.any((item) => item.key == tab)) {
        ref
            .read(reportQueryProvider(ReportScope.outlets).notifier)
            .setSection(tab);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final permissionsState = ref.watch(reportPermissionProvider);
    final query = ref.watch(reportQueryProvider(ReportScope.outlets));
    final notifier =
        ref.read(reportQueryProvider(ReportScope.outlets).notifier);
    final result = ref.watch(outletReportProvider);
    final options = ref.watch(reportFilterOptionsProvider(ReportScope.outlets));
    final tenantContext = ref.watch(tenantAdminContextProvider).asData?.value;
    final outlets = reportOutletOptions(tenantContext);
    autoSelectSingleReportOutlet(outlets, query.outletId, notifier);

    return permissionsState.when(
      loading: () => const ReportPageScaffold(
        title: 'Outlet Report',
        subtitle: 'Compare accessible outlets, tills and cashier performance.',
        child: ReportLoadingState(),
      ),
      error: (error, stackTrace) => ReportPageScaffold(
        title: 'Outlet Report',
        subtitle: 'Compare accessible outlets, tills and cashier performance.',
        child: ReportRequestErrorState(error: error),
      ),
      data: (permissions) {
        final tabs = _visibleOutletTabs(permissions);
        _ensureSelectedOutletTab(tabs, query.section, notifier);
        return ReportScreenFrame(
          title: 'Outlet Report',
          subtitle:
              'Compare accessible outlets, tills and cashier performance.',
          scope: ReportScope.outlets,
          query: query,
          queryNotifier: notifier,
          outlets: outlets,
          filterOptions: options.asData?.value,
          result: result,
          permitted: permissions.outlets,
          tabs: tabs,
          onTabSelected: (tab) {
            notifier.setSection(tab.key);
            context.go('/tenant-admin/reports/outlets?tab=${tab.key}');
          },
          onRetry: () => ref.invalidate(outletReportProvider),
          onApply: () => ref.invalidate(outletReportProvider),
          onClear: () {
            notifier.clearFilters();
            ref.invalidate(outletReportProvider);
          },
          allowSensitiveColumns: permissions.inventoryValuation,
          showSectionCharts: query.section == ReportSections.outletPerformance,
          actions: permissions.export
              ? [
                  ReportExportMenu(
                    onSelected: (format) => requestReportExport(
                      context,
                      ref,
                      reportType: 'outlets',
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

List<ReportTabSpec> _visibleOutletTabs(ReportPermissionSnapshot permissions) {
  return ReportCatalog.outletTabs.where((tab) {
    return switch (tab.key) {
      ReportSections.outletPerformance => permissions.outlets,
      ReportSections.tillSummary => permissions.tillSummary,
      ReportSections.cashiers => permissions.cashiers,
      _ => false,
    };
  }).toList();
}

void _ensureSelectedOutletTab(
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

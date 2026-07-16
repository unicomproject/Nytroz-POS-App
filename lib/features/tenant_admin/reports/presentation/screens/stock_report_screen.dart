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

class StockReportScreen extends ConsumerStatefulWidget {
  const StockReportScreen({super.key});

  @override
  ConsumerState<StockReportScreen> createState() => _StockReportScreenState();
}

class _StockReportScreenState extends ConsumerState<StockReportScreen> {
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
          ReportCatalog.stockTabs.any((item) => item.key == tab)) {
        ref
            .read(reportQueryProvider(ReportScope.stock).notifier)
            .setSection(tab);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final permissionsState = ref.watch(reportPermissionProvider);
    final query = ref.watch(reportQueryProvider(ReportScope.stock));
    final notifier = ref.read(reportQueryProvider(ReportScope.stock).notifier);
    final result = ref.watch(stockReportProvider);
    final options = ref.watch(reportFilterOptionsProvider(ReportScope.stock));
    final tenantContext = ref.watch(tenantAdminContextProvider).asData?.value;
    final outlets = reportOutletOptions(tenantContext);
    autoSelectSingleReportOutlet(outlets, query.outletId, notifier);

    return permissionsState.when(
      loading: () => const ReportPageScaffold(
        title: 'Stock Report',
        subtitle: 'Review stock availability, expiry, movement and valuation.',
        child: ReportLoadingState(),
      ),
      error: (error, stackTrace) => ReportPageScaffold(
        title: 'Stock Report',
        subtitle: 'Review stock availability, expiry, movement and valuation.',
        child: ReportRequestErrorState(error: error),
      ),
      data: (permissions) {
        final tabs = _visibleStockTabs(permissions);
        _ensureSelectedStockTab(tabs, query.section, notifier);
        return ReportScreenFrame(
          title: 'Stock Report',
          subtitle:
              'Review stock availability, expiry, movement and valuation.',
          scope: ReportScope.stock,
          query: query,
          queryNotifier: notifier,
          outlets: outlets,
          filterOptions: options.asData?.value,
          result: result,
          permitted: permissions.stock,
          tabs: tabs,
          onTabSelected: (tab) {
            notifier.setSection(tab.key);
            context.go('/tenant-admin/reports/stock?tab=${tab.key}');
          },
          onRetry: () => ref.invalidate(stockReportProvider),
          onApply: () => ref.invalidate(stockReportProvider),
          onClear: () {
            notifier.clearFilters();
            ref.invalidate(stockReportProvider);
          },
          allowSensitiveColumns: permissions.inventoryValuation,
          actions: permissions.export
              ? [
                  ReportExportMenu(
                    onSelected: (format) => requestReportExport(
                      context,
                      ref,
                      reportType: 'stock',
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

List<ReportTabSpec> _visibleStockTabs(ReportPermissionSnapshot permissions) {
  return ReportCatalog.stockTabs.where((tab) {
    return switch (tab.key) {
      ReportSections.currentStock => permissions.stock,
      ReportSections.lowStock => permissions.stock,
      ReportSections.outOfStock => permissions.stock,
      ReportSections.batchExpiry => permissions.batchExpiry,
      ReportSections.movements => permissions.stockMovements,
      ReportSections.valuation => permissions.inventoryValuation,
      _ => false,
    };
  }).toList();
}

void _ensureSelectedStockTab(
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

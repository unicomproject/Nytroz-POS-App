import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../presentation/theme/tenant_admin_theme.dart';
import '../../../domain/entities/report_models.dart';
import '../../../domain/entities/report_query.dart';
import '../../providers/report_providers.dart';
import '../../utils/report_catalog.dart';
import 'report_filter_components.dart';
import 'report_page_components.dart';
import 'report_result_content.dart';
import 'report_states.dart';
import 'report_tabs.dart';

class ReportScreenFrame extends StatelessWidget {
  const ReportScreenFrame({
    super.key,
    required this.title,
    required this.subtitle,
    required this.scope,
    required this.query,
    required this.queryNotifier,
    required this.outlets,
    required this.filterOptions,
    required this.result,
    required this.permitted,
    required this.tabs,
    required this.onTabSelected,
    required this.onRetry,
    required this.onApply,
    required this.onClear,
    this.allowSensitiveColumns = false,
    this.onOpenRecord,
    this.showSectionCharts = false,
    this.actions = const [],
  });

  final String title;
  final String subtitle;
  final ReportScope scope;
  final ReportQuery query;
  final ReportQueryNotifier queryNotifier;
  final List<ReportFilterOption> outlets;
  final ReportFilterOptions? filterOptions;
  final AsyncValue<ReportResult> result;
  final bool permitted;
  final List<ReportTabSpec> tabs;
  final ValueChanged<ReportTabSpec> onTabSelected;
  final VoidCallback onRetry;
  final VoidCallback onApply;
  final VoidCallback onClear;
  final bool allowSensitiveColumns;
  final ValueChanged<ReportRecord>? onOpenRecord;
  final bool showSectionCharts;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return ReportPageScaffold(
      title: title,
      subtitle: subtitle,
      actions: actions,
      child: permitted
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ReportFilterBar(
                  scope: scope,
                  query: query,
                  notifier: queryNotifier,
                  outlets: outlets,
                  filterOptions: filterOptions,
                  onApply: onApply,
                  onClear: onClear,
                ),
                const SizedBox(height: TenantAdminSpacing.xl),
                if (tabs.isNotEmpty) ...[
                  ReportTabs(
                    tabs: tabs,
                    selectedKey: query.section,
                    onSelected: onTabSelected,
                  ),
                  const SizedBox(height: TenantAdminSpacing.xl),
                ],
                result.when(
                  loading: () => const ReportLoadingState(),
                  error: (error, stackTrace) => ReportRequestErrorState(
                    error: error,
                    onRetry: onRetry,
                  ),
                  data: (data) {
                    final selected = tabs.where(
                      (tab) => tab.key == query.section,
                    );
                    final columns = selected.isEmpty
                        ? const <ReportColumnSpec>[]
                        : selected.first.columns;
                    return ReportResultContent(
                      result: data,
                      queryHasFilters: query.hasActiveFilters,
                      columns: columns,
                      onClearFilters: onClear,
                      onPageChanged: queryNotifier.setPage,
                      onPageSizeChanged: queryNotifier.setPageSize,
                      allowSensitiveColumns: allowSensitiveColumns,
                      onOpenRecord: onOpenRecord,
                      showSectionCharts: showSectionCharts,
                    );
                  },
                ),
              ],
            )
          : const ReportPermissionDeniedState(),
    );
  }
}

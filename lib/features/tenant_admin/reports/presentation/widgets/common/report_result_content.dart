import 'package:flutter/material.dart';

import '../../../../presentation/theme/tenant_admin_theme.dart';
import '../../../domain/entities/report_models.dart';
import '../../utils/report_catalog.dart';
import 'report_data_components.dart';
import 'report_page_components.dart';
import 'report_states.dart';

class ReportResultContent extends StatelessWidget {
  const ReportResultContent({
    super.key,
    required this.result,
    required this.queryHasFilters,
    required this.columns,
    required this.onClearFilters,
    required this.onPageChanged,
    required this.onPageSizeChanged,
    this.allowSensitiveColumns = false,
    this.onOpenRecord,
    this.showSectionCharts = false,
  });

  final ReportResult result;
  final bool queryHasFilters;
  final List<ReportColumnSpec> columns;
  final VoidCallback onClearFilters;
  final ValueChanged<int> onPageChanged;
  final ValueChanged<int> onPageSizeChanged;
  final bool allowSensitiveColumns;
  final ValueChanged<ReportRecord>? onOpenRecord;
  final bool showSectionCharts;

  @override
  Widget build(BuildContext context) {
    if (result.isEmpty) {
      return ReportEmptyState(
        filtered: queryHasFilters,
        onClear: onClearFilters,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (result.metrics.isNotEmpty) ...[
          ReportSummaryGrid(metrics: result.metrics),
          const SizedBox(height: TenantAdminSpacing.xl),
        ],
        if (showSectionCharts && result.sections.isNotEmpty) ...[
          LayoutBuilder(
            builder: (context, constraints) {
              final cardWidth = constraints.maxWidth >= 1100
                  ? (constraints.maxWidth - 16) / 2
                  : constraints.maxWidth;
              return Wrap(
                spacing: TenantAdminSpacing.lg,
                runSpacing: TenantAdminSpacing.lg,
                children: result.sections
                    .map(
                      (section) => SizedBox(
                        width: cardWidth,
                        child: ReportChartCard(
                          title: section.title,
                          records: section.records,
                          valueKey: _chartValueKey(section),
                        ),
                      ),
                    )
                    .toList(),
              );
            },
          ),
          const SizedBox(height: TenantAdminSpacing.xl),
        ],
        if (result.records.isNotEmpty)
          ReportSectionCard(
            title: 'Report Results',
            child: Column(
              children: [
                ReportDataView(
                  records: result.records,
                  columns: columns,
                  currencyCode: result.currencyCode,
                  allowSensitiveColumns: allowSensitiveColumns,
                  onOpenRecord: onOpenRecord,
                ),
                ReportPaginationControls(
                  pagination: result.pagination,
                  onPageChanged: onPageChanged,
                  onPageSizeChanged: onPageSizeChanged,
                ),
              ],
            ),
          ),
      ],
    );
  }

  String _chartValueKey(ReportSection section) {
    final candidateKeys = switch (section.key) {
      'salesTrend' => const ['netSalesAmount', 'grossSalesAmount'],
      'paymentMethodBreakdown' => const ['netCollectedAmount', 'paidAmount'],
      'topSellingProducts' => const ['netSalesAmount', 'quantitySold'],
      'outletPerformance' => const ['netSalesAmount', 'transactionCount'],
      _ => const [
          'value',
          'netSalesAmount',
          'transactionCount',
          'totalAmount',
        ],
    };
    for (final key in candidateKeys) {
      if (section.records.any((record) => record[key] is num)) {
        return key;
      }
    }
    return candidateKeys.first;
  }
}

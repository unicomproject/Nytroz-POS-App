import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../presentation/theme/tenant_admin_theme.dart';
import '../../../domain/entities/report_models.dart';
import '../../utils/report_catalog.dart';
import '../../utils/report_formatters.dart';
import 'report_page_components.dart';

class ReportSummaryGrid extends StatelessWidget {
  const ReportSummaryGrid({super.key, required this.metrics});

  final List<ReportMetric> metrics;

  @override
  Widget build(BuildContext context) {
    if (metrics.isEmpty) {
      return const SizedBox.shrink();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 1200
            ? math.min(4, metrics.length)
            : constraints.maxWidth >= 900
                ? math.min(4, metrics.length)
                : constraints.maxWidth >= 600
                    ? 2
                    : constraints.maxWidth >= 420
                        ? 2
                        : 1;
        final width = (constraints.maxWidth - ((columns - 1) * 16)) / columns;
        return Wrap(
          spacing: TenantAdminSpacing.lg,
          runSpacing: TenantAdminSpacing.lg,
          children: metrics
              .map(
                (metric) => SizedBox(
                  width: width,
                  child: ReportSummaryCard(metric: metric),
                ),
              )
              .toList(),
        );
      },
    );
  }
}

class ReportSummaryCard extends StatelessWidget {
  const ReportSummaryCard({super.key, required this.metric});

  final ReportMetric metric;

  @override
  Widget build(BuildContext context) {
    final change = metric.percentageChange;
    final positive = change != null && change > 0;
    final negative = change != null && change < 0;
    final trendColor = positive
        ? TenantAdminColors.success
        : negative
            ? TenantAdminColors.danger
            : TenantAdminColors.mutedText;
    final value = metric.formattedValue?.trim().isNotEmpty == true
        ? metric.formattedValue!
        : formatReportValue(
            metric.rawValue,
            currencyCode: metric.currencyCode,
          );

    return Container(
      constraints: const BoxConstraints(minHeight: 122),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: TenantAdminColors.surface,
        borderRadius: BorderRadius.circular(TenantAdminRadius.lg),
        border: Border.all(color: TenantAdminColors.border),
        boxShadow: TenantAdminShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: TenantAdminColors.secondary,
                  borderRadius: BorderRadius.circular(TenantAdminRadius.md),
                ),
                child: const Icon(
                  Icons.analytics_outlined,
                  color: TenantAdminColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: TenantAdminSpacing.sm),
              Expanded(
                child: Text(
                  metric.label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: TenantAdminColors.mutedText,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: TenantAdminSpacing.md),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: TenantAdminColors.bodyText,
              fontWeight: FontWeight.w900,
              fontSize: 20,
            ),
          ),
          if (change != null) ...[
            const SizedBox(height: TenantAdminSpacing.sm),
            Row(
              children: [
                Icon(
                  positive
                      ? Icons.trending_up
                      : negative
                          ? Icons.trending_down
                          : Icons.trending_flat,
                  size: 16,
                  color: trendColor,
                ),
                const SizedBox(width: TenantAdminSpacing.xs),
                Expanded(
                  child: Text(
                    '${change.toStringAsFixed(1)}% ${metric.comparisonLabel ?? ''}'
                        .trim(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: trendColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class ReportDataView extends StatelessWidget {
  const ReportDataView({
    super.key,
    required this.records,
    required this.columns,
    this.currencyCode,
    this.allowSensitiveColumns = false,
    this.onOpenRecord,
  });

  final List<ReportRecord> records;
  final List<ReportColumnSpec> columns;
  final String? currencyCode;
  final bool allowSensitiveColumns;
  final ValueChanged<ReportRecord>? onOpenRecord;

  @override
  Widget build(BuildContext context) {
    final visibleColumns = columns
        .where((column) => !column.sensitive || allowSensitiveColumns)
        .toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 600) {
          return Column(
            children: [
              for (var index = 0; index < records.length; index++) ...[
                ReportMobileRecordCard(
                  record: records[index],
                  columns: visibleColumns,
                  currencyCode: currencyCode,
                  onOpen: onOpenRecord == null
                      ? null
                      : () => onOpenRecord!(records[index]),
                ),
                if (index != records.length - 1)
                  const SizedBox(height: TenantAdminSpacing.md),
              ],
            ],
          );
        }

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(
              TenantAdminColors.background,
            ),
            horizontalMargin: 16,
            columnSpacing: 24,
            columns: [
              ...visibleColumns.map(
                (column) => DataColumn(
                  numeric: column.financial,
                  label: Text(
                    column.label,
                    style: const TextStyle(
                      color: TenantAdminColors.bodyText,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              if (onOpenRecord != null) const DataColumn(label: Text('Action')),
            ],
            rows: records
                .map(
                  (record) => DataRow(
                    cells: [
                      ...visibleColumns.map(
                        (column) => DataCell(
                          column.status
                              ? ReportStatusBadge(
                                  value: formatReportValue(record[column.key]),
                                )
                              : Text(
                                  formatReportValue(
                                    record[column.key],
                                    currencyCode: column.financial
                                        ? (record['currencyCode']?.toString() ??
                                            currencyCode)
                                        : null,
                                  ),
                                  textAlign: column.financial
                                      ? TextAlign.right
                                      : TextAlign.left,
                                ),
                        ),
                      ),
                      if (onOpenRecord != null)
                        DataCell(
                          IconButton(
                            tooltip: 'View details',
                            onPressed: () => onOpenRecord!(record),
                            icon: const Icon(
                              Icons.open_in_new,
                              color: TenantAdminColors.primary,
                            ),
                          ),
                        ),
                    ],
                  ),
                )
                .toList(),
          ),
        );
      },
    );
  }
}

class ReportMobileRecordCard extends StatelessWidget {
  const ReportMobileRecordCard({
    super.key,
    required this.record,
    required this.columns,
    this.currencyCode,
    this.onOpen,
  });

  final ReportRecord record;
  final List<ReportColumnSpec> columns;
  final String? currencyCode;
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    final primary = columns.where((column) => column.primary).take(2).toList();
    final secondary = columns
        .where((column) => !column.primary)
        .where((column) => record[column.key] != null)
        .take(6)
        .toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: TenantAdminColors.surface,
        borderRadius: BorderRadius.circular(TenantAdminRadius.lg),
        border: Border.all(color: TenantAdminColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final column in primary)
            Padding(
              padding: const EdgeInsets.only(bottom: TenantAdminSpacing.xs),
              child: Text(
                formatReportValue(record[column.key]),
                style: const TextStyle(
                  color: TenantAdminColors.bodyText,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
            ),
          if (primary.isNotEmpty) const Divider(height: TenantAdminSpacing.xl),
          for (final column in secondary)
            Padding(
              padding: const EdgeInsets.only(bottom: TenantAdminSpacing.sm),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 130,
                    child: Text(
                      column.label,
                      style: TenantAdminTextStyles.muted(context),
                    ),
                  ),
                  Expanded(
                    child: column.status
                        ? Align(
                            alignment: Alignment.centerLeft,
                            child: ReportStatusBadge(
                              value: formatReportValue(record[column.key]),
                            ),
                          )
                        : Text(
                            formatReportValue(
                              record[column.key],
                              currencyCode: column.financial
                                  ? (record['currencyCode']?.toString() ??
                                      currencyCode)
                                  : null,
                            ),
                            textAlign: TextAlign.right,
                            style: const TextStyle(
                              color: TenantAdminColors.bodyText,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ],
              ),
            ),
          if (onOpen != null) ...[
            const SizedBox(height: TenantAdminSpacing.sm),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onOpen,
                icon: const Icon(Icons.visibility_outlined),
                label: const Text('View Details'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class ReportStatusBadge extends StatelessWidget {
  const ReportStatusBadge({super.key, required this.value});

  final String value;

  @override
  Widget build(BuildContext context) {
    final normalized = value.toUpperCase();
    final color = normalized.contains('ACTIVE') ||
            normalized.contains('COMPLETED') ||
            normalized.contains('PAID') ||
            normalized.contains('IN_STOCK')
        ? TenantAdminColors.success
        : normalized.contains('PENDING') ||
                normalized.contains('LOW') ||
                normalized.contains('EXPIR')
            ? TenantAdminColors.warning
            : normalized.contains('FAILED') ||
                    normalized.contains('CANCEL') ||
                    normalized.contains('VOID') ||
                    normalized.contains('OUT_OF_STOCK')
                ? TenantAdminColors.danger
                : TenantAdminColors.mutedText;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        value,
        style:
            TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class ReportPaginationControls extends StatelessWidget {
  const ReportPaginationControls({
    super.key,
    required this.pagination,
    required this.onPageChanged,
    required this.onPageSizeChanged,
  });

  final ReportPagination pagination;
  final ValueChanged<int> onPageChanged;
  final ValueChanged<int> onPageSizeChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: TenantAdminSpacing.lg),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: TenantAdminSpacing.md,
        runSpacing: TenantAdminSpacing.sm,
        children: [
          Text(
            'Page ${pagination.page} of ${math.max(1, pagination.totalPages)} · '
            '${pagination.totalCount} records',
            style: TenantAdminTextStyles.muted(context),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButton<int>(
                value: const {25, 50, 100}.contains(pagination.pageSize)
                    ? pagination.pageSize
                    : 25,
                items: const [
                  DropdownMenuItem(value: 25, child: Text('25 / page')),
                  DropdownMenuItem(value: 50, child: Text('50 / page')),
                  DropdownMenuItem(value: 100, child: Text('100 / page')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    onPageSizeChanged(value);
                  }
                },
              ),
              IconButton(
                tooltip: 'Previous page',
                onPressed: pagination.page > 1
                    ? () => onPageChanged(pagination.page - 1)
                    : null,
                icon: const Icon(Icons.chevron_left),
              ),
              IconButton(
                tooltip: 'Next page',
                onPressed: pagination.page < pagination.totalPages
                    ? () => onPageChanged(pagination.page + 1)
                    : null,
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class ReportChartCard extends StatelessWidget {
  const ReportChartCard({
    super.key,
    required this.title,
    required this.records,
    required this.valueKey,
  });

  final String title;
  final List<ReportRecord> records;
  final String valueKey;

  @override
  Widget build(BuildContext context) {
    final values = records
        .map((record) => record[valueKey])
        .whereType<num>()
        .map((value) => value.toDouble())
        .toList();
    return ReportSectionCard(
      title: title,
      child: values.isEmpty
          ? const SizedBox(
              height: 180,
              child: Center(
                child: Text(
                  'No chart data',
                  style: TextStyle(color: TenantAdminColors.mutedText),
                ),
              ),
            )
          : SizedBox(
              height: 180,
              width: double.infinity,
              child: CustomPaint(painter: _ReportBarPainter(values)),
            ),
    );
  }
}

class _ReportBarPainter extends CustomPainter {
  const _ReportBarPainter(this.values);

  final List<double> values;

  @override
  void paint(Canvas canvas, Size size) {
    final maxValue = values.fold<double>(0, math.max);
    if (maxValue <= 0) {
      return;
    }
    final paint = Paint()..color = TenantAdminColors.primary;
    const gap = 6.0;
    final barWidth =
        math.max(4.0, (size.width - gap * values.length) / values.length);
    for (var index = 0; index < values.length; index++) {
      final height = (values[index] / maxValue) * (size.height - 16);
      final left = index * (barWidth + gap);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(left, size.height - height, barWidth, height),
          const Radius.circular(4),
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ReportBarPainter oldDelegate) {
    return oldDelegate.values != values;
  }
}

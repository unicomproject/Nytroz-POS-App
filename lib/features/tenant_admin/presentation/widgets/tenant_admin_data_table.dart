import 'package:flutter/material.dart';

import '../theme/tenant_admin_theme.dart';
import 'tenant_admin_states.dart';

class TenantAdminDataTable extends StatelessWidget {
  const TenantAdminDataTable({
    super.key,
    required this.columns,
    required this.rows,
    this.loading = false,
    this.errorMessage,
    this.emptyTitle = 'No records found',
    this.emptyMessage = 'There is nothing to show yet.',
    this.onRetry,
    this.showCheckboxColumn = false,
    this.footer,
  });

  final List<DataColumn> columns;
  final List<DataRow> rows;
  final bool loading;
  final String? errorMessage;
  final String emptyTitle;
  final String emptyMessage;
  final VoidCallback? onRetry;
  final bool showCheckboxColumn;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    Widget child;

    if (loading) {
      child = const Padding(
        padding: EdgeInsets.all(TenantAdminSpacing.xl),
        child: TenantAdminLoadingSkeleton(rowCount: 6),
      );
    } else if (errorMessage != null) {
      child = Padding(
        padding: const EdgeInsets.all(TenantAdminSpacing.xl),
        child: TenantAdminErrorState(
          title: 'Unable to load data',
          message: errorMessage!,
          onRetry: onRetry,
        ),
      );
    } else if (rows.isEmpty) {
      child = Padding(
        padding: const EdgeInsets.all(TenantAdminSpacing.xl),
        child: TenantAdminEmptyState(
          title: emptyTitle,
          message: emptyMessage,
        ),
      );
    } else {
      child = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Theme(
            data: Theme.of(context).copyWith(
              dataTableTheme: const DataTableThemeData(
                headingRowHeight: 48,
                dataRowMinHeight: 60,
                dataRowMaxHeight: 72,
                dividerThickness: 1,
                horizontalMargin: TenantAdminSpacing.xl,
                columnSpacing: TenantAdminSpacing.xl,
              ),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingTextStyle: const TextStyle(
                  color: TenantAdminColors.mutedText,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
                dataTextStyle: const TextStyle(
                  color: TenantAdminColors.bodyText,
                  fontWeight: FontWeight.w500,
                ),
                showCheckboxColumn: showCheckboxColumn,
                columns: columns,
                rows: rows,
              ),
            ),
          ),
          if (footer != null) ...[
            const Divider(height: 1, color: TenantAdminColors.border),
            footer!,
          ],
        ],
      );
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: TenantAdminColors.surface,
        borderRadius: BorderRadius.circular(TenantAdminRadius.lg),
        border: Border.all(color: TenantAdminColors.border),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(TenantAdminRadius.lg),
        child: child,
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../theme/tenant_admin_theme.dart';
import 'tenant_admin_states.dart';

class TenantAdminDataTable extends StatefulWidget {
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
    this.minWidth = 850.0,
    this.fillAvailableWidth = false,
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
  final double minWidth;

  @override
  State<TenantAdminDataTable> createState() => _TenantAdminDataTableState();
}

class _TenantAdminDataTableState extends State<TenantAdminDataTable> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget child;

    if (widget.loading) {
      child = const Padding(
        padding: EdgeInsets.all(TenantAdminSpacing.xl),
        child: TenantAdminLoadingSkeleton(rowCount: 6),
      );
    } else if (widget.errorMessage != null) {
      child = Padding(
        padding: const EdgeInsets.all(TenantAdminSpacing.xl),
        child: TenantAdminErrorState(
          title: 'Unable to load data',
          message: widget.errorMessage!,
          onRetry: widget.onRetry,
        ),
      );
    } else if (widget.rows.isEmpty) {
      child = Padding(
        padding: const EdgeInsets.all(TenantAdminSpacing.xl),
        child: TenantAdminEmptyState(
          title: widget.emptyTitle,
          message: widget.emptyMessage,
        ),
      );
    } else {
      child = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final compact =
                  constraints.maxWidth < TenantAdminBreakpoints.tablet;

              return Theme(
                data: Theme.of(context).copyWith(
                  dataTableTheme: DataTableThemeData(
                    headingRowHeight:
                        TenantAdminContentTokens.tableHeaderHeight,
                    dataRowMinHeight: compact ? 56 : 60,
                    dataRowMaxHeight: compact ? 68 : 72,
                    dividerThickness: 1,
                    horizontalMargin:
                        compact ? TenantAdminSpacing.lg : TenantAdminSpacing.xl,
                    columnSpacing:
                        compact ? TenantAdminSpacing.lg : TenantAdminSpacing.xl,
                  ),
                ),
                child: Scrollbar(
                  controller: _scrollController,
                  thumbVisibility: true,
                  trackVisibility: true,
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    scrollDirection: Axis.horizontal,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: TenantAdminSpacing.md),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minWidth: widget.minWidth > constraints.maxWidth
                              ? widget.minWidth
                              : constraints.maxWidth,
                        ),
                        child: DataTable(
                          headingTextStyle: TenantAdminTextStyles.tableHeader(context),
                          dataTextStyle: TenantAdminTextStyles.tableRow(context),
                          showCheckboxColumn: widget.showCheckboxColumn,
                          columns: widget.columns,
                          rows: widget.rows,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          if (widget.footer != null) ...[
            const Divider(height: 1, color: TenantAdminColors.border),
            widget.footer!,
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

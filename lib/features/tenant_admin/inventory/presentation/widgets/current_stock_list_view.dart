import 'package:flutter/material.dart';

import '../../../domain/services/tenant_admin_access_checker.dart';
import '../../../presentation/theme/tenant_admin_theme.dart';
import '../../domain/entities/inventory.dart';
import '../utils/inventory_api_errors.dart';

class CurrentStockListView extends StatelessWidget {
  const CurrentStockListView({
    super.key,
    required this.items,
    required this.visibility,
    required this.isMobile,
    this.onView,
  });

  final List<InventoryBalanceRow> items;
  final CurrentStockVisibility visibility;
  final bool isMobile;
  final ValueChanged<InventoryBalanceRow>? onView;

  static const _headerHeight = 52.0;
  static const _rowHeight = 62.0;
  static const _tableHeaderColor = Color(0xFFF8FAFC);
  static const _tableHoverColor = Color(0xFFF1F5F9);
  static const _horizontalPadding = 20.0;
  static const _minTableWidth = 1040.0;
  static const _columnFlex = <int>[22, 18, 10, 10, 10, 14, 8];

  @override
  Widget build(BuildContext context) {
    if (isMobile) {
      return Padding(
        padding: const EdgeInsets.all(TenantAdminSpacing.lg),
        child: Column(
          children: [
            for (final row in items) ...[
              _CurrentStockMobileCard(
                row: row,
                showViewAction: visibility.showTable,
                onView: onView,
              ),
              const SizedBox(height: TenantAdminSpacing.md),
            ],
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final tableWidth = constraints.maxWidth < _minTableWidth
            ? _minTableWidth
            : constraints.maxWidth;

        final table = SizedBox(
          width: tableWidth,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _CurrentStockTableHeader(),
              for (final row in items) ...[
                const Divider(
                  height: 1,
                  thickness: 0.5,
                  color: TenantAdminColors.border,
                ),
                _CurrentStockTableRow(
                  row: row,
                  showViewAction: visibility.showTable,
                  onView: onView,
                ),
              ],
            ],
          ),
        );

        if (constraints.maxWidth < _minTableWidth) {
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: table,
          );
        }

        return table;
      },
    );
  }
}

class _CurrentStockTableHeader extends StatelessWidget {
  const _CurrentStockTableHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: CurrentStockListView._headerHeight,
      color: CurrentStockListView._tableHeaderColor,
      padding: const EdgeInsets.symmetric(
        horizontal: CurrentStockListView._horizontalPadding,
      ),
      child: Row(
        children: [
          _HeaderCell('Product', flex: CurrentStockListView._columnFlex[0]),
          _HeaderCell('Variant', flex: CurrentStockListView._columnFlex[1]),
          _HeaderCell('On Hand', flex: CurrentStockListView._columnFlex[2]),
          _HeaderCell('Reserved', flex: CurrentStockListView._columnFlex[3]),
          _HeaderCell('Available', flex: CurrentStockListView._columnFlex[4]),
          _HeaderCell(
            'Low Stock Threshold',
            flex: CurrentStockListView._columnFlex[5],
          ),
          _HeaderCell('Action', flex: CurrentStockListView._columnFlex[6]),
        ],
      ),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  const _HeaderCell(this.label, {required this.flex});

  final String label;
  final int flex;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Text(
        label,
        style: const TextStyle(
          color: TenantAdminColors.mutedText,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _CurrentStockTableRow extends StatelessWidget {
  const _CurrentStockTableRow({
    required this.row,
    required this.showViewAction,
    this.onView,
  });

  final InventoryBalanceRow row;
  final bool showViewAction;
  final ValueChanged<InventoryBalanceRow>? onView;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        hoverColor: CurrentStockListView._tableHoverColor,
        child: SizedBox(
          height: CurrentStockListView._rowHeight,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: CurrentStockListView._horizontalPadding,
            ),
            child: Row(
              children: [
                _BodyCell(
                  row.productName,
                  flex: CurrentStockListView._columnFlex[0],
                  fontWeight: FontWeight.w600,
                ),
                _BodyCell(
                  row.variantLabel,
                  flex: CurrentStockListView._columnFlex[1],
                ),
                _BodyCell(
                  formatInventoryQuantity(row.onHand),
                  flex: CurrentStockListView._columnFlex[2],
                ),
                _BodyCell(
                  formatInventoryQuantity(row.reserved),
                  flex: CurrentStockListView._columnFlex[3],
                ),
                _BodyCell(
                  formatInventoryQuantity(row.displayAvailable),
                  flex: CurrentStockListView._columnFlex[4],
                ),
                _BodyCell(
                  formatInventoryQuantity(row.lowStockThreshold),
                  flex: CurrentStockListView._columnFlex[5],
                ),
                Expanded(
                  flex: CurrentStockListView._columnFlex[6],
                  child: showViewAction
                      ? TextButton(
                          onPressed:
                              onView == null ? null : () => onView!(row),
                          child: const Text('View'),
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BodyCell extends StatelessWidget {
  const _BodyCell(
    this.value, {
    required this.flex,
    this.fontWeight = FontWeight.w500,
  });

  final String value;
  final int flex;
  final FontWeight fontWeight;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Text(
        value,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: TenantAdminColors.bodyText,
          fontSize: 13,
          fontWeight: fontWeight,
        ),
      ),
    );
  }
}

class _CurrentStockMobileCard extends StatelessWidget {
  const _CurrentStockMobileCard({
    required this.row,
    required this.showViewAction,
    this.onView,
  });

  final InventoryBalanceRow row;
  final bool showViewAction;
  final ValueChanged<InventoryBalanceRow>? onView;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(TenantAdminSpacing.md),
      decoration: BoxDecoration(
        color: TenantAdminColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: TenantAdminColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            row.productName,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            row.variantLabel,
            style: const TextStyle(
              color: TenantAdminColors.mutedText,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: TenantAdminSpacing.sm),
          _MobileMetricRow(
            label: 'On Hand',
            value: formatInventoryQuantity(row.onHand),
          ),
          _MobileMetricRow(
            label: 'Reserved',
            value: formatInventoryQuantity(row.reserved),
          ),
          _MobileMetricRow(
            label: 'Available',
            value: formatInventoryQuantity(row.displayAvailable),
          ),
          _MobileMetricRow(
            label: 'Low Stock Threshold',
            value: formatInventoryQuantity(row.lowStockThreshold),
          ),
          if (showViewAction && onView != null) ...[
            const SizedBox(height: TenantAdminSpacing.sm),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => onView!(row),
                child: const Text('View'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MobileMetricRow extends StatelessWidget {
  const _MobileMetricRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: TenantAdminColors.mutedText,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

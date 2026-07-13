import 'package:flutter/material.dart';

import '../../domain/entities/inventory_entities.dart';
import '../../../presentation/theme/tenant_admin_theme.dart';
import '../../../presentation/widgets/tenant_admin_data_table.dart';
import '../utils/inventory_api_errors.dart';
import 'inventory_pagination.dart';
import 'inventory_status_badges.dart';

class CurrentStockTable extends StatelessWidget {
  const CurrentStockTable({
    super.key,
    required this.page,
    required this.loading,
    required this.errorMessage,
    required this.onRetry,
    required this.onPageChanged,
    required this.showStockInAction,
    required this.onStockIn,
  });

  final CurrentStockPage page;
  final bool loading;
  final String? errorMessage;
  final VoidCallback? onRetry;
  final ValueChanged<int> onPageChanged;
  final bool showStockInAction;
  final VoidCallback onStockIn;

  @override
  Widget build(BuildContext context) {
    return TenantAdminDataTable(
      loading: loading,
      errorMessage: errorMessage,
      onRetry: onRetry,
      emptyTitle: 'No stock records yet',
      emptyMessage:
          'Stock will appear after products are received into an accessible outlet.',
      columns: const [
        DataColumn(label: Text('Product')),
        DataColumn(label: Text('Variant')),
        DataColumn(label: Text('SKU')),
        DataColumn(label: Text('Outlet')),
        DataColumn(label: Text('Batch')),
        DataColumn(label: Text('Expiry')),
        DataColumn(label: Text('On hand'), numeric: true),
        DataColumn(label: Text('Available'), numeric: true),
        DataColumn(label: Text('Stock status')),
        DataColumn(label: Text('Expiry status')),
        DataColumn(label: Text('Actions')),
      ],
      rows: page.items.map((item) => _buildRow(item)).toList(),
      footer: InventoryPagination(
        page: page.page,
        pageSize: page.pageSize,
        totalCount: page.totalCount,
        label: 'stock records',
        onPageChanged: onPageChanged,
      ),
    );
  }

  DataRow _buildRow(CurrentStockItem item) {
    return DataRow(
      cells: [
        DataCell(Text(item.productName, overflow: TextOverflow.ellipsis)),
        DataCell(Text(item.displayVariant, overflow: TextOverflow.ellipsis)),
        DataCell(Text(item.sku ?? '—')),
        DataCell(Text(item.outletName, overflow: TextOverflow.ellipsis)),
        DataCell(Text(item.batchNumber ?? '—')),
        DataCell(Text(item.expiryDate ?? '—')),
        DataCell(InventoryQuantityText(value: item.onHandQuantity)),
        DataCell(
          InventoryQuantityText(value: item.availableQuantity, emphasize: true),
        ),
        DataCell(StockStatusBadge(status: item.stockStatus)),
        DataCell(ExpiryStatusBadge(status: item.expiryStatus)),
        DataCell(
          showStockInAction
              ? TextButton(onPressed: onStockIn, child: const Text('Stock in'))
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}

class CurrentStockMobileCard extends StatelessWidget {
  const CurrentStockMobileCard({
    super.key,
    required this.item,
    required this.showStockInAction,
    required this.onStockIn,
  });

  final CurrentStockItem item;
  final bool showStockInAction;
  final VoidCallback onStockIn;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: TenantAdminSpacing.md),
      padding: const EdgeInsets.all(TenantAdminSpacing.lg),
      decoration: BoxDecoration(
        color: TenantAdminColors.surface,
        borderRadius: BorderRadius.circular(TenantAdminRadius.lg),
        border: Border.all(color: TenantAdminColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.productName,
            style: const TextStyle(
              color: TenantAdminColors.bodyText,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            item.displayVariant,
            style: const TextStyle(
              color: TenantAdminColors.mutedText,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: TenantAdminSpacing.md),
          Wrap(
            spacing: TenantAdminSpacing.sm,
            runSpacing: TenantAdminSpacing.sm,
            children: [
              StockStatusBadge(status: item.stockStatus),
              ExpiryStatusBadge(status: item.expiryStatus),
            ],
          ),
          const SizedBox(height: TenantAdminSpacing.md),
          _InfoRow(label: 'SKU / barcode', value: item.sku ?? item.barcode ?? '—'),
          _InfoRow(label: 'Outlet', value: item.outletName),
          _InfoRow(label: 'Batch', value: item.batchNumber ?? '—'),
          _InfoRow(label: 'Expiry', value: item.expiryDate ?? '—'),
          const SizedBox(height: TenantAdminSpacing.sm),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'On hand',
                      style: TextStyle(
                        color: TenantAdminColors.mutedText,
                        fontSize: 12,
                      ),
                    ),
                    InventoryQuantityText(
                      value: item.onHandQuantity,
                      emphasize: true,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Available',
                      style: TextStyle(
                        color: TenantAdminColors.mutedText,
                        fontSize: 12,
                      ),
                    ),
                    InventoryQuantityText(
                      value: item.availableQuantity,
                      emphasize: true,
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (item.lastMovementAt != null) ...[
            const SizedBox(height: TenantAdminSpacing.sm),
            _InfoRow(label: 'Last movement', value: item.lastMovementAt!),
          ],
          if (showStockInAction) ...[
            const SizedBox(height: TenantAdminSpacing.md),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: onStockIn,
                child: const Text('Stock in'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(
                color: TenantAdminColors.mutedText,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: TenantAdminColors.bodyText,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class InventoryQuantityText extends StatelessWidget {
  const InventoryQuantityText({
    super.key,
    required this.value,
    this.emphasize = false,
  });

  final double value;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    return Text(
      formatInventoryQuantity(value),
      textAlign: TextAlign.right,
      style: TextStyle(
        color:
            emphasize ? TenantAdminColors.bodyText : TenantAdminColors.mutedText,
        fontWeight: emphasize ? FontWeight.w800 : FontWeight.w600,
        fontSize: emphasize ? 16 : 13,
      ),
    );
  }
}

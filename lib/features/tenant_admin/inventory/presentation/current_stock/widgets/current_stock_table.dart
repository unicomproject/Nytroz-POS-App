import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../presentation/theme/tenant_admin_theme.dart';
import '../../../../presentation/widgets/tenant_admin_data_table.dart';
import '../../../../presentation/widgets/tenant_admin_pagination.dart';
import '../../../../presentation/widgets/tenant_admin_status_badge.dart';
import '../../../domain/entities/current_stock_entities.dart';
import '../providers/current_stock_providers.dart';

class CurrentStockTable extends ConsumerWidget {
  const CurrentStockTable({
    super.key,
    required this.stockPage,
  });

  final CurrentStockPage stockPage;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final search = ref.watch(currentStockSearchProvider);
    final currentPage = stockPage.page;
    final pageSize = ref.watch(currentStockPageSizeProvider);

    if (stockPage.items.isEmpty) {
      return Container(
        decoration: BoxDecoration(
          color: TenantAdminColors.surface,
          borderRadius: BorderRadius.circular(TenantAdminRadius.lg),
          border: Border.all(color: TenantAdminColors.border),
        ),
        padding: const EdgeInsets.all(TenantAdminSpacing.xxl),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.inventory_2_outlined,
                size: 48,
                color: TenantAdminColors.mutedText,
              ),
              const SizedBox(height: TenantAdminSpacing.md),
              const Text(
                'No matching stock found',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: TenantAdminColors.bodyText,
                ),
              ),
              const SizedBox(height: TenantAdminSpacing.xs),
              const Text(
                'Try adjusting your search terms or filters.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: TenantAdminColors.mutedText,
                  fontSize: 12,
                ),
              ),
              if (search.isNotEmpty ||
                  ref.read(currentStockStatusFilterProvider) != null) ...[
                const SizedBox(height: TenantAdminSpacing.md),
                TextButton(
                  onPressed: () {
                    ref.read(currentStockSearchProvider.notifier).state = '';
                    ref.read(currentStockStatusFilterProvider.notifier).state =
                        null;
                  },
                  child: const Text('Clear filters'),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return TenantAdminDataTable(
      columns: const [
        DataColumn(label: Text('Product')),
        DataColumn(label: Text('On Hand')),
        DataColumn(label: Text('Reserved')),
        DataColumn(label: Text('Available')),
        DataColumn(label: Text('Status')),
        DataColumn(label: Text('Reorder Level')),
        DataColumn(label: Text('Action')),
      ],
      rows: stockPage.items.map((item) {
        return DataRow(
          onSelectChanged: (selected) {
            if (item.variantId != null) {
              context.go('/tenant-admin/stock/current/${item.variantId}');
            }
          },
          cells: [
            DataCell(
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: TenantAdminColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(TenantAdminRadius.md),
                      image: item.imageUrl != null && item.imageUrl!.isNotEmpty
                          ? DecorationImage(
                              image: NetworkImage(item.imageUrl!),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: item.imageUrl == null || item.imageUrl!.isEmpty
                        ? const Center(
                            child: Icon(
                              Icons.inventory_2_outlined,
                              size: 18,
                              color: TenantAdminColors.primary,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: TenantAdminSpacing.md),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        item.productName ?? 'Unnamed Product',
                        style: (Theme.of(context).textTheme.bodySmall ??
                                const TextStyle())
                            .copyWith(fontWeight: FontWeight.w600),
                      ),
                      if (item.sku != null && item.sku!.isNotEmpty)
                        Text(
                          'SKU: ${item.sku}',
                          style: (Theme.of(context).textTheme.labelSmall ??
                                  const TextStyle())
                              .copyWith(color: TenantAdminColors.mutedText),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            DataCell(Text(item.onHandQuantity.toStringAsFixed(0),
                style: const TextStyle(fontWeight: FontWeight.w600))),
            DataCell(Text(item.reservedQuantity.toStringAsFixed(0),
                style: const TextStyle(fontWeight: FontWeight.w600))),
            DataCell(Text(item.availableQuantity.toStringAsFixed(0),
                style: const TextStyle(fontWeight: FontWeight.w700))),
            DataCell(
              TenantAdminStatusBadge(
                label: item.stockStatus == 'IN_STOCK'
                    ? 'In Stock'
                    : item.stockStatus == 'LOW_STOCK'
                        ? 'Low Stock'
                        : 'Out of Stock',
                status: item.stockStatus == 'IN_STOCK'
                    ? TenantAdminStatusType.success
                    : item.stockStatus == 'LOW_STOCK'
                        ? TenantAdminStatusType.warning
                        : TenantAdminStatusType.danger,
              ),
            ),
            DataCell(Text(item.reorderLevel.toStringAsFixed(0),
                style: (Theme.of(context).textTheme.bodySmall ??
                        const TextStyle())
                    .copyWith(fontWeight: FontWeight.w600))),
            DataCell(
              OutlinedButton(
                onPressed: () {
                  if (item.variantId != null) {
                    context
                        .push('/tenant-admin/stock/current/${item.variantId}');
                  }
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                      horizontal: TenantAdminSpacing.md),
                  side: const BorderSide(color: TenantAdminColors.primary),
                  foregroundColor: TenantAdminColors.primary,
                  shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(TenantAdminRadius.md)),
                ),
                child: Text(
                  'View',
                  style: (Theme.of(context).textTheme.labelSmall ??
                          const TextStyle())
                      .copyWith(
                          color: TenantAdminColors.primary,
                          fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        );
      }).toList(),
      footer: TenantAdminPaginationBar(
        currentPage: currentPage,
        pageSize: pageSize,
        totalCount: stockPage.totalCount,
        itemLabel: 'products',
        onPageChanged: (p) {
          ref.read(currentStockPageProvider.notifier).state = p;
        },
      ),
    );
  }
}

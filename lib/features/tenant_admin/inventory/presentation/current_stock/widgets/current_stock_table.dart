import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../presentation/theme/tenant_admin_theme.dart';
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // "Showing X-Y of Z" text above table
        Padding(
          padding: const EdgeInsets.only(
              bottom: TenantAdminSpacing.md, right: TenantAdminSpacing.sm),
          child: Text(
            'Showing ${stockPage.items.isEmpty ? 0 : ((currentPage - 1) * pageSize + 1)}–${(currentPage * pageSize > stockPage.totalCount) ? stockPage.totalCount : (currentPage * pageSize)} of ${stockPage.totalCount} products',
            style: (Theme.of(context).textTheme.labelSmall ?? const TextStyle())
                .copyWith(color: TenantAdminColors.mutedText),
          ),
        ),

        Container(
          decoration: BoxDecoration(
            color: TenantAdminColors.surface,
            borderRadius: BorderRadius.circular(TenantAdminSpacing.md),
            border: Border.all(color: TenantAdminColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // --- Data Table ---
              if (stockPage.items.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(TenantAdminSpacing.xxl),
                  child: Center(
                    child: Column(
                      children: [
                        const Icon(Icons.inventory_2_outlined,
                            size: 48, color: TenantAdminColors.mutedText),
                        const SizedBox(height: TenantAdminSpacing.md),
                        const Text(
                          'No matching stock found',
                          style: TextStyle(color: TenantAdminColors.mutedText),
                        ),
                        if (search.isNotEmpty ||
                            ref.read(currentStockStatusFilterProvider) !=
                                null) ...[
                          const SizedBox(height: TenantAdminSpacing.md),
                          TextButton(
                            onPressed: () {
                              ref
                                  .read(currentStockSearchProvider.notifier)
                                  .state = '';
                              ref
                                  .read(
                                      currentStockStatusFilterProvider.notifier)
                                  .state = null;
                            },
                            child: const Text('Clear filters'),
                          ),
                        ],
                      ],
                    ),
                  ),
                )
              else
                LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: ConstrainedBox(
                        constraints:
                            BoxConstraints(minWidth: constraints.maxWidth),
                        child: DataTable(
                          headingTextStyle:
                              (Theme.of(context).textTheme.labelSmall ??
                                      const TextStyle())
                                  .copyWith(
                                      color: TenantAdminColors.mutedText,
                                      fontWeight: FontWeight.w600),
                          dataTextStyle:
                              (Theme.of(context).textTheme.bodySmall ??
                                  const TextStyle()),
                          dividerThickness: 1,
                          showCheckboxColumn: false,
                          columns: const [
                            DataColumn(label: Text('Product')),
                            DataColumn(
                                label: Expanded(
                                    child: Text('On Hand',
                                        textAlign: TextAlign.center))),
                            DataColumn(
                                label: Expanded(
                                    child: Text('Reserved',
                                        textAlign: TextAlign.center))),
                            DataColumn(
                                label: Expanded(
                                    child: Text('Available',
                                        textAlign: TextAlign.center))),
                            DataColumn(
                                label: Expanded(
                                    child: Text('Status',
                                        textAlign: TextAlign.center))),
                            DataColumn(
                                label: Expanded(
                                    child: Text('Reorder Level',
                                        textAlign: TextAlign.center))),
                            DataColumn(
                                label: Expanded(
                                    child: Text('Action',
                                        textAlign: TextAlign.center))),
                          ],
                          rows: stockPage.items.map((item) {
                            return DataRow(
                              onSelectChanged: (selected) {
                                if (item.variantId != null) {
                                  context.go(
                                      '/tenant-admin/stock/current/${item.variantId}');
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
                                          color: TenantAdminColors.primary
                                              .withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(
                                              TenantAdminSpacing.sm),
                                          image: item.imageUrl != null &&
                                                  item.imageUrl!.isNotEmpty
                                              ? DecorationImage(
                                                  image: NetworkImage(
                                                      item.imageUrl!),
                                                  fit: BoxFit.cover,
                                                )
                                              : null,
                                        ),
                                        child: item.imageUrl == null ||
                                                item.imageUrl!.isEmpty
                                            ? const Center(
                                                child: Icon(
                                                  Icons.inventory_2_outlined,
                                                  size: 18,
                                                  color:
                                                      TenantAdminColors.primary,
                                                ),
                                              )
                                            : null,
                                      ),
                                      const SizedBox(
                                          width: TenantAdminSpacing.md),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            item.productName ??
                                                'Unnamed Product',
                                            style: (Theme.of(context)
                                                        .textTheme
                                                        .bodySmall ??
                                                    const TextStyle())
                                                .copyWith(
                                                    fontWeight:
                                                        FontWeight.w600),
                                          ),
                                          if (item.sku != null &&
                                              item.sku!.isNotEmpty)
                                            Text(
                                              'SKU: ${item.sku}',
                                              style: (Theme.of(context)
                                                          .textTheme
                                                          .labelSmall ??
                                                      const TextStyle())
                                                  .copyWith(
                                                      color: TenantAdminColors
                                                          .mutedText),
                                            ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                DataCell(Center(
                                    child: Text(
                                        item.onHandQuantity.toStringAsFixed(0),
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w600)))),
                                DataCell(Center(
                                    child: Text(
                                        item.reservedQuantity
                                            .toStringAsFixed(0),
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w600)))),
                                DataCell(Center(
                                    child: Text(
                                        item.availableQuantity
                                            .toStringAsFixed(0),
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w700)))),
                                DataCell(Center(
                                    child: _buildStatusBadge(
                                        context, item.stockStatus))),
                                DataCell(Center(
                                    child: Text(
                                        item.reorderLevel.toStringAsFixed(0),
                                        style: (Theme.of(context)
                                                    .textTheme
                                                    .bodySmall ??
                                                const TextStyle())
                                            .copyWith(
                                                fontWeight: FontWeight.w600)))),
                                DataCell(
                                  Center(
                                    child: OutlinedButton(
                                      onPressed: () {
                                        if (item.variantId != null) {
                                          context.push(
                                              '/tenant-admin/stock/current/${item.variantId}');
                                        }
                                      },
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: TenantAdminSpacing.md),
                                        side: const BorderSide(
                                            color: Color(0xFFF97316)),
                                        foregroundColor:
                                            const Color(0xFFF97316),
                                        shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                                TenantAdminSpacing.sm)),
                                      ),
                                      child: Text(
                                        'View',
                                        style: (Theme.of(context)
                                                    .textTheme
                                                    .labelSmall ??
                                                const TextStyle())
                                            .copyWith(
                                                color: const Color(0xFFF97316),
                                                fontWeight: FontWeight.w600),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                    );
                  },
                ),

              const Divider(height: 1),

              // --- Pagination Footer ---
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: TenantAdminSpacing.lg,
                    vertical: TenantAdminSpacing.md),
                child: Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  runSpacing: TenantAdminSpacing.md,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Rows per page',
                          style: (Theme.of(context).textTheme.labelSmall ??
                                  const TextStyle())
                              .copyWith(color: TenantAdminColors.mutedText),
                        ),
                        const SizedBox(width: TenantAdminSpacing.sm),
                        DropdownButtonHideUnderline(
                          child: Container(
                            height: 32,
                            padding: const EdgeInsets.symmetric(
                                horizontal: TenantAdminSpacing.sm),
                            decoration: BoxDecoration(
                              border:
                                  Border.all(color: TenantAdminColors.border),
                              borderRadius:
                                  BorderRadius.circular(TenantAdminSpacing.sm),
                            ),
                            child: DropdownButton<int>(
                              value: pageSize,
                              icon: const Icon(Icons.keyboard_arrow_down,
                                  size: 16),
                              items: [10, 25, 50].map((int value) {
                                return DropdownMenuItem<int>(
                                  value: value,
                                  child: Text(value.toString(),
                                      style: const TextStyle(fontSize: 12)),
                                );
                              }).toList(),
                              onChanged: (newValue) {
                                if (newValue != null) {
                                  ref
                                      .read(
                                          currentStockPageSizeProvider.notifier)
                                      .state = newValue;
                                  ref
                                      .read(currentStockPageProvider.notifier)
                                      .state = 1;
                                }
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '${stockPage.items.isEmpty ? 0 : ((currentPage - 1) * pageSize + 1)}–${(currentPage * pageSize > stockPage.totalCount) ? stockPage.totalCount : (currentPage * pageSize)} of ${stockPage.totalCount}',
                      style: (Theme.of(context).textTheme.labelSmall ??
                              const TextStyle())
                          .copyWith(color: TenantAdminColors.mutedText),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        OutlinedButton.icon(
                          onPressed: currentPage > 1
                              ? () {
                                  ref
                                      .read(currentStockPageProvider.notifier)
                                      .state = currentPage - 1;
                                }
                              : null,
                          icon: const Icon(Icons.chevron_left, size: 16),
                          label: const Text('Previous'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: TenantAdminSpacing.sm),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                    TenantAdminSpacing.sm)),
                            side: BorderSide(
                                color: currentPage > 1
                                    ? TenantAdminColors.border
                                    : Colors.transparent),
                          ),
                        ),
                        const SizedBox(width: TenantAdminSpacing.sm),
                        ..._buildPageNumbers(context, ref, currentPage,
                            (stockPage.totalCount / pageSize).ceil()),
                        const SizedBox(width: TenantAdminSpacing.sm),
                        OutlinedButton.icon(
                          onPressed: (currentPage * pageSize) <
                                  stockPage.totalCount
                              ? () {
                                  ref
                                      .read(currentStockPageProvider.notifier)
                                      .state = currentPage + 1;
                                }
                              : null,
                          icon: const Icon(Icons.chevron_right, size: 16),
                          label: const Text('Next'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: TenantAdminSpacing.sm),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                    TenantAdminSpacing.sm)),
                            side: BorderSide(
                                color: (currentPage * pageSize) <
                                        stockPage.totalCount
                                    ? TenantAdminColors.border
                                    : Colors.transparent),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  List<Widget> _buildPageNumbers(
      BuildContext context, WidgetRef ref, int currentPage, int totalPages) {
    if (totalPages == 0) return [];

    List<Widget> pages = [];
    final List<int> pageIndices = [];

    if (totalPages <= 5) {
      for (int i = 1; i <= totalPages; i++) {
        pageIndices.add(i);
      }
    } else {
      if (currentPage <= 3) {
        pageIndices.addAll([1, 2, 3, 4, -1, totalPages]);
      } else if (currentPage >= totalPages - 2) {
        pageIndices.addAll([
          1,
          -1,
          totalPages - 3,
          totalPages - 2,
          totalPages - 1,
          totalPages
        ]);
      } else {
        pageIndices.addAll([
          1,
          -1,
          currentPage - 1,
          currentPage,
          currentPage + 1,
          -1,
          totalPages
        ]);
      }
    }

    for (int i = 0; i < pageIndices.length; i++) {
      final pageNum = pageIndices[i];
      if (pageNum == -1) {
        pages.add(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            alignment: Alignment.center,
            child: const Text('...',
                style: TextStyle(color: TenantAdminColors.mutedText)),
          ),
        );
      } else {
        final isActive = pageNum == currentPage;
        pages.add(
          InkWell(
            onTap: isActive
                ? null
                : () {
                    ref.read(currentStockPageProvider.notifier).state = pageNum;
                  },
            child: Container(
              width: 32,
              height: 32,
              alignment: Alignment.center,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                color:
                    isActive ? TenantAdminColors.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(TenantAdminSpacing.sm),
                border: Border.all(
                    color: isActive
                        ? TenantAdminColors.primary
                        : Colors.transparent),
              ),
              child: Text(
                pageNum.toString(),
                style: TextStyle(
                  color: isActive ? Colors.white : TenantAdminColors.bodyText,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        );
      }
    }
    return pages;
  }

  Widget _buildStatusBadge(BuildContext context, String status) {
    Color bg;
    Color text;
    String label;

    switch (status.toLowerCase()) {
      case 'instock':
        bg = Colors.green.withValues(alpha: 0.1);
        text = Colors.green;
        label = 'In Stock';
        break;
      case 'lowstock':
        bg = Colors.orange.withValues(alpha: 0.1);
        text = Colors.orange;
        label = 'Low Stock';
        break;
      case 'outofstock':
        bg = Colors.red.withValues(alpha: 0.1);
        text = Colors.red;
        label = 'Out of Stock';
        break;
      default:
        bg = Colors.grey.withValues(alpha: 0.1);
        text = Colors.grey;
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: TenantAdminSpacing.sm, vertical: TenantAdminSpacing.xs),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(TenantAdminSpacing.lg),
      ),
      child: Text(
        label,
        style: (Theme.of(context).textTheme.labelSmall ?? const TextStyle())
            .copyWith(color: text, fontWeight: FontWeight.w600),
      ),
    );
  }
}

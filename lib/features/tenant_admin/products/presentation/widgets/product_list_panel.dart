import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../domain/services/tenant_admin_access_checker.dart';
import '../../../presentation/theme/tenant_admin_theme.dart';
import '../../domain/entities/tenant_product.dart';
import '../providers/tenant_product_providers.dart';
import 'product_table.dart';

class ProductListPanel extends ConsumerWidget {
  const ProductListPanel({
    super.key,
    required this.result,
    required this.visibility,
  });

  final TenantProductListResult result;
  final ProductListVisibility visibility;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (result.items.isEmpty)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(TenantAdminSpacing.xl),
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
                      'No matching products found',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: TenantAdminColors.bodyText,
                      ),
                    ),
                    const SizedBox(height: TenantAdminSpacing.xs),
                    const Text(
                      'Please check your spelling or adjust your filters.',
                      style: TextStyle(color: TenantAdminColors.mutedText),
                    ),
                    const SizedBox(height: TenantAdminSpacing.lg),
                    TextButton(
                      onPressed: () {
                        ref
                            .read(productListFilterProvider.notifier)
                            .resetFilters();
                      },
                      child: const Text('Reset Filters'),
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          Expanded(
            child: ProductTable(
              products: result.items,
              visibility: visibility,
              onView: (product) {
                if (product.status == 'DRAFT') {
                  context.go('/tenant-admin/products/draft/${product.id}');
                } else {
                  context.go('/tenant-admin/products/${product.id}');
                }
              },
              onEdit: (product) {
                if (product.status == 'DRAFT') {
                  context.go('/tenant-admin/products/draft/${product.id}');
                } else {
                  context.go('/tenant-admin/products/${product.id}/edit');
                }
              },
            ),
          ),
        if (visibility.showPagination && result.totalCount > 0) ...[
          const SizedBox(height: TenantAdminSpacing.md),
          _PaginationFooter(
            page: result.page,
            pageSize: result.pageSize,
            totalCount: result.totalCount,
          ),
        ],
      ],
    );
  }
}

class _PaginationFooter extends ConsumerWidget {
  const _PaginationFooter({
    required this.page,
    required this.pageSize,
    required this.totalCount,
  });

  final int page;
  final int pageSize;
  final int totalCount;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final totalPages =
        pageSize <= 0 ? 1 : (totalCount / pageSize).ceil().clamp(1, 9999);
    final rangeStart = totalCount == 0 ? 0 : ((page - 1) * pageSize) + 1;
    final rangeEnd = (page * pageSize).clamp(0, totalCount);

    final notifier = ref.read(productListFilterProvider.notifier);

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: TenantAdminSpacing.sm,
        vertical: TenantAdminSpacing.sm,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Showing $rangeStart to $rangeEnd of $totalCount products',
            style: const TextStyle(
              color: TenantAdminColors.mutedText,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 34,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  border: Border.all(color: TenantAdminColors.border),
                  borderRadius: BorderRadius.circular(TenantAdminRadius.md),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: pageSize,
                    icon: const Icon(Icons.keyboard_arrow_down, size: 16),
                    isDense: true,
                    items: const [
                      DropdownMenuItem(value: 6, child: Text('6')),
                      DropdownMenuItem(value: 8, child: Text('8')),
                      DropdownMenuItem(value: 10, child: Text('10')),
                      DropdownMenuItem(value: 25, child: Text('25')),
                      DropdownMenuItem(value: 50, child: Text('50')),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        notifier.setPageSize(val);
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(width: TenantAdminSpacing.md),
              _PageButton(
                icon: Icons.chevron_left,
                onPressed: page > 1 ? () => notifier.setPage(page - 1) : null,
              ),
              const SizedBox(width: 4),
              for (final pageNum in _buildPageNumbers(page, totalPages)) ...[
                if (pageNum == -1)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4),
                    child: Text('...',
                        style: TextStyle(color: TenantAdminColors.mutedText)),
                  )
                else
                  _PageNumberButton(
                    pageNumber: pageNum,
                    isActive: pageNum == page,
                    onPressed: () => notifier.setPage(pageNum),
                  ),
                const SizedBox(width: 4),
              ],
              _PageButton(
                icon: Icons.chevron_right,
                onPressed:
                    page < totalPages ? () => notifier.setPage(page + 1) : null,
              ),
            ],
          ),
        ],
      ),
    );
  }

  static List<int> _buildPageNumbers(int current, int total) {
    if (total <= 5) {
      return List.generate(total, (i) => i + 1);
    }
    final pages = <int>[];
    pages.add(1);
    if (current > 3) {
      pages.add(-1);
    }
    final start = (current - 1).clamp(2, total - 1);
    final end = (current + 1).clamp(2, total - 1);
    for (int i = start; i <= end; i++) {
      if (!pages.contains(i)) {
        pages.add(i);
      }
    }
    if (current < total - 2) {
      pages.add(-1);
    }
    if (!pages.contains(total)) {
      pages.add(total);
    }
    return pages;
  }
}

class _PageButton extends StatelessWidget {
  const _PageButton({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        border: Border.all(color: TenantAdminColors.border),
        borderRadius: BorderRadius.circular(TenantAdminRadius.md),
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
        padding: EdgeInsets.zero,
        splashRadius: 18,
      ),
    );
  }
}

class _PageNumberButton extends StatelessWidget {
  const _PageNumberButton({
    required this.pageNumber,
    required this.isActive,
    required this.onPressed,
  });

  final int pageNumber;
  final bool isActive;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isActive
            ? TenantAdminColors.posHomeAccentOrange
            : Colors.transparent,
        border: Border.all(
          color: isActive
              ? TenantAdminColors.posHomeAccentOrange
              : TenantAdminColors.border,
        ),
        borderRadius: BorderRadius.circular(TenantAdminRadius.md),
      ),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(TenantAdminRadius.md),
        child: Center(
          child: Text(
            '$pageNumber',
            style: TextStyle(
              color: isActive ? Colors.white : TenantAdminColors.bodyText,
              fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}

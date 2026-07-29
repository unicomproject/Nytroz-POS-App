import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../domain/services/tenant_admin_access_checker.dart';
import '../../../presentation/theme/tenant_admin_theme.dart';
import '../../../presentation/widgets/tenant_admin_states.dart';
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
    final productCountLabel =
        '${result.totalCount > 0 ? result.totalCount : result.items.length} '
        '${result.totalCount == 1 ? 'Product' : 'Products'}';

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: TenantAdminColors.surface,
        borderRadius: BorderRadius.circular(TenantAdminRadius.md),
        border: Border.all(color: TenantAdminColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: TenantAdminSpacing.lg,
              vertical: TenantAdminSpacing.md,
            ),
            child: _PanelTitle(countLabel: productCountLabel),
          ),
          const Divider(height: 1, color: TenantAdminColors.border),
          if (result.items.isEmpty)
            const Padding(
              padding: EdgeInsets.all(TenantAdminSpacing.xl),
              child: TenantAdminEmptyState(
                title: 'No products found',
                message: 'Try adjusting your search or add a new product.',
                icon: Icons.inventory_2_outlined,
              ),
            )
          else
            ProductTable(
              products: result.items,
              visibility: visibility,
              onView: (product) =>
                  context.go('/tenant-admin/products/${product.id}'),
              onEdit: (product) =>
                  context.go('/tenant-admin/products/${product.id}/edit'),
            ),
          if (visibility.showPagination && result.totalCount > 0)
            _PaginationFooter(
              page: result.page,
              pageSize: result.pageSize,
              totalCount: result.totalCount,
              onPageChanged: (nextPage) =>
                  ref.read(productPageProvider.notifier).state = nextPage,
            ),
        ],
      ),
    );
  }
}

class _PanelTitle extends StatelessWidget {
  const _PanelTitle({required this.countLabel});

  final String countLabel;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Product List',
            style: TenantAdminTextStyles.sectionTitle(context)),
        const SizedBox(width: TenantAdminSpacing.sm),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: TenantAdminSpacing.sm,
            vertical: TenantAdminSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: TenantAdminColors.secondary,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            countLabel,
            style: const TextStyle(
              color: TenantAdminColors.primary,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

class _PaginationFooter extends StatelessWidget {
  const _PaginationFooter({
    required this.page,
    required this.pageSize,
    required this.totalCount,
    required this.onPageChanged,
  });

  final int page;
  final int pageSize;
  final int totalCount;
  final ValueChanged<int> onPageChanged;

  @override
  Widget build(BuildContext context) {
    final totalPages =
        pageSize <= 0 ? 1 : (totalCount / pageSize).ceil().clamp(1, 9999);
    final rangeStart = totalCount == 0 ? 0 : ((page - 1) * pageSize) + 1;
    final rangeEnd = (page * pageSize).clamp(0, totalCount);

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: TenantAdminSpacing.lg,
        vertical: TenantAdminSpacing.md,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Showing $rangeStart to $rangeEnd of $totalCount products',
              style: const TextStyle(
                color: TenantAdminColors.mutedText,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          IconButton(
            onPressed: page > 1 ? () => onPageChanged(page - 1) : null,
            icon: const Icon(Icons.chevron_left, size: 18),
          ),
          Text('$page / $totalPages'),
          IconButton(
            onPressed: page < totalPages ? () => onPageChanged(page + 1) : null,
            icon: const Icon(Icons.chevron_right, size: 18),
          ),
        ],
      ),
    );
  }
}

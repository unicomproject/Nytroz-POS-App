import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../domain/services/tenant_admin_access_checker.dart';
import '../../../presentation/theme/tenant_admin_theme.dart';
import '../../../presentation/widgets/tenant_admin_buttons.dart';
import '../../../presentation/widgets/tenant_admin_search_field.dart';
import '../../../presentation/widgets/tenant_admin_states.dart';
import '../../domain/entities/product.dart';
import '../providers/product_providers.dart';
import '../utils/product_list_filters.dart';
import 'product_filter_chips.dart';
import 'product_list_view.dart';
import 'products_list_header_actions.dart';

class ProductListPanel extends ConsumerWidget {
  const ProductListPanel({
    super.key,
    required this.result,
    required this.visibility,
    required this.statusFilter,
    required this.isMobile,
  });

  final ProductListResult result;
  final ProductListVisibility visibility;
  final ProductStatusFilter statusFilter;
  final bool isMobile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final countLabel =
        '${result.displayTotalCount} '
        '${result.displayTotalCount == 1 ? 'Product' : 'Products'}';

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: TenantAdminColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: TenantAdminColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08071A33),
            blurRadius: 24,
            offset: Offset(0, 8),
          ),
          BoxShadow(
            color: Color(0x04071A33),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Toolbar header matching the reference screenshot exactly
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 16,
            ),
            child: isMobile
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ProductSearchToolbar(
                        visibility: visibility,
                        isMobile: true,
                      ),
                      const SizedBox(height: TenantAdminSpacing.md),
                      ProductsListHeaderActions(
                        visibility: visibility,
                        isMobile: true,
                      ),
                    ],
                  )
                : Row(
                    children: [
                      // Search Bar
                      Expanded(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 400),
                          child: ProductSearchToolbar(
                            visibility: visibility,
                            isMobile: false,
                          ),
                        ),
                      ),
                      const Spacer(),
                      // Actions aligned to the right (Filters, Import, Add Product)
                      ProductsListHeaderActions(
                        visibility: visibility,
                        isMobile: false,
                      ),
                    ],
                  ),
          ),
          const Divider(height: 1, color: TenantAdminColors.border),
          if (result.items.isEmpty)
            Padding(
              padding: const EdgeInsets.all(TenantAdminSpacing.xl),
              child: TenantAdminEmptyState(
                title: statusFilter == ProductStatusFilter.all
                    ? 'No products found'
                    : 'No matching products',
                message: statusFilter == ProductStatusFilter.all
                    ? 'Create your first product to get started.'
                    : 'Try changing the filter or search term.',
                icon: statusFilter == ProductStatusFilter.all
                    ? Icons.inventory_2_outlined
                    : Icons.filter_alt_off_outlined,
                action: statusFilter == ProductStatusFilter.all
                    ? _EmptyProductActions(visibility: visibility)
                    : statusFilter != ProductStatusFilter.all
                        ? TenantAdminSecondaryButton(
                            label: 'Clear filters',
                            icon: Icons.clear,
                            onPressed: () => _resetFilters(ref),
                          )
                        : null,
              ),
            )
          else
            ProductListView(
              result: result,
              visibility: visibility,
              isMobile: isMobile,
            ),
          if (visibility.showPagination && result.displayTotalCount > 0)
            _PaginationFooter(
              page: result.page,
              pageSize: result.pageSize,
              totalCount: result.displayTotalCount,
              onPageChanged: (nextPage) =>
                  ref.read(productPageProvider.notifier).state = nextPage,
            ),
        ],
      ),
    );
  }

  void _resetFilters(WidgetRef ref) {
    ref.read(productStatusFilterProvider.notifier).state =
        ProductStatusFilter.all;
    ref.read(productSearchProvider.notifier).state = '';
    ref.read(productPageProvider.notifier).state = 1;
  }
}

class _EmptyProductActions extends StatelessWidget {
  const _EmptyProductActions({required this.visibility});

  final ProductListVisibility visibility;

  @override
  Widget build(BuildContext context) {
    if (!visibility.showAddProduct && !visibility.showImportCsv) {
      return const SizedBox.shrink();
    }

    return Wrap(
      spacing: TenantAdminSpacing.sm,
      runSpacing: TenantAdminSpacing.sm,
      children: [
        if (visibility.showAddProduct)
          TenantAdminPrimaryButton(
            label: 'Add product',
            icon: Icons.add,
            onPressed: () => context.go('/tenant-admin/products/add'),
          ),
        if (visibility.showImportCsv)
          TenantAdminSecondaryButton(
            label: 'Import CSV',
            icon: Icons.file_upload_outlined,
            onPressed: () => context.go('/tenant-admin/products/import'),
          ),
      ],
    );
  }
}

class ProductSearchToolbar extends ConsumerWidget {
  const ProductSearchToolbar({
    super.key,
    required this.visibility,
    required this.isMobile,
  });

  final ProductListVisibility visibility;
  final bool isMobile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!visibility.showSearch) {
      return const SizedBox.shrink();
    }

    return TenantAdminSearchField(
      hint: 'Search by product name, SKU or barcode...',
      value: ref.watch(productSearchProvider),
      onChanged: (value) {
        ref.read(productSearchProvider.notifier).state = value;
        ref.read(productPageProvider.notifier).state = 1;
      },
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
        vertical: TenantAdminSpacing.sm,
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
          _PageButton(
            icon: Icons.chevron_left,
            onPressed: page > 1 ? () => onPageChanged(page - 1) : null,
          ),
          const SizedBox(width: TenantAdminSpacing.sm),
          _PageNumber(
            label: '$page',
            active: true,
            onPressed: () {},
          ),
          if (page < totalPages) ...[
            const SizedBox(width: TenantAdminSpacing.sm),
            _PageNumber(
              label: '${page + 1}',
              active: false,
              onPressed: () => onPageChanged(page + 1),
            ),
          ],
          const SizedBox(width: TenantAdminSpacing.sm),
          _PageButton(
            icon: Icons.chevron_right,
            onPressed: page < totalPages ? () => onPageChanged(page + 1) : null,
          ),
        ],
      ),
    );
  }
}

class _PageButton extends StatelessWidget {
  const _PageButton({
    required this.icon,
    required this.onPressed,
  });

  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      style: IconButton.styleFrom(
        minimumSize: const Size(34, 34),
        padding: EdgeInsets.zero,
        side: const BorderSide(color: TenantAdminColors.border),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(TenantAdminRadius.sm),
        ),
      ),
      icon: Icon(icon, size: 18),
    );
  }
}

class _PageNumber extends StatelessWidget {
  const _PageNumber({
    required this.label,
    required this.active,
    required this.onPressed,
  });

  final String label;
  final bool active;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 34,
      height: 34,
      child: OutlinedButton(
        onPressed: active ? null : onPressed,
        style: OutlinedButton.styleFrom(
          padding: EdgeInsets.zero,
          backgroundColor:
              active ? TenantAdminColors.primary : TenantAdminColors.surface,
          foregroundColor: active ? Colors.white : TenantAdminColors.bodyText,
          disabledBackgroundColor: TenantAdminColors.primary,
          disabledForegroundColor: Colors.white,
          side: BorderSide(
            color:
                active ? TenantAdminColors.primary : TenantAdminColors.border,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(TenantAdminRadius.sm),
          ),
        ),
        child: Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../domain/services/tenant_admin_access_checker.dart';
import '../../../presentation/theme/tenant_admin_theme.dart';
import '../../../presentation/widgets/tenant_admin_pagination.dart';
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
          TenantAdminPaginationBar(
            currentPage: result.page,
            pageSize: result.pageSize,
            totalCount: result.totalCount,
            itemLabel: 'products',
            onPageChanged: (page) =>
                ref.read(productListFilterProvider.notifier).setPage(page),
          ),
        ],
      ],
    );
  }
}

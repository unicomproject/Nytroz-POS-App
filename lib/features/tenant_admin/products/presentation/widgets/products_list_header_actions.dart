import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../domain/services/tenant_admin_access_checker.dart';
import '../../../presentation/theme/tenant_admin_theme.dart';
import '../../../presentation/widgets/tenant_admin_buttons.dart';
import '../providers/product_providers.dart';
import '../utils/product_list_filters.dart';

class ProductsListHeaderActions extends ConsumerWidget {
  const ProductsListHeaderActions({
    super.key,
    required this.visibility,
    required this.isMobile,
  });

  final ProductListVisibility visibility;
  final bool isMobile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!visibility.showFilters &&
        !visibility.showAddProduct &&
        !visibility.showImportCsv) {
      return const SizedBox.shrink();
    }

    final children = <Widget>[
      if (visibility.showFilters)
        TenantAdminSecondaryButton(
          label: isMobile ? 'Filter' : 'Filters',
          icon: Icons.filter_alt_outlined,
          onPressed: () => _showFilterSheet(context, ref),
        ),
      if (visibility.showImportCsv) ...[
        if (visibility.showFilters) const SizedBox(width: TenantAdminSpacing.sm),
        TenantAdminSecondaryButton(
          label: 'Import',
          icon: Icons.file_upload_outlined,
          onPressed: () => context.go('/tenant-admin/products/import'),
        ),
      ],
      // Add Product Button
      if (visibility.showAddProduct) ...[
        const SizedBox(width: TenantAdminSpacing.sm),
        TenantAdminPrimaryButton(
          label: isMobile ? 'Add' : 'Add Product',
          icon: Icons.add,
          onPressed: () => context.go('/tenant-admin/products/add'),
        ),
      ],
    ];

    if (isMobile) {
      return Wrap(
        spacing: TenantAdminSpacing.sm,
        runSpacing: TenantAdminSpacing.sm,
        children: children,
      );
    }

    return Row(mainAxisSize: MainAxisSize.min, children: children);
  }

  Future<void> _showFilterSheet(BuildContext context, WidgetRef ref) {
    final currentFilter = ref.read(productStatusFilterProvider);

    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Filter products',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                    color: TenantAdminColors.bodyText,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Select a status to filter the product list.',
                  style: TextStyle(
                    color: TenantAdminColors.mutedText,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: TenantAdminSpacing.lg),
                for (final filter in ProductStatusFilter.values) ...[
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        ref.read(productStatusFilterProvider.notifier).state =
                            filter;
                        ref.read(productPageProvider.notifier).state = 1;
                        Navigator.of(context).pop();
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: currentFilter == filter
                              ? TenantAdminColors.primary
                                  .withValues(alpha: 0.06)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: currentFilter == filter
                                ? TenantAdminColors.primary
                                    .withValues(alpha: 0.2)
                                : TenantAdminColors.border,
                          ),
                        ),
                        child: Row(
                          children: [
                            Text(
                              filter.label,
                              style: TextStyle(
                                color: currentFilter == filter
                                    ? TenantAdminColors.primary
                                    : TenantAdminColors.bodyText,
                                fontWeight: currentFilter == filter
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                fontSize: 14,
                              ),
                            ),
                            const Spacer(),
                            if (currentFilter == filter)
                              const Icon(
                                Icons.check_circle,
                                color: TenantAdminColors.primary,
                                size: 20,
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

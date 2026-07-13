import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../domain/services/tenant_admin_access_checker.dart';
import '../../../presentation/theme/tenant_admin_theme.dart';
import '../../../presentation/widgets/tenant_admin_buttons.dart';
import '../../../presentation/widgets/tenant_admin_page_scaffold.dart';
import '../../../presentation/widgets/tenant_admin_search_field.dart';
import '../../../presentation/widgets/tenant_admin_states.dart';
import '../providers/tenant_product_providers.dart';
import '../providers/tenant_product_visibility_provider.dart';
import '../widgets/product_list_panel.dart';
import '../widgets/product_summary_section.dart';

class ProductListScreen extends ConsumerWidget {
  const ProductListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final visibilityState = ref.watch(productListVisibilityProvider);

    return visibilityState.when(
      loading: () => const TenantAdminPageScaffold(
        title: 'Products',
        subtitle: 'Manage your products, categories and pricing.',
        child: TenantAdminLoadingSkeleton(rowCount: 8),
      ),
      error: (error, stackTrace) => TenantAdminPageScaffold(
        title: 'Products',
        subtitle: 'Manage your products, categories and pricing.',
        child: TenantAdminErrorState(
          title: 'Unable to load products',
          message: 'Please try again.',
          onRetry: () => ref.invalidate(productListVisibilityProvider),
        ),
      ),
      data: (visibility) {
        if (!visibility.showPage) {
          return const TenantAdminPageScaffold(
            title: 'No access to Products',
            child: TenantAdminEmptyState(
              title: 'No access',
              message: 'You do not have permission to view products.',
              icon: Icons.inventory_2_outlined,
            ),
          );
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth < 700;

            return TenantAdminPageScaffold(
              title: visibility.showTitle ? 'Products' : '',
              subtitle: visibility.showSubtitle
                  ? 'Manage your products, categories and pricing.'
                  : null,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ProductSearchToolbar(
                    visibility: visibility,
                    isMobile: isMobile,
                  ),
                  if (visibility.showSearch || visibility.showAddProduct)
                    const SizedBox(height: TenantAdminSpacing.lg),
                  if (visibility.showSummarySection) ...[
                    ProductSummarySection(compact: isMobile),
                    const SizedBox(height: TenantAdminSpacing.xl),
                  ],
                  if (visibility.showList) const _ProductListBody(),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _ProductListBody extends ConsumerWidget {
  const _ProductListBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final visibility = ref.watch(productListVisibilityProvider).valueOrNull;
    final productsState = ref.watch(productListProvider);

    if (visibility == null) {
      return const TenantAdminLoadingSkeleton(rowCount: 6);
    }

    return productsState.when(
      loading: () => const TenantAdminLoadingSkeleton(rowCount: 6),
      error: (error, stackTrace) => TenantAdminErrorState(
        title: 'Unable to load products',
        message: 'Please try again.',
        onRetry: () => ref.refresh(productListProvider),
      ),
      data: (result) {
        if (result == null) {
          return const TenantAdminEmptyState(
            title: 'No access',
            message: 'You do not have permission to view products.',
            icon: Icons.inventory_2_outlined,
          );
        }

        return ProductListPanel(
          result: result,
          visibility: visibility,
        );
      },
    );
  }
}

class _ProductSearchToolbar extends ConsumerWidget {
  const _ProductSearchToolbar({
    required this.visibility,
    required this.isMobile,
  });

  final ProductListVisibility visibility;
  final bool isMobile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!visibility.showSearch && !visibility.showAddProduct) {
      return const SizedBox.shrink();
    }

    final searchField = TenantAdminSearchField(
      hint: 'Search by product name, SKU or barcode',
      value: ref.watch(productSearchProvider),
      onChanged: (value) {
        ref.read(productSearchProvider.notifier).state = value;
        ref.read(productPageProvider.notifier).state = 1;
      },
    );

    final addButton = TenantAdminPrimaryButton(
      label: 'Add Product',
      icon: Icons.add,
      onPressed: visibility.showAddProduct
          ? () => context.go('/tenant-admin/products/add')
          : null,
    );

    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (visibility.showSearch) searchField,
          if (visibility.showAddProduct) ...[
            if (visibility.showSearch)
              const SizedBox(height: TenantAdminSpacing.sm),
            Align(alignment: Alignment.centerRight, child: addButton),
          ],
        ],
      );
    }

    return Row(
      children: [
        if (visibility.showSearch) Expanded(child: searchField),
        if (visibility.showAddProduct) ...[
          const SizedBox(width: TenantAdminSpacing.md),
          addButton,
        ],
      ],
    );
  }
}

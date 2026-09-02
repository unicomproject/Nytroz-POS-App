import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../domain/services/tenant_admin_access_checker.dart';
import '../../../presentation/providers/tenant_admin_access_provider.dart';
import '../../../presentation/theme/tenant_admin_theme.dart';
import '../../../presentation/widgets/tenant_admin_buttons.dart';
import '../../../presentation/widgets/tenant_admin_page_scaffold.dart';
import '../../../presentation/widgets/tenant_admin_search_field.dart';
import '../../../presentation/widgets/tenant_admin_states.dart';
import '../../domain/entities/tenant_product_filter_options.dart';
import '../providers/tenant_product_providers.dart';
import '../providers/tenant_product_visibility_provider.dart';
import '../widgets/product_list_panel.dart';

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
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline,
                  size: 48, color: TenantAdminColors.danger),
              const SizedBox(height: TenantAdminSpacing.md),
              const Text(
                'Failed to load products page',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: TenantAdminColors.bodyText),
              ),
              const SizedBox(height: TenantAdminSpacing.xs),
              Text(error.toString(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: TenantAdminColors.mutedText)),
              const SizedBox(height: TenantAdminSpacing.lg),
              TextButton.icon(
                onPressed: () => ref.invalidate(productListVisibilityProvider),
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
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
            final productsState = ref.watch(productListProvider);
            final isFirstTimeEmpty = productsState.maybeWhen(
              data: (result) =>
                  result != null &&
                  result.totalCount == 0 &&
                  result.catalogTotalCount == 0,
              orElse: () => false,
            );

            return TenantAdminPageScaffold(
              title: visibility.showTitle ? 'Products' : '',
              subtitle: (visibility.showSubtitle && !isFirstTimeEmpty)
                  ? 'Manage your products, categories and pricing.'
                  : null,
              headerSpacing: TenantAdminSpacing.sm,
              scrollable: false,
              actions: [
                if (visibility.showAddProduct)
                  TenantAdminPrimaryButton(
                    label: 'Add Product',
                    icon: Icons.add,
                    backgroundColor: TenantAdminColors.posHomeAccentOrange,
                    onPressed: () => context.go('/tenant-admin/products/add'),
                  ),
              ],
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isFirstTimeEmpty) ...[
                    _ProductSearchToolbar(
                      visibility: visibility,
                      isMobile: isMobile,
                    ),
                    if (visibility.showSearch || visibility.showAddProduct)
                      const SizedBox(height: TenantAdminSpacing.lg),
                  ],
                  if (visibility.showList)
                    const Expanded(child: _ProductListBody()),
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
        onRetry: () => ref.invalidate(productListProvider),
      ),
      data: (result) {
        if (result == null) {
          return const TenantAdminEmptyState(
            title: 'No access',
            message: 'You do not have permission to view products.',
            icon: Icons.inventory_2_outlined,
          );
        }

        if (result.totalCount == 0 && result.catalogTotalCount == 0) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 48.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.inventory_2_outlined,
                    size: 96,
                    color: TenantAdminColors.mutedText,
                  ),
                  const SizedBox(height: TenantAdminSpacing.lg),
                  Text(
                    'No products yet',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: TenantAdminColors.bodyText,
                        ),
                  ),
                  const SizedBox(height: TenantAdminSpacing.xs),
                  const Text(
                    'Start by adding your first product.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: TenantAdminColors.mutedText),
                  ),
                  const SizedBox(height: TenantAdminSpacing.xl),
                  if (visibility.showAddProduct)
                    TenantAdminPrimaryButton(
                      label: 'Add Product',
                      icon: Icons.add,
                      backgroundColor: TenantAdminColors.posHomeAccentOrange,
                      onPressed: () => context.go('/tenant-admin/products/add'),
                    ),
                  const SizedBox(height: TenantAdminSpacing.xl),
                  const Divider(height: 1, color: TenantAdminColors.border),
                  const SizedBox(height: TenantAdminSpacing.lg),
                  const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.info_outline,
                          size: 16, color: TenantAdminColors.mutedText),
                      SizedBox(width: TenantAdminSpacing.xs),
                      Text(
                        'Products, variants, pricing, and stock will appear here once created.',
                        style: TextStyle(
                            color: TenantAdminColors.mutedText, fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),
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

    final filterState = ref.watch(productListFilterProvider);
    final filterNotifier = ref.read(productListFilterProvider.notifier);

    final canViewStock = ref
            .watch(tenantAdminAccessCheckerProvider)
            .valueOrNull
            ?.canViewCurrentStock() ??
        false;
    final optionsAsync = ref.watch(productFilterOptionsProvider);

    final searchField = TenantAdminSearchField(
      hint: 'Search by product name, code, SKU or barcode',
      value: filterState.search,
      onChanged: filterNotifier.setSearch,
    );

    final isFiltered = filterState.search.isNotEmpty ||
        filterState.categoryId != null ||
        filterState.brandId != null ||
        filterState.productStatus != null ||
        filterState.stockStatus != null;

    final resetButton = TextButton.icon(
      style: TextButton.styleFrom(
        foregroundColor: const Color(0xFF6B7280),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
      onPressed: isFiltered ? filterNotifier.resetFilters : null,
      icon: const Icon(Icons.refresh, size: 18),
      label: const Text(
        'Reset Filters',
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
      ),
    );

    Widget buildFilters(TenantProductFilterOptions? options, bool loading) {
      final categories = options?.categories ?? [];
      final brands = options?.brands ?? [];
      final productStatuses = options?.productStatuses ?? [];
      final stockStatuses = options?.stockStatuses ?? [];

      final dropdownDecoration = InputDecoration(
        filled: true,
        fillColor: TenantAdminColors.surface,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(TenantAdminRadius.md),
          borderSide: const BorderSide(color: TenantAdminColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(TenantAdminRadius.md),
          borderSide: const BorderSide(color: TenantAdminColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(TenantAdminRadius.md),
          borderSide: const BorderSide(color: TenantAdminColors.primary),
        ),
        isDense: true,
      );

      final categoryDropdown = DropdownButtonFormField<String?>(
        key: ValueKey(filterState.categoryId),
        initialValue: filterState.categoryId,
        icon: const Icon(Icons.keyboard_arrow_down,
            color: TenantAdminColors.mutedText),
        dropdownColor: TenantAdminOverlaySurfaces.color,
        decoration: dropdownDecoration,
        items: [
          const DropdownMenuItem<String?>(
            value: null,
            child: Text('Category', style: TextStyle(fontSize: 12.5), maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
          ...categories.map(
            (c) => DropdownMenuItem<String?>(
              value: c.id,
              child: Text(c.name, overflow: TextOverflow.ellipsis),
            ),
          ),
        ],
        onChanged: loading ? null : filterNotifier.setCategory,
        isExpanded: true,
      );

      final brandDropdown = DropdownButtonFormField<String?>(
        key: ValueKey(filterState.brandId),
        initialValue: filterState.brandId,
        icon: const Icon(Icons.keyboard_arrow_down,
            color: TenantAdminColors.mutedText),
        dropdownColor: TenantAdminOverlaySurfaces.color,
        decoration: dropdownDecoration,
        items: [
          const DropdownMenuItem<String?>(
            value: null,
            child: Text('Brand', style: TextStyle(fontSize: 12.5), maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
          ...brands.map(
            (b) => DropdownMenuItem<String?>(
              value: b.id,
              child: Text(b.name, overflow: TextOverflow.ellipsis),
            ),
          ),
        ],
        onChanged: loading ? null : filterNotifier.setBrand,
        isExpanded: true,
      );

      final statusDropdown = DropdownButtonFormField<String?>(
        key: ValueKey(filterState.productStatus),
        initialValue: filterState.productStatus,
        icon: const Icon(Icons.keyboard_arrow_down,
            color: TenantAdminColors.mutedText),
        dropdownColor: TenantAdminOverlaySurfaces.color,
        decoration: dropdownDecoration,
        items: [
          const DropdownMenuItem<String?>(
            value: null,
            child: Text('Product Status', style: TextStyle(fontSize: 12.5), maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
          ...productStatuses.map(
            (s) => DropdownMenuItem<String?>(
              value: s,
              child: Text(s),
            ),
          ),
        ],
        onChanged: loading ? null : filterNotifier.setProductStatus,
        isExpanded: true,
      );

      final stockStatusDropdown = DropdownButtonFormField<String?>(
        key: ValueKey(filterState.stockStatus),
        initialValue: filterState.stockStatus,
        icon: const Icon(Icons.keyboard_arrow_down,
            color: TenantAdminColors.mutedText),
        dropdownColor: TenantAdminOverlaySurfaces.color,
        decoration: dropdownDecoration,
        items: [
          const DropdownMenuItem<String?>(
            value: null,
            child: Text('Stock Status', style: TextStyle(fontSize: 12.5), maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
          ...stockStatuses.map(
            (s) => DropdownMenuItem<String?>(
              value: s,
              child: Text(s.replaceAll('_', ' ')),
            ),
          ),
        ],
        onChanged: loading ? null : filterNotifier.setStockStatus,
        isExpanded: true,
      );

      // Always single row: search (wider) + filters (shorter) + reset
      return Row(
        children: [
          Expanded(
            flex: 7,
            child: searchField,
          ),
          const SizedBox(width: TenantAdminSpacing.md),
          Expanded(
            flex: 4,
            child: categoryDropdown,
          ),
          const SizedBox(width: TenantAdminSpacing.md),
          Expanded(
            flex: 3,
            child: brandDropdown,
          ),
          const SizedBox(width: TenantAdminSpacing.md),
          Expanded(
            flex: 5,
            child: statusDropdown,
          ),
          if (canViewStock) ...[
            const SizedBox(width: TenantAdminSpacing.md),
            Expanded(
              flex: 5,
              child: stockStatusDropdown,
            ),
          ],
          const SizedBox(width: TenantAdminSpacing.md),
          resetButton,
        ],
      );
    }

    return optionsAsync.when(
      loading: () => buildFilters(null, true),
      error: (err, stack) => Row(
        children: [
          Expanded(flex: 10, child: searchField),
          const SizedBox(width: TenantAdminSpacing.md),
          const Icon(Icons.error_outline, color: Colors.red, size: 16),
          const SizedBox(width: 8),
          const Text('Error loading filters',
              style: TextStyle(color: Colors.red)),
          const SizedBox(width: 4),
          IconButton(
            icon: const Icon(Icons.refresh, size: 16),
            onPressed: () => ref.invalidate(productFilterOptionsProvider),
          ),
        ],
      ),
      data: (options) => buildFilters(options, false),
    );
  }
}

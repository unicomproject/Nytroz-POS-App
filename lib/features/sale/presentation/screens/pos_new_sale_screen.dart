import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nytroz_pos/features/cart/presentation/providers/pos_catalog_provider.dart';
import 'package:nytroz_pos/features/cart/presentation/providers/pos_new_sale_cart_provider.dart';
import 'package:nytroz_pos/features/cart/presentation/widgets/pos_empty_cart_panel.dart';

import '../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';
import '../widgets/new_sale/pos_new_sale_action_bar.dart';
import '../widgets/new_sale/pos_product_category_chips.dart';
import '../widgets/new_sale/pos_product_grid.dart';

class PosNewSaleScreen extends ConsumerStatefulWidget {
  const PosNewSaleScreen({super.key});

  @override
  ConsumerState<PosNewSaleScreen> createState() => _PosNewSaleScreenState();
}

class _PosNewSaleScreenState extends ConsumerState<PosNewSaleScreen> {
  String? _lastRoutePath;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final routePath = GoRouterState.of(context).uri.path;
    if (routePath == _lastRoutePath) {
      return;
    }

    final enteredNewSale =
        routePath == '/pos/new-sale' && _lastRoutePath != '/pos/new-sale';
    _lastRoutePath = routePath;

    if (enteredNewSale) {
      _resetSearchAfterRouteEntry();
      _refreshCatalogAfterRouteEntry();
    }
  }

  void _resetSearchAfterRouteEntry() {
    final queryAtEntry = ref.read(posNewSaleSearchQueryProvider);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || GoRouterState.of(context).uri.path != '/pos/new-sale') {
        return;
      }

      final searchNotifier = ref.read(posNewSaleSearchQueryProvider.notifier);
      if (searchNotifier.state.isNotEmpty &&
          searchNotifier.state == queryAtEntry) {
        searchNotifier.state = '';
      }
    });
  }

  void _refreshCatalogAfterRouteEntry() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || GoRouterState.of(context).uri.path != '/pos/new-sale') {
        return;
      }

      ref.invalidate(posNewSaleCatalogProvider);
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final useSideBySide = constraints.maxWidth >= 1000 ||
            (constraints.maxWidth >= TenantAdminBreakpoints.tablet &&
                constraints.maxHeight < 720);
        final isMobile = constraints.maxWidth < TenantAdminBreakpoints.tablet;
        final padding = EdgeInsets.all(
          constraints.maxWidth >= TenantAdminBreakpoints.tablet
              ? TenantAdminSpacing.lg
              : TenantAdminSpacing.md,
        );

        if (!useSideBySide) {
          final cartHeight = isMobile
              ? (constraints.maxHeight * 0.55).clamp(360.0, 520.0)
              : (constraints.maxHeight * 0.36).clamp(300.0, 420.0);

          if (!isMobile) {
            return Padding(
              padding: padding,
              child: Column(
                children: [
                  const Expanded(
                    child: _ProductArea(showActionBar: true),
                  ),
                  const SizedBox(height: TenantAdminSpacing.md),
                  SizedBox(
                    height: cartHeight,
                    child: const PosEmptyCartPanel(),
                  ),
                ],
              ),
            );
          }

          return Padding(
            padding: padding,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: isMobile ? 520 : 600,
                      maxHeight: isMobile
                          ? (constraints.maxHeight * 0.95).clamp(520.0, 760.0)
                          : (constraints.maxHeight * 0.62).clamp(600.0, 820.0),
                    ),
                    child: const _ProductArea(showActionBar: true),
                  ),
                  const SizedBox(height: TenantAdminSpacing.md),
                  SizedBox(
                    height: cartHeight,
                    child: const PosEmptyCartPanel(),
                  ),
                ],
              ),
            ),
          );
        }

        final cartWidth = constraints.maxWidth < 1180 ? 340.0 : 380.0;

        return Padding(
          padding: padding,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1440),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Expanded(
                    child: _ProductArea(showActionBar: true),
                  ),
                  const SizedBox(width: TenantAdminSpacing.md),
                  SizedBox(
                    width: cartWidth,
                    child: const PosEmptyCartPanel(),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ProductArea extends StatelessWidget {
  const _ProductArea({
    this.showActionBar = false,
  });

  final bool showActionBar;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < TenantAdminBreakpoints.tablet;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const PosProductCategoryChips(),
            const SizedBox(height: TenantAdminSpacing.sm),
            const _ProductSectionHeader(),
            const SizedBox(height: TenantAdminSpacing.sm),
            const Expanded(child: PosProductGrid()),
            if (showActionBar) ...[
              const SizedBox(height: TenantAdminSpacing.sm),
              PosNewSaleActionBar(compact: compact),
            ],
          ],
        );
      },
    );
  }
}

class _ProductSectionHeader extends ConsumerWidget {
  const _ProductSectionHeader();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final query = ref.watch(posNewSaleSearchQueryProvider).trim();
    final selectedCategory = ref.watch(posNewSaleSelectedCategoryProvider);
    final catalogAsync = ref.watch(posNewSaleCatalogProvider);
    final productCount = catalogAsync.maybeWhen(
      data: (catalog) => catalog.products.where((product) {
        final matchesCategory = posNewSaleProductMatchesCategory(
          product.categoryName,
          selectedCategory,
        );
        final matchesSearch = product.matches(query);
        return matchesCategory && matchesSearch;
      }).length,
      orElse: () => 0,
    );
    final hasSearch = query.isNotEmpty;
    final sectionTitle = hasSearch
        ? 'Search results for "$query"'
        : selectedCategory == 'All'
            ? 'All Products ($productCount)'
            : '$selectedCategory Products';

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 420;
        final title = Text(
          sectionTitle,
          maxLines: compact ? 2 : 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: TenantAdminColors.bodyText,
                    fontWeight: FontWeight.w900,
                  ) ??
              const TextStyle(
                color: TenantAdminColors.bodyText,
                fontWeight: FontWeight.w900,
              ),
        );
        final sort = Text(
          'Sort by: Popular',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: TenantAdminColors.mutedText,
                    fontWeight: FontWeight.w700,
                  ) ??
              const TextStyle(
                color: TenantAdminColors.mutedText,
                fontWeight: FontWeight.w700,
              ),
        );

        if (compact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              title,
              const SizedBox(height: TenantAdminSpacing.xs),
              sort,
            ],
          );
        }

        return Row(
          children: [
            Expanded(child: title),
            const SizedBox(width: TenantAdminSpacing.md),
            sort,
          ],
        );
      },
    );
  }
}

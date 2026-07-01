import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nytroz_pos/core/access/pos_access_codes.dart';
import 'package:nytroz_pos/core/access/pos_permission_access.dart';
import 'package:nytroz_pos/features/auth/presentation/providers/session_provider.dart';
import 'package:nytroz_pos/features/cart/domain/entities/pos_catalog_models.dart';
import 'package:nytroz_pos/features/cart/presentation/providers/pos_catalog_provider.dart';
import 'package:nytroz_pos/features/cart/presentation/providers/pos_new_sale_cart_provider.dart';
import 'package:nytroz_pos/features/cart/presentation/widgets/pos_product_image.dart';

import '../../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';
import 'pos_product_variant_sheet.dart';

class PosProductGrid extends ConsumerWidget {
  const PosProductGrid({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authSessionProvider);
    final granted = session?.permissionCodes.toSet() ?? const <String>{};
    final canViewProducts =
        session?.hasPermission(PosPermissionCodes.viewProducts) == true;
    final canAddItems = PosPermissionAccess.canAddCartItem(granted);

    if (!canViewProducts) {
      return const _ProductsAccessBlocked();
    }

    final catalogAsync = ref.watch(posNewSaleCatalogProvider);

    return catalogAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const _CatalogLoadError(),
      data: (catalog) {
        final query = ref.watch(posNewSaleSearchQueryProvider).trim();
        final selectedCategory = ref.watch(posNewSaleSelectedCategoryProvider);
        final products = catalog.products.where((product) {
          final matchesCategory = posNewSaleProductMatchesCategory(
            product.categoryName,
            selectedCategory,
          );
          final matchesSearch = product.matches(query);

          return matchesCategory && matchesSearch;
        }).toList();
        return LayoutBuilder(
          builder: (context, constraints) {
            if (products.isEmpty) {
              return const _NoProductsFound();
            }

            final crossAxisCount =
                _crossAxisCountForWidth(constraints.maxWidth);
            final tileWidth = (constraints.maxWidth -
                    (TenantAdminSpacing.sm * (crossAxisCount - 1))) /
                crossAxisCount;
            final mainAxisExtent = (tileWidth + 64).clamp(168.0, 218.0);

            return GridView.count(
              clipBehavior: Clip.hardEdge,
              padding: const EdgeInsets.only(bottom: TenantAdminSpacing.sm),
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: TenantAdminSpacing.sm,
              mainAxisSpacing: TenantAdminSpacing.sm,
              childAspectRatio: tileWidth / mainAxisExtent,
              children: [
                for (final product in products)
                  _ProductTile(
                    product: product,
                    onTap: canAddItems
                        ? () => _handleProductTap(context, ref, product, query)
                        : null,
                  ),
              ],
            );
          },
        );
      },
    );
  }

  int _crossAxisCountForWidth(double width) {
    if (width < 340) {
      return 1;
    }
    if (width < 520) {
      return 2;
    }
    if (width < 760) {
      return 3;
    }
    if (width < 1120) {
      return 4;
    }

    return 5;
  }

  Future<void> _handleProductTap(
    BuildContext context,
    WidgetRef ref,
    PosCatalogProductSummary product,
    String query,
  ) async {
    if (product.hasVariants) {
      await showPosProductVariantSheet(
        context: context,
        ref: ref,
        summary: product,
        initialSearchQuery: query,
      );
      return;
    }

    ref.read(posNewSaleCartProvider.notifier).addToCart(
          toCartProduct(
            summary: product,
            variant: null,
            quantity: 1,
          ),
        );
  }
}

class _ProductTile extends StatelessWidget {
  const _ProductTile({
    required this.product,
    required this.onTap,
  });

  final PosCatalogProductSummary product;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: TenantAdminColors.surface,
      borderRadius: BorderRadius.circular(TenantAdminRadius.md),
      child: InkWell(
        borderRadius: BorderRadius.circular(TenantAdminRadius.md),
        onTap: onTap,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(TenantAdminRadius.md),
            border: Border.all(color: TenantAdminColors.border),
            boxShadow: TenantAdminShadows.card,
          ),
          child: Padding(
            padding: const EdgeInsets.all(TenantAdminSpacing.sm),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                PosProductImage(
                  imageUrl: product.imageUrl,
                  category: product.categoryName,
                  expand: true,
                ),
                const SizedBox(height: TenantAdminSpacing.sm),
                Text(
                  product.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: TenantAdminColors.bodyText,
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: TenantAdminSpacing.xs),
                Text(
                  formatLkr(product.basePrice),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: TenantAdminColors.bodyText,
                        fontWeight: FontWeight.w900,
                      ),
                ),
                const SizedBox(height: TenantAdminSpacing.xs),
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: TenantAdminColors.success,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: TenantAdminSpacing.xs),
                    Expanded(
                      child: Text(
                        product.hasVariants
                            ? 'Select options'
                            : product.stockLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: TenantAdminColors.mutedText,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CatalogLoadError extends StatelessWidget {
  const _CatalogLoadError();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.cloud_off_outlined,
            size: 40,
            color: TenantAdminColors.mutedText,
          ),
          const SizedBox(height: TenantAdminSpacing.sm),
          Text(
            'Unable to load products',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: TenantAdminColors.bodyText,
                  fontWeight: FontWeight.w800,
                ),
          ),
        ],
      ),
    );
  }
}

class _ProductsAccessBlocked extends StatelessWidget {
  const _ProductsAccessBlocked();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.lock_outline_rounded,
            size: 40,
            color: TenantAdminColors.mutedText,
          ),
          const SizedBox(height: TenantAdminSpacing.sm),
          Text(
            'Products unavailable',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: TenantAdminColors.bodyText,
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: TenantAdminSpacing.xs),
          Text(
            'You do not have permission to view products.',
            textAlign: TextAlign.center,
            style: TenantAdminTextStyles.muted(context),
          ),
        ],
      ),
    );
  }
}

class _NoProductsFound extends StatelessWidget {
  const _NoProductsFound();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.search_off_rounded,
            size: 40,
            color: TenantAdminColors.mutedText,
          ),
          const SizedBox(height: TenantAdminSpacing.sm),
          Text(
            'No products found',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: TenantAdminColors.bodyText,
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: TenantAdminSpacing.xs),
          Text(
            'Try a product name or exact SKU/barcode.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: TenantAdminColors.mutedText,
                ),
          ),
        ],
      ),
    );
  }
}

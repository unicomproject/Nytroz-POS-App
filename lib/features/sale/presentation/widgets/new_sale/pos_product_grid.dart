import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nytroz_pos/core/access/pos_access_codes.dart';
import 'package:nytroz_pos/core/access/pos_permission_access.dart';
import 'package:nytroz_pos/features/auth/presentation/providers/session_provider.dart';
import 'package:nytroz_pos/features/cart/domain/entities/pos_catalog_models.dart';
import 'package:nytroz_pos/features/cart/presentation/providers/pos_catalog_provider.dart';
import 'package:nytroz_pos/features/cart/presentation/providers/pos_new_sale_cart_provider.dart';

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
        final query =
            ref.watch(posNewSaleSearchQueryProvider).trim().toLowerCase();
        final selectedCategory = ref.watch(posNewSaleSelectedCategoryProvider);
        final products = catalog.products.where((product) {
          final matchesCategory = posNewSaleProductMatchesCategory(
            product.categoryName,
            selectedCategory,
          );
          final matchesSearch = query.isEmpty || product.matches(query);

          return matchesCategory && matchesSearch;
        }).toList();

        return LayoutBuilder(
          builder: (context, constraints) {
            final crossAxisCount = constraints.maxWidth < 500
                ? 2
                : constraints.maxWidth < 700
                    ? 3
                    : 4;

            if (products.isEmpty) {
              return const _NoProductsFound();
            }

            return GridView.builder(
              clipBehavior: Clip.hardEdge,
              padding: const EdgeInsets.only(bottom: TenantAdminSpacing.sm),
              itemCount: products.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: TenantAdminSpacing.sm,
                mainAxisSpacing: TenantAdminSpacing.sm,
                mainAxisExtent: 152,
              ),
              itemBuilder: (context, index) {
                final product = products[index];

                return _ProductTile(
                  product: product,
                  onTap: canAddItems
                      ? () => _handleProductTap(context, ref, product)
                      : null,
                );
              },
            );
          },
        );
      },
    );
  }

  Future<void> _handleProductTap(
    BuildContext context,
    WidgetRef ref,
    PosCatalogProductSummary product,
  ) async {
    if (product.hasVariants) {
      await showPosProductVariantSheet(
        context: context,
        ref: ref,
        summary: product,
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
    final visual = _ProductVisual.forCategory(product.categoryName);

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
                _ProductImageFallback(visual: visual),
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
                        color: TenantAdminColors.success,
                        fontWeight: FontWeight.w800,
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
            'Try a product name, category or SKU.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: TenantAdminColors.mutedText,
                ),
          ),
        ],
      ),
    );
  }
}

class _ProductImageFallback extends StatelessWidget {
  const _ProductImageFallback({required this.visual});

  final _ProductVisual visual;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: visual.backgroundColor,
          borderRadius: BorderRadius.circular(TenantAdminRadius.sm),
        ),
        child: Center(
          child: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.82),
              shape: BoxShape.circle,
            ),
            child: Icon(
              visual.icon,
              color: visual.iconColor,
              size: 22,
            ),
          ),
        ),
      ),
    );
  }
}

class _ProductVisual {
  const _ProductVisual({
    required this.icon,
    required this.backgroundColor,
    required this.iconColor,
  });

  final IconData icon;
  final Color backgroundColor;
  final Color iconColor;

  static _ProductVisual forCategory(String category) {
    return switch (category.toLowerCase()) {
      'tickets' || 'ticket' => const _ProductVisual(
          icon: Icons.confirmation_number_outlined,
          backgroundColor: Color(0xFFEFF6FF),
          iconColor: TenantAdminColors.info,
        ),
      'services' || 'service' => const _ProductVisual(
          icon: Icons.room_service_outlined,
          backgroundColor: Color(0xFFF0FDF4),
          iconColor: TenantAdminColors.success,
        ),
      'retail' => const _ProductVisual(
          icon: Icons.shopping_bag_outlined,
          backgroundColor: Color(0xFFFFF7ED),
          iconColor: TenantAdminColors.warning,
        ),
      'food' => const _ProductVisual(
          icon: Icons.restaurant_outlined,
          backgroundColor: Color(0xFFFEF2F2),
          iconColor: TenantAdminColors.danger,
        ),
      'drinks' || 'drink' => const _ProductVisual(
          icon: Icons.local_cafe_outlined,
          backgroundColor: Color(0xFFFFF7ED),
          iconColor: TenantAdminColors.warning,
        ),
      'memberships' || 'membership' => const _ProductVisual(
          icon: Icons.workspace_premium_outlined,
          backgroundColor: Color(0xFFF5F3FF),
          iconColor: TenantAdminColors.pending,
        ),
      'apparel' => const _ProductVisual(
          icon: Icons.checkroom_outlined,
          backgroundColor: Color(0xFFEFF6FF),
          iconColor: TenantAdminColors.info,
        ),
      'accessories' => const _ProductVisual(
          icon: Icons.watch_outlined,
          backgroundColor: Color(0xFFF0FDF4),
          iconColor: TenantAdminColors.success,
        ),
      _ => const _ProductVisual(
          icon: Icons.inventory_2_outlined,
          backgroundColor: TenantAdminColors.background,
          iconColor: TenantAdminColors.mutedText,
        ),
    };
  }
}

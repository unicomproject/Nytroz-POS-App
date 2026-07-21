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
      error: (error, _) => _CatalogLoadError(message: error.toString()),
      data: (catalog) {
        final products = catalog.products;

        return LayoutBuilder(
          builder: (context, constraints) {
            final crossAxisCount = constraints.maxWidth < 600 ? 2 : 3;

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
                mainAxisExtent: 280,
              ),
              itemBuilder: (context, index) {
                final product = products[index];

                return _ProductTile(
                  product: product,
                  onTap: canAddItems && !product.isOutOfStock
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
                _ProductImage(product: product, visual: visual),
                const SizedBox(height: TenantAdminSpacing.sm),
                Text(
                  product.name,
                  maxLines: 2,
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
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: TenantAdminSpacing.xs),
                Row(
                  children: [
                    Expanded(
                      child: _ProductStatus(
                        label: product.hasVariants && !product.isOutOfStock
                            ? 'Select options'
                            : product.stockLabel,
                        isOutOfStock: product.isOutOfStock,
                      ),
                    ),
                    const SizedBox(width: TenantAdminSpacing.xs),
                    _ProductQuickAddButton(onTap: onTap),
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

class _ProductStatus extends StatelessWidget {
  const _ProductStatus({
    required this.label,
    required this.isOutOfStock,
  });

  final String label;
  final bool isOutOfStock;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: isOutOfStock
                ? TenantAdminColors.danger
                : TenantAdminColors.success,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: TenantAdminSpacing.xs),
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: TenantAdminColors.mutedText,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ),
      ],
    );
  }
}

class _ProductQuickAddButton extends StatelessWidget {
  const _ProductQuickAddButton({required this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isEnabled = onTap != null;

    return Semantics(
      button: true,
      enabled: isEnabled,
      label: 'Add product to cart',
      child: SizedBox.square(
        dimension: 44,
        child: Material(
          color: Colors.transparent,
          shape: const CircleBorder(),
          child: InkWell(
            onTap: onTap,
            customBorder: const CircleBorder(),
            child: Center(
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isEnabled
                      ? TenantAdminColors.surface
                      : TenantAdminColors.background,
                  border: Border.all(color: TenantAdminColors.border),
                ),
                child: Icon(
                  Icons.add,
                  size: 20,
                  color: isEnabled
                      ? TenantAdminColors.primary
                      : TenantAdminColors.mutedText.withValues(alpha: 0.45),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CatalogLoadError extends StatelessWidget {
  const _CatalogLoadError({this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    final details = message?.trim();
    final showDetails = details != null &&
        details.isNotEmpty &&
        !details.contains('FutureProvider');

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
          if (showDetails) ...[
            const SizedBox(height: TenantAdminSpacing.xs),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: TenantAdminSpacing.md,
              ),
              child: Text(
                details,
                textAlign: TextAlign.center,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: TenantAdminColors.mutedText,
                    ),
              ),
            ),
          ],
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
            'Try a product name, SKU or barcode.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: TenantAdminColors.mutedText,
                ),
          ),
        ],
      ),
    );
  }
}

class _ProductImage extends StatelessWidget {
  const _ProductImage({required this.product, required this.visual});

  final PosCatalogProductSummary product;
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
        clipBehavior: Clip.hardEdge,
        child: product.imageUrl != null && product.imageUrl!.isNotEmpty
            ? Image.network(
                product.imageUrl!,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
                errorBuilder: (_, __, ___) =>
                    _ProductImageFallback(visual: visual),
              )
            : _ProductImageFallback(visual: visual),
      ),
    );
  }
}

class _ProductImageFallback extends StatelessWidget {
  const _ProductImageFallback({required this.visual});

  static const _dummyImageAsset = 'assets/images/product_dummy.png';

  final _ProductVisual visual;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      _dummyImageAsset,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      errorBuilder: (_, __, ___) {
        return Container(
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
        );
      },
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
      'footwear' => const _ProductVisual(
          icon: Icons.hiking_outlined,
          backgroundColor: Color(0xFFF5F3FF),
          iconColor: TenantAdminColors.pending,
        ),
      'sports' => const _ProductVisual(
          icon: Icons.sports_soccer_outlined,
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

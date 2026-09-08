import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nytroz_pos/core/access/pos_access_codes.dart';
import 'package:nytroz_pos/core/access/pos_permission_access.dart';
import 'package:nytroz_pos/features/auth/presentation/providers/session_provider.dart';
import 'package:nytroz_pos/features/pos/domain/entities/pos_catalog_models.dart';
import 'package:nytroz_pos/features/cart/domain/entities/pos_resolved_sale_item.dart';
import 'package:nytroz_pos/features/pos/presentation/providers/pos_catalog_provider.dart';
import 'package:nytroz_pos/features/cart/presentation/providers/pos_resolved_variant_cart_action.dart';

import '../../../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';
import '../../../../../sale/presentation/widgets/new_sale/pos_product_variant_sheet.dart';
import 'pos_product_card.dart';

class PosProductGrid extends ConsumerWidget {
  const PosProductGrid({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authSessionProvider);
    final granted = session?.permissionCodes.toSet() ?? const <String>{};
    final canViewProducts = PosPermissionAccess.canViewProducts(granted);
    final canAddItems = PosPermissionAccess.canAddCartItem(granted);
    final canOpenDetails = granted.contains(
          PosPermissionCodes.catalogProductCardOpenDetails,
        ) ||
        granted.contains(PosPermissionCodes.catalogProductDetailView);

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
            final crossAxisCount = constraints.maxWidth < 420
                ? 2
                : constraints.maxWidth < 540
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
                crossAxisSpacing: TenantAdminSpacing.md,
                mainAxisSpacing: TenantAdminSpacing.md,
                mainAxisExtent: constraints.maxWidth < 540 ? 238 : 248,
              ),
              itemBuilder: (context, index) {
                final product = products[index];

                final canTapProduct = !product.isOutOfStock &&
                    ((product.hasVariants &&
                            product.variantId == null &&
                            canOpenDetails) ||
                        (product.variantId != null && canAddItems) ||
                        (!product.hasVariants && canAddItems));

                return PosProductCard(
                  product: product,
                  onTap: canTapProduct
                      ? () => _handleProductTap(
                            context,
                            ref,
                            product,
                            canOpenDetails: canOpenDetails,
                            canAddItems: canAddItems,
                          )
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
    PosCatalogProductSummary product, {
    required bool canOpenDetails,
    required bool canAddItems,
  }) async {
    if (product.variantId case final matchedVariantId?) {
      if (!canAddItems) return;
      final detail = await ref.read(
        posProductDetailProvider(product.productId).future,
      );
      final matchedVariant = detail.variants
          .where((variant) => variant.variantId == matchedVariantId)
          .firstOrNull;

      if (matchedVariant == null || matchedVariant.isOutOfStock) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('The matched product option is unavailable.'),
            ),
          );
        }
        return;
      }

      ref.read(posResolvedVariantCartActionProvider).add(
            PosResolvedSaleItem.fromCatalog(
              summary: product,
              variant: matchedVariant,
            ),
            requestedQuantity: 1,
          );
      return;
    }

    if (product.hasVariants) {
      if (!canOpenDetails) return;
      await showPosProductVariantSheet(
        context: context,
        ref: ref,
        summary: product,
      );
      return;
    }

    if (!canAddItems) return;
    ref.read(posResolvedVariantCartActionProvider).add(
          PosResolvedSaleItem.fromCatalog(summary: product),
          requestedQuantity: 1,
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

class _NoProductsFound extends ConsumerWidget {
  const _NoProductsFound();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final segment = ref.watch(posNewSaleSelectedSegmentProvider);
    final isFrequentlySold = segment == 'frequently-sold';
    final isOffers = segment == 'offers';

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
            isFrequentlySold
                ? 'No frequently sold products yet'
                : isOffers
                    ? 'No active offers'
                    : 'No products found',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: TenantAdminColors.bodyText,
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: TenantAdminSpacing.xs),
          Text(
            isFrequentlySold
                ? 'Products will appear here once sales are recorded.'
                : isOffers
                    ? 'Check back later or try selecting a different category.'
                    : 'Try a product name, SKU or barcode.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: TenantAdminColors.mutedText,
                ),
          ),
        ],
      ),
    );
  }
}

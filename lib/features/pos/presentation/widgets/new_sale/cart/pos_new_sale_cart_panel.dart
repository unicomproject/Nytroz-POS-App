import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nytroz_pos/core/access/pos_permission_access.dart';
import 'package:nytroz_pos/features/auth/presentation/providers/session_provider.dart';
import 'package:nytroz_pos/features/pos/domain/entities/pos_catalog_models.dart';
import 'package:nytroz_pos/features/cart/presentation/providers/pos_new_sale_cart_provider.dart';
import 'package:nytroz_pos/features/sale/presentation/widgets/new_sale/pos_product_variant_sheet.dart';
import 'package:nytroz_pos/features/sale/presentation/providers/pos_checkout_summary_provider.dart';

import '../../../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';
import 'pos_cart_header.dart';
import 'pos_cart_row.dart';
import 'pos_empty_cart_message.dart';
import '../summary/pos_cart_summary.dart';
import '../summary/pos_payment_bar.dart';

class PosNewSaleCartPanel extends ConsumerWidget {
  const PosNewSaleCartPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(posNewSaleCartProvider);
    final pricingAsync = cart.hasItems
        ? ref.watch(posCheckoutSummaryProvider)
        : const AsyncValue<PosCheckoutSummaryViewData>.loading();

    return ClipRRect(
      borderRadius: BorderRadius.circular(TenantAdminRadius.lg),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: TenantAdminColors.surface,
          border: Border.all(color: TenantAdminColors.border, width: 1.5),
          boxShadow: TenantAdminShadows.card,
        ),
        child: Padding(
          padding: const EdgeInsets.all(TenantAdminSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const PosCartHeader(),
              const Divider(height: TenantAdminSpacing.xl),
              if (cart.hasItems) ...[
                const _CartColumnHeader(),
                const Divider(height: TenantAdminSpacing.md),
              ],
              Expanded(
                child: ClipRect(
                  child: cart.hasItems
                      ? _CartItemList(
                          items: cart.itemList,
                          pricingAsync: pricingAsync,
                          cart: cart,
                        )
                      : const PosEmptyCartMessage(),
                ),
              ),
              if (cart.hasItems) ...[
                const SizedBox(height: TenantAdminSpacing.md),
                PosCartSummary(cart: cart, pricingAsync: pricingAsync),
                const SizedBox(height: TenantAdminSpacing.md),
              ],
              PosPaymentBar(cart: cart, pricingAsync: pricingAsync),
            ],
          ),
        ),
      ),
    );
  }
}

class _CartItemList extends ConsumerWidget {
  const _CartItemList({
    required this.items,
    required this.pricingAsync,
    required this.cart,
  });

  final List<PosNewSaleCartItem> items;
  final AsyncValue<PosCheckoutSummaryViewData> pricingAsync;
  final PosNewSaleCartState cart;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reversedItems = items.reversed.toList(growable: false);
    final pricing = pricingAsync.valueOrNull;
    if (pricing == null) {
      return ListView.separated(
        clipBehavior: Clip.hardEdge,
        padding: const EdgeInsets.only(bottom: TenantAdminSpacing.sm),
        itemCount: reversedItems.length,
        separatorBuilder: (_, __) => const Divider(
          height: TenantAdminSpacing.md,
        ),
        itemBuilder: (context, index) {
          final item = reversedItems[index];
          return PosCartRow(
            item: item,
            onTap: () => _handleCartItemTap(context, ref, item),
          );
        },
      );
    }

    final isAuthoritative =
        isCurrentAuthoritativePricing(cart: cart, pricing: pricing);
    final currency = pricing.currency;

    return ListView.separated(
      clipBehavior: Clip.hardEdge,
      padding: const EdgeInsets.only(bottom: TenantAdminSpacing.sm),
      itemCount: reversedItems.length,
      separatorBuilder: (_, __) => const Divider(
        height: TenantAdminSpacing.md,
      ),
      itemBuilder: (context, index) {
        final item = reversedItems[index];
        final linePricing = isAuthoritative
            ? authoritativeLinePricingFor(item: item, pricing: pricing)
            : null;

        return PosCartRow(
          item: item,
          linePricing: linePricing,
          isAuthoritative: isAuthoritative && linePricing != null,
          currency: currency,
          onTap: () => _handleCartItemTap(context, ref, item),
        );
      },
    );
  }

  void _handleCartItemTap(
    BuildContext context,
    WidgetRef ref,
    PosNewSaleCartItem item,
  ) {
    final session = ref.read(authSessionProvider);
    if (!PosPermissionAccess.canUpdateCartItemSession(session)) {
      PosPermissionAccess.showAccessDeniedSnackBar(
        context,
        'You do not have permission to update cart items.',
      );
      return;
    }

    _openEditSheet(context, ref, item);
  }

  Future<void> _openEditSheet(
    BuildContext context,
    WidgetRef ref,
    PosNewSaleCartItem item,
  ) {
    return showPosProductVariantSheet(
      context: context,
      ref: ref,
      summary: PosCatalogProductSummary(
        productId: item.product.productId,
        variantId: item.product.variantId,
        name: item.product.name,
        categoryName: item.product.category,
        basePrice: item.product.price,
        hasVariants: item.product.hasVariants,
        imageUrl: item.product.imageUrl,
      ),
      existingCartItem: item,
    );
  }
}

class _CartColumnHeader extends StatelessWidget {
  const _CartColumnHeader();

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.labelSmall?.copyWith(
          color: TenantAdminColors.posHomeAccentOrange,
          fontWeight: FontWeight.w800,
        );
    return Row(
      children: [
        Expanded(
          flex: 5,
          child: Padding(
            padding: const EdgeInsets.only(left: 68),
            child: Text('Item', style: style),
          ),
        ),
        Expanded(
          flex: 4,
          child: Text('Qty', textAlign: TextAlign.center, style: style),
        ),
        Expanded(
          flex: 4,
          child: Text('Price', textAlign: TextAlign.right, style: style),
        ),
        Expanded(
          flex: 4,
          child: Text('Total', textAlign: TextAlign.right, style: style),
        ),
        const SizedBox(width: 36),
      ],
    );
  }
}

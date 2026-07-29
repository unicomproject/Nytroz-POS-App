import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nytroz_pos/core/access/pos_access_codes.dart';
import 'package:nytroz_pos/core/access/pos_permission_access.dart';
import 'package:nytroz_pos/features/auth/presentation/providers/session_provider.dart';
import 'package:nytroz_pos/features/cart/domain/entities/pos_catalog_models.dart';
import 'package:nytroz_pos/features/cart/presentation/providers/pos_new_sale_cart_provider.dart';
import 'package:nytroz_pos/features/device_activation/presentation/providers/device_activation_provider.dart';
import 'package:nytroz_pos/features/sale/domain/entities/pos_payment_method_type.dart';
import 'package:nytroz_pos/features/sale/presentation/widgets/new_sale/pos_discount_dialog.dart';
import 'package:nytroz_pos/features/sale/presentation/widgets/new_sale/pos_product_variant_sheet.dart';
import 'package:nytroz_pos/features/till/presentation/providers/till_provider.dart';

import '../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';

class PosEmptyCartPanel extends ConsumerWidget {
  const PosEmptyCartPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(posNewSaleCartProvider);

    // Cart/totals visibility is inherited from New Sale screen access because no
    // dedicated cart view permission exists.
    return ClipRRect(
      borderRadius: BorderRadius.circular(TenantAdminRadius.lg),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: TenantAdminColors.surface,
          border: Border.all(color: TenantAdminColors.border),
          boxShadow: TenantAdminShadows.card,
        ),
        child: Padding(
          padding: const EdgeInsets.all(TenantAdminSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _CartHeader(),
              const Divider(height: TenantAdminSpacing.xl),
              if (cart.hasItems) ...[
                const _CartColumnHeader(),
                const Divider(height: TenantAdminSpacing.md),
              ],
              Expanded(
                child: ClipRect(
                  child: cart.hasItems
                      ? _CartItemList(items: cart.itemList)
                      : const _EmptyCartMessage(),
                ),
              ),
              _CartSummaryFooter(cart: cart),
            ],
          ),
        ),
      ),
    );
  }
}

class _CartHeader extends ConsumerWidget {
  const _CartHeader();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(posNewSaleCartProvider);
    final selectedCustomer = cart.selectedCustomer;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Icon(
              Icons.shopping_cart_outlined,
              color: TenantAdminColors.posHomeAccentOrange,
            ),
            const SizedBox(width: TenantAdminSpacing.sm),
            Text(
              'Current Sale',
              style: TenantAdminTextStyles.sectionTitle(context),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: TenantAdminSpacing.sm,
                vertical: TenantAdminSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: TenantAdminColors.surface,
                borderRadius: BorderRadius.circular(TenantAdminRadius.sm),
                border: Border.all(color: TenantAdminColors.border),
              ),
              child: Text(
                '${cart.itemList.length} Lines • '
                '${cart.itemList.fold<int>(0, (total, item) => total + item.quantity)} Items',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: TenantAdminColors.info,
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ),
          ],
        ),
        if (selectedCustomer != null) ...[
          const SizedBox(height: TenantAdminSpacing.xs),
          Wrap(
            spacing: TenantAdminSpacing.xs,
            runSpacing: TenantAdminSpacing.xs,
            children: [
              Chip(
                label: Text(selectedCustomer.displayName),
                avatar: const Icon(Icons.person_outline_rounded, size: 18),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _EmptyCartMessage extends StatelessWidget {
  const _EmptyCartMessage();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxHeight < 150;

        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.add_shopping_cart_rounded,
                size: compact ? 36 : 56,
                color: TenantAdminColors.offline,
              ),
              SizedBox(
                height: compact ? TenantAdminSpacing.sm : TenantAdminSpacing.md,
              ),
              Text(
                'No items added',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: TenantAdminColors.bodyText,
                      fontWeight: FontWeight.w800,
                    ),
              ),
              if (!compact) ...[
                const SizedBox(height: TenantAdminSpacing.xs),
                Text(
                  'Select a product to prepare the sale.',
                  textAlign: TextAlign.center,
                  style: TenantAdminTextStyles.muted(context),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _CartItemList extends ConsumerWidget {
  const _CartItemList({required this.items});

  final List<PosNewSaleCartItem> items;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reversedItems = items.reversed.toList(growable: false);

    return ListView.separated(
      clipBehavior: Clip.hardEdge,
      padding: const EdgeInsets.only(bottom: TenantAdminSpacing.sm),
      itemCount: reversedItems.length,
      separatorBuilder: (_, __) => const Divider(
        height: TenantAdminSpacing.xl,
      ),
      itemBuilder: (context, index) {
        final item = reversedItems[index];

        return _CartItemRow(
          item: item,
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

class _CartItemRow extends ConsumerWidget {
  const _CartItemRow({
    required this.item,
    required this.onTap,
  });

  final PosNewSaleCartItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(posNewSaleCartProvider.notifier);
    final session = ref.watch(authSessionProvider);
    final granted = session?.permissionCodes.toSet() ?? const <String>{};
    final canUpdateItems = PosPermissionAccess.canUpdateCartItem(granted);
    final canRemoveItems = PosPermissionAccess.canRemoveCartItem(granted);

    return InkWell(
      onTap: onTap,
      child: SizedBox(
        height: 64,
        child: Row(
          children: [
            _CartProductThumbnail(product: item.product),
            const SizedBox(width: TenantAdminSpacing.sm),
            Expanded(
              flex: 5,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.product.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: TenantAdminColors.bodyText,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  if (item.product.variantSummary.isNotEmpty)
                    Text(
                      item.product.variantSummary,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: TenantAdminColors.mutedText,
                          ),
                    ),
                ],
              ),
            ),
            Expanded(
              flex: 4,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _QuantityButton(
                    icon: Icons.remove_rounded,
                    onPressed: canUpdateItems
                        ? () =>
                            notifier.decreaseQuantity(item.product.cartLineKey)
                        : null,
                  ),
                  SizedBox(
                    width: 36,
                    child: Text(
                      'Qty ${item.quantity}',
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  _QuantityButton(
                    icon: Icons.add_rounded,
                    onPressed: canUpdateItems
                        ? () =>
                            notifier.increaseQuantity(item.product.cartLineKey)
                        : null,
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 4,
              child: Text(
                formatLkr(item.product.price),
                textAlign: TextAlign.right,
                maxLines: 1,
                style: const TextStyle(
                  color: TenantAdminColors.info,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Expanded(
              flex: 4,
              child: Text(
                formatLkr(item.lineTotal),
                textAlign: TextAlign.right,
                maxLines: 1,
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
            SizedBox(
              width: 36,
              child: canRemoveItems
                  ? IconButton(
                      visualDensity: VisualDensity.compact,
                      onPressed: () =>
                          notifier.removeItem(item.product.cartLineKey),
                      icon: const Icon(Icons.close_rounded, size: 20),
                      color: TenantAdminColors.posHomeAccentOrange,
                      tooltip: 'Remove item',
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _CartProductThumbnail extends StatelessWidget {
  const _CartProductThumbnail({required this.product});

  final PosNewSaleProduct product;

  @override
  Widget build(BuildContext context) {
    final imageUrl = product.imageUrl?.trim();
    return ClipRRect(
      borderRadius: BorderRadius.circular(TenantAdminRadius.sm),
      child: SizedBox.square(
        dimension: 42,
        child: ColoredBox(
          color: TenantAdminColors.background,
          child: imageUrl != null && imageUrl.isNotEmpty
              ? Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const _CartImageFallback(),
                )
              : const _CartImageFallback(),
        ),
      ),
    );
  }
}

class _CartImageFallback extends StatelessWidget {
  const _CartImageFallback();

  @override
  Widget build(BuildContext context) => const Icon(
        Icons.inventory_2_outlined,
        color: TenantAdminColors.posHomeAccentOrange,
        size: 22,
      );
}

class _CartColumnHeader extends StatelessWidget {
  const _CartColumnHeader();

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.labelSmall?.copyWith(
          color: TenantAdminColors.primary,
          fontWeight: FontWeight.w800,
        );
    return Row(
      children: [
        Expanded(
          flex: 5,
          child: Padding(
            padding: const EdgeInsets.only(left: 50),
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

class _QuantityButton extends StatelessWidget {
  const _QuantityButton({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: 24,
      child: IconButton.outlined(
        padding: EdgeInsets.zero,
        onPressed: onPressed,
        icon: Icon(icon, size: 16),
      ),
    );
  }
}

class _CartSummaryFooter extends ConsumerWidget {
  const _CartSummaryFooter({required this.cart});

  final PosNewSaleCartState cart;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authSessionProvider);
    final deviceState = ref.watch(deviceActivationProvider);
    final tillState = ref.watch(tillProvider);
    final canCheckout = PosPermissionAccess.canCheckoutSession(session);
    final hasPaymentMethod =
        allowedPosPaymentMethods(session?.permissionCodes.toSet() ?? const {})
            .isNotEmpty;
    final deviceContext = deviceState.deviceContext;
    final hasTrustedDevice = deviceContext != null &&
        deviceContext.isTrusted &&
        deviceContext.deviceId.trim().isNotEmpty &&
        deviceContext.outletId.trim().isNotEmpty &&
        deviceContext.tillId.trim().isNotEmpty;
    final hasOpenTillSession = tillState.hasOpenSession;
    final canProceed = cart.hasItems &&
        canCheckout &&
        hasPaymentMethod &&
        hasTrustedDevice &&
        hasOpenTillSession;

    return DecoratedBox(
      decoration: const BoxDecoration(
        color: TenantAdminColors.surface,
        border: Border(
          top: BorderSide(color: TenantAdminColors.border),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.only(top: TenantAdminSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            _CartTotalLine(
              label: 'Subtotal',
              value: formatLkr(cart.subtotal),
            ),
            const SizedBox(height: TenantAdminSpacing.sm),
            _CartTotalLine(
              labelWidget: _DiscountSummaryLabel(cart: cart),
              value: cart.hasDiscount
                  ? '- ${formatLkr(cart.discount)}'
                  : formatLkr(cart.discount),
            ),
            const SizedBox(height: TenantAdminSpacing.sm),
            _CartTotalLine(label: 'Tax', value: formatLkr(cart.tax)),
            const SizedBox(height: TenantAdminSpacing.md),
            Container(
              constraints: const BoxConstraints(minHeight: 62),
              padding: const EdgeInsets.symmetric(
                horizontal: TenantAdminSpacing.md,
                vertical: TenantAdminSpacing.sm,
              ),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    TenantAdminColors.posNewSaleAccent,
                    TenantAdminColors.posNewSaleAccentEnd,
                  ],
                ),
                borderRadius: BorderRadius.circular(TenantAdminRadius.md),
              ),
              child: Row(
                children: [
                  Text(
                    'Total',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(width: TenantAdminSpacing.md),
                  Container(
                    width: 1,
                    height: 30,
                    color: Colors.white.withValues(alpha: 0.5),
                  ),
                  const SizedBox(width: TenantAdminSpacing.md),
                  Expanded(
                    child: Text(
                      formatLkr(cart.total),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                  ),
                  const SizedBox(width: TenantAdminSpacing.sm),
                  FilledButton.icon(
                    onPressed: canProceed
                        ? () => context.push('/pos/new-sale/payment')
                        : null,
                    icon: const Icon(Icons.arrow_forward_rounded),
                    label: const Text('Proceed to Payment'),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(132, 44),
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      backgroundColor: Colors.white,
                      foregroundColor: TenantAdminColors.posNewSaleAccentEnd,
                      disabledBackgroundColor:
                          Colors.white.withValues(alpha: 0.68),
                      disabledForegroundColor: TenantAdminColors.mutedText,
                      textStyle: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(TenantAdminRadius.sm),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DiscountSummaryLabel extends ConsumerWidget {
  const _DiscountSummaryLabel({required this.cart});

  final PosNewSaleCartState cart;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authSessionProvider);
    final canApplyDiscount =
        session?.hasPermission(PosPermissionCodes.applySaleDiscount) == true;
    final isApplied = cart.hasDiscount;
    final isPending = cart.pendingDiscount != null;
    final actionLabel = isApplied
        ? 'Discount Applied'
        : isPending
            ? 'Approval Pending'
            : 'Add Discount';

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Discount',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: TenantAdminColors.mutedText,
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(width: TenantAdminSpacing.sm),
        InkWell(
          onTap: canApplyDiscount && cart.hasItems
              ? () => showPosDiscountDialog(context: context, ref: ref)
              : null,
          borderRadius: BorderRadius.circular(TenantAdminRadius.sm),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: TenantAdminSpacing.xs,
              vertical: 2,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isApplied ? Icons.check_circle_rounded : Icons.sell_outlined,
                  size: 16,
                  color: isApplied
                      ? TenantAdminColors.success
                      : TenantAdminColors.posHomeAccentOrange,
                ),
                const SizedBox(width: TenantAdminSpacing.xs),
                Text(
                  actionLabel,
                  style: TextStyle(
                    color: isApplied
                        ? TenantAdminColors.success
                        : TenantAdminColors.posHomeAccentOrange,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _CartTotalLine extends StatelessWidget {
  const _CartTotalLine({
    this.label,
    this.labelWidget,
    required this.value,
  }) : assert(label != null || labelWidget != null);

  final String? label;
  final Widget? labelWidget;
  final String value;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: TenantAdminColors.mutedText,
          fontWeight: FontWeight.w700,
        );

    return Row(
      children: [
        Expanded(child: labelWidget ?? Text(label!, style: style)),
        Text(value, style: style),
      ],
    );
  }
}

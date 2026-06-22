import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nytroz_pos/core/access/pos_access_codes.dart';
import 'package:nytroz_pos/features/auth/domain/entities/auth_session.dart';
import 'package:nytroz_pos/features/auth/presentation/providers/session_provider.dart';
import 'package:nytroz_pos/features/cart/domain/entities/pos_catalog_models.dart';
import 'package:nytroz_pos/features/cart/presentation/providers/pos_new_sale_cart_provider.dart';
import 'package:nytroz_pos/features/sale/presentation/widgets/new_sale/pos_product_variant_sheet.dart';

import '../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';

class PosEmptyCartPanel extends ConsumerWidget {
  const PosEmptyCartPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(posNewSaleCartProvider);

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
    final session = ref.watch(authSessionProvider);
    final canClearCart =
        session?.hasPermission(PosPermissionCodes.clearCart) == true;
    final cartHasItems = ref.watch(posNewSaleCartProvider).hasItems;

    return Row(
      children: [
        const Icon(
          Icons.shopping_cart_outlined,
          color: TenantAdminColors.info,
        ),
        const SizedBox(width: TenantAdminSpacing.sm),
        Text(
          'Cart',
          style: TenantAdminTextStyles.sectionTitle(context),
        ),
        const Spacer(),
        if (canClearCart && cartHasItems)
          IconButton(
            visualDensity: VisualDensity.compact,
            onPressed: () => ref.read(posNewSaleCartProvider.notifier).clear(),
            tooltip: 'Clear cart',
            icon: const Icon(Icons.delete_sweep_outlined),
            color: TenantAdminColors.danger,
          ),
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
    return ListView.separated(
      clipBehavior: Clip.hardEdge,
      padding: const EdgeInsets.only(bottom: TenantAdminSpacing.sm),
      itemCount: items.length,
      separatorBuilder: (_, __) => const Divider(
        height: TenantAdminSpacing.xl,
      ),
      itemBuilder: (context, index) {
        return _CartItemRow(
          item: items[index],
          onTap: () => _openEditSheet(context, ref, items[index]),
        );
      },
    );
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
        name: item.product.name,
        categoryName: item.product.category,
        basePrice: item.product.price,
        hasVariants: item.product.hasVariants,
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
    final canUpdateItems =
        session?.hasPermission(PosPermissionCodes.updateCartItem) == true;
    final canRemoveItems =
        session?.hasPermission(PosPermissionCodes.removeCartItem) == true;

    return InkWell(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.product.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: TenantAdminColors.bodyText,
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    if (item.product.variantSummary.isNotEmpty) ...[
                      const SizedBox(height: TenantAdminSpacing.xs),
                      Text(
                        item.product.variantSummary,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: TenantAdminColors.mutedText,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ],
                    const SizedBox(height: TenantAdminSpacing.xs),
                    Text(
                      formatLkr(item.product.price),
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: TenantAdminColors.mutedText,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: TenantAdminSpacing.md),
              Text(
                formatLkr(item.lineTotal),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: TenantAdminColors.bodyText,
                      fontWeight: FontWeight.w900,
                    ),
              ),
            ],
          ),
          const SizedBox(height: TenantAdminSpacing.sm),
          Row(
            children: [
              IconButton.filledTonal(
                visualDensity: VisualDensity.compact,
                onPressed: canUpdateItems
                    ? () => notifier.decreaseQuantity(item.product.cartLineKey)
                    : null,
                icon: const Icon(Icons.remove_rounded),
                tooltip: 'Decrease quantity',
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: TenantAdminSpacing.sm,
                ),
                child: Text(
                  'Qty ${item.quantity}',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: TenantAdminColors.bodyText,
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
              IconButton.filledTonal(
                visualDensity: VisualDensity.compact,
                onPressed: canUpdateItems
                    ? () => notifier.increaseQuantity(item.product.cartLineKey)
                    : null,
                icon: const Icon(Icons.add_rounded),
                tooltip: 'Increase quantity',
              ),
              const Spacer(),
              if (canRemoveItems)
                IconButton(
                  visualDensity: VisualDensity.compact,
                  onPressed: () =>
                      notifier.removeItem(item.product.cartLineKey),
                  icon: const Icon(Icons.delete_outline_rounded),
                  color: TenantAdminColors.danger,
                  tooltip: 'Remove item',
                ),
            ],
          ),
        ],
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
    final canCheckout =
        session?.hasPermission(PosPermissionCodes.checkoutSale) == true;
    final paymentMethods = _allowedPaymentMethods(session);
    final canProceed =
        cart.hasItems && canCheckout && paymentMethods.isNotEmpty;

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
              label: 'Discount',
              value: formatLkr(cart.discount),
            ),
            const SizedBox(height: TenantAdminSpacing.sm),
            _CartTotalLine(label: 'Tax', value: formatLkr(cart.tax)),
            const Divider(height: TenantAdminSpacing.xl),
            _CartTotalLine(
              label: 'Total',
              value: formatLkr(cart.total),
              emphasized: true,
            ),
            const SizedBox(height: TenantAdminSpacing.sm),
            FilledButton.icon(
              onPressed: canProceed
                  ? () => _showPaymentMethods(context, paymentMethods)
                  : null,
              icon: const Icon(Icons.payments_outlined),
              label: const Text('Proceed to Payment'),
            ),
          ],
        ),
      ),
    );
  }

  List<_PaymentMethod> _allowedPaymentMethods(AuthSession? session) {
    if (session == null) {
      return const [];
    }

    return [
      if (session.hasPermission(PosPermissionCodes.acceptCashPayment))
        const _PaymentMethod(
          icon: Icons.payments_outlined,
          label: 'Cash',
        ),
      if (session.hasPermission(PosPermissionCodes.acceptCardPayment))
        const _PaymentMethod(
          icon: Icons.credit_card_rounded,
          label: 'Card',
        ),
      if (session.hasPermission(PosPermissionCodes.acceptQrPayment))
        const _PaymentMethod(
          icon: Icons.qr_code_2_rounded,
          label: 'QR',
        ),
      if (session.hasPermission(PosPermissionCodes.acceptSplitPayment))
        const _PaymentMethod(
          icon: Icons.call_split_rounded,
          label: 'Split',
        ),
    ];
  }

  Future<void> _showPaymentMethods(
    BuildContext context,
    List<_PaymentMethod> methods,
  ) {
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => _PaymentMethodSheet(methods: methods),
    );
  }
}

class _PaymentMethod {
  const _PaymentMethod({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;
}

class _PaymentMethodSheet extends StatelessWidget {
  const _PaymentMethodSheet({required this.methods});

  final List<_PaymentMethod> methods;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          TenantAdminSpacing.lg,
          TenantAdminSpacing.sm,
          TenantAdminSpacing.lg,
          TenantAdminSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Select payment method',
              style: TenantAdminTextStyles.sectionTitle(context),
            ),
            const SizedBox(height: TenantAdminSpacing.md),
            Wrap(
              spacing: TenantAdminSpacing.sm,
              runSpacing: TenantAdminSpacing.sm,
              children: [
                for (final method in methods)
                  OutlinedButton.icon(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(method.icon),
                    label: Text(method.label),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CartTotalLine extends StatelessWidget {
  const _CartTotalLine({
    required this.label,
    required this.value,
    this.emphasized = false,
  });

  final String label;
  final String value;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final style = emphasized
        ? Theme.of(context).textTheme.titleMedium?.copyWith(
              color: TenantAdminColors.bodyText,
              fontWeight: FontWeight.w900,
            )
        : Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: TenantAdminColors.mutedText,
              fontWeight: FontWeight.w700,
            );

    return Row(
      children: [
        Expanded(child: Text(label, style: style)),
        Text(value, style: style),
      ],
    );
  }
}

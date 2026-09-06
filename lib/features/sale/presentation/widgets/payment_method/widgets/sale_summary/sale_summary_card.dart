import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../../cart/presentation/providers/pos_new_sale_cart_provider.dart';
import 'package:nytroz_pos/core/access/permission_access_providers.dart';
import 'package:nytroz_pos/core/access/pos_payment_permission_visibility.dart';
import '../../payment_method_style.dart';

class SaleSummaryCard extends ConsumerWidget {
  const SaleSummaryCard({
    super.key,
    required this.cart,
    this.currency = '',
    this.surface = PaymentSummaryPermissionSurface.checkout,
  });

  final PosNewSaleCartState cart;
  final String currency;
  final PaymentSummaryPermissionSurface surface;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final permissions = ref.watch(effectivePermissionSetProvider);
    final showQty = surface == PaymentSummaryPermissionSurface.checkout
        ? PosPaymentPermissionVisibility.canShowCheckoutSummaryQuantity(
            permissions,
          )
        : PosPaymentPermissionVisibility.canShowCashLineQuantity(permissions);
    final showLineTotal = surface == PaymentSummaryPermissionSurface.checkout
        ? PosPaymentPermissionVisibility.canShowCheckoutSummaryLineTotal(
            permissions,
          )
        : PosPaymentPermissionVisibility.canShowCashLineItemTotal(permissions);
    final showItem = surface == PaymentSummaryPermissionSurface.checkout
        ? PosPaymentPermissionVisibility.canShowCheckoutSummaryItems(
            permissions,
          )
        : PosPaymentPermissionVisibility.canShowCashLineItem(permissions);
    final showItemCount = showQty;

    final items =
        cart.itemList.fold<int>(0, (sum, line) => sum + line.quantity);
    final countLabel = '$items ${items == 1 ? 'Item' : 'Items'}';

    if (!showItem && !showQty && !showLineTotal) {
      return const SizedBox.shrink();
    }

    return Container(
      key: const ValueKey('sale-summary-card'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'SALE SUMMARY',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: PaymentMethodStyle.navy,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
              if (showItemCount)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: PaymentMethodStyle.subtleBackground,
                    border: Border.all(color: PaymentMethodStyle.border),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    countLabel,
                    style: const TextStyle(
                      color: PaymentMethodStyle.navy,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          ProductTableHeader(
            currency: currency,
            showItem: showItem,
            showQty: showQty,
            showAmount: showLineTotal,
          ),
          const Divider(height: 1, color: PaymentMethodStyle.border),
          Expanded(
            child: ListView.separated(
              key: const ValueKey('payment-product-list'),
              padding: const EdgeInsets.symmetric(vertical: 4),
              itemCount: cart.itemList.length,
              separatorBuilder: (_, __) =>
                  const Divider(height: 1, color: PaymentMethodStyle.border),
              itemBuilder: (_, index) => PaymentProductRow(
                key: ValueKey('payment-product-row-$index'),
                item: cart.itemList[index],
                currency: currency,
                showItem: showItem,
                showQty: showQty,
                showAmount: showLineTotal,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ProductTableHeader extends StatelessWidget {
  const ProductTableHeader({
    super.key,
    this.currency = '',
    this.showItem = true,
    this.showQty = true,
    this.showAmount = true,
  });
  final String currency;
  final bool showItem;
  final bool showQty;
  final bool showAmount;

  @override
  Widget build(BuildContext context) {
    final currencyLabel = currency.trim().isNotEmpty ? currency.trim() : 'LKR';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          if (showItem) const Expanded(flex: 5, child: _Header('Item')),
          if (showQty)
            const SizedBox(width: 48, child: _Header('Qty', center: true)),
          if (showAmount)
            SizedBox(
              width: 120,
              child: _Header('Amount ($currencyLabel)', right: true),
            ),
        ],
      ),
    );
  }
}

class PaymentProductRow extends StatelessWidget {
  const PaymentProductRow({
    super.key,
    required this.item,
    this.currency = '',
    this.showItem = true,
    this.showQty = true,
    this.showAmount = true,
  });

  final PosNewSaleCartItem item;
  final String currency;
  final bool showItem;
  final bool showQty;
  final bool showAmount;

  @override
  Widget build(BuildContext context) {
    final image = item.product.imageUrl;
    final sku = item.product.sku?.trim();
    final variant = item.product.variantSummary.trim();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          if (showItem)
            Expanded(
              flex: 5,
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: SizedBox.square(
                      dimension: 48,
                      child: image?.isNotEmpty == true
                          ? Image.network(
                              image!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  const _ImageFallback(),
                            )
                          : const _ImageFallback(),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.product.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: PaymentMethodStyle.navy,
                          ),
                        ),
                        if (variant.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            variant,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF64748B),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                        if (sku != null && sku.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            'SKU: $sku',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF94A3B8),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          if (showQty)
            SizedBox(
              width: 48,
              child: Text(
                '${item.quantity}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: PaymentMethodStyle.navy,
                ),
              ),
            ),
          if (showAmount)
            SizedBox(
              width: 120,
              child: Text(
                paymentMoney(item.lineTotal, currency),
                textAlign: TextAlign.right,
                maxLines: 1,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: PaymentMethodStyle.navy,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header(this.text, {this.center = false, this.right = false});
  final String text;
  final bool center;
  final bool right;

  @override
  Widget build(BuildContext context) => Text(
        text,
        textAlign: right
            ? TextAlign.right
            : center
                ? TextAlign.center
                : TextAlign.left,
        style: const TextStyle(
          color: Color(0xFF64748B),
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
      );
}

class _ImageFallback extends StatelessWidget {
  const _ImageFallback();

  @override
  Widget build(BuildContext context) => Container(
        color: const Color(0xFFF1F5F9),
        child: const Icon(
          Icons.shopping_bag_outlined,
          color: Color(0xFF94A3B8),
          size: 24,
        ),
      );
}

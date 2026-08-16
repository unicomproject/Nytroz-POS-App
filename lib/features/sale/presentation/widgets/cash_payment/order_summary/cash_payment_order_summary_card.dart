import 'package:flutter/material.dart';
import '../../../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';
import '../../../../../cart/presentation/providers/pos_new_sale_cart_provider.dart';
import 'cash_payment_order_items_list.dart';
import 'cash_payment_order_totals.dart';

class CashPaymentOrderSummaryCard extends StatelessWidget {
  const CashPaymentOrderSummaryCard({
    super.key,
    required this.itemCount,
    required this.subtotal,
    required this.discount,
    required this.tax,
    required this.total,
    required this.items,
  });

  final int itemCount;
  final int subtotal;
  final int discount;
  final int tax;
  final int total;
  final List<PosNewSaleCartItem> items;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: TenantAdminColors.surface,
        borderRadius: BorderRadius.circular(TenantAdminRadius.md),
        border: Border.all(color: TenantAdminColors.border),
        boxShadow: TenantAdminShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ORDER SUMMARY',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: TenantAdminColors.bodyText,
                        fontSize: 14,
                      ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.shopping_cart_outlined,
                      size: 14,
                      color: TenantAdminColors.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$itemCount Items',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: TenantAdminColors.primary,
                            fontWeight: FontWeight.w600,
                            fontSize: 11,
                          ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: CashPaymentOrderItemsList(items: items),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
            child: CashPaymentOrderTotals(
              subtotal: subtotal,
              discount: discount,
              tax: tax,
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              color:
                  TenantAdminColors.posHomeAccentOrange.withValues(alpha: 0.12),
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(TenantAdminRadius.md),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'TOTAL DUE',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: TenantAdminColors.bodyText,
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                  ),
                  Text(
                    formatLkr(total),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: TenantAdminColors.posHomeAccentOrange,
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                        ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

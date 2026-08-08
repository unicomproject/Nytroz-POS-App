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
        borderRadius: BorderRadius.circular(TenantAdminRadius.lg),
        border: Border.all(color: TenantAdminColors.border),
        boxShadow: TenantAdminShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(TenantAdminSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ORDER SUMMARY',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: TenantAdminColors.bodyText,
                      ),
                ),
                const SizedBox(height: TenantAdminSpacing.sm),
                Row(
                  children: [
                    const Icon(
                      Icons.shopping_cart_outlined,
                      size: 20,
                      color: TenantAdminColors.primary,
                    ),
                    const SizedBox(width: TenantAdminSpacing.xs),
                    Text(
                      '$itemCount Items',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: TenantAdminColors.primary,
                            fontWeight: FontWeight.w600,
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
            padding: const EdgeInsets.all(TenantAdminSpacing.lg),
            child: CashPaymentOrderTotals(
              subtotal: subtotal,
              discount: discount,
              tax: tax,
            ),
          ),
          DecoratedBox(
            decoration: const BoxDecoration(
              color: TenantAdminColors.posHomeAccentOrange,
              borderRadius: BorderRadius.vertical(
                bottom: Radius.circular(TenantAdminRadius.lg),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: TenantAdminSpacing.lg,
                vertical: TenantAdminSpacing.lg,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'TOTAL DUE',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  Text(
                    formatLkr(total),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
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

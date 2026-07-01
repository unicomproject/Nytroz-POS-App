import 'package:flutter/material.dart';

import '../../../../cart/presentation/providers/pos_new_sale_cart_provider.dart';
import '../../../../cart/presentation/widgets/pos_product_image.dart';
import '../../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';
import '../../providers/pos_cash_payment_success_provider.dart';
import '../payment/payment_panel_card.dart';

class ItemsPurchasedCard extends StatelessWidget {
  const ItemsPurchasedCard({
    super.key,
    required this.items,
    required this.itemCount,
    required this.total,
  });

  final List<PosCashPaymentSuccessLineItem> items;
  final int itemCount;
  final int total;

  @override
  Widget build(BuildContext context) {
    return PaymentPanelCard(
      title: 'Items Purchased ($itemCount)',
      icon: Icons.shopping_bag_outlined,
      child: Column(
        children: [
          const _ItemsHeaderRow(),
          const Divider(height: TenantAdminSpacing.lg),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: TenantAdminSpacing.md),
              child: _ItemRow(item: item),
            ),
          ),
          const Divider(height: TenantAdminSpacing.lg),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Total ($itemCount)',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: TenantAdminColors.bodyText,
                      ),
                ),
              ),
              Text(
                formatLkr(total),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: TenantAdminColors.bodyText,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ItemsHeaderRow extends StatelessWidget {
  const _ItemsHeaderRow();

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.labelLarge?.copyWith(
          color: TenantAdminColors.mutedText,
          fontWeight: FontWeight.w800,
        );

    return Row(
      children: [
        Expanded(flex: 5, child: Text('Item', style: style)),
        Expanded(child: Text('Qty', style: style, textAlign: TextAlign.center)),
        Expanded(
          flex: 2,
          child: Text('Price', style: style, textAlign: TextAlign.end),
        ),
      ],
    );
  }
}

class _ItemRow extends StatelessWidget {
  const _ItemRow({required this.item});

  final PosCashPaymentSuccessLineItem item;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 5,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PosProductImage(
                imageUrl: item.imageUrl,
                category: item.category,
                width: 44,
                height: 44,
              ),
              const SizedBox(width: TenantAdminSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: TenantAdminColors.bodyText,
                          ),
                    ),
                    if (item.variantSummary != null &&
                        item.variantSummary!.isNotEmpty) ...[
                      const SizedBox(height: TenantAdminSpacing.xs),
                      Text(
                        item.variantSummary!,
                        style: TenantAdminTextStyles.muted(context),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Text(
            '${item.quantity}',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
        ),
        Expanded(
          flex: 2,
          child: Text(
            formatLkr(item.lineTotal),
            textAlign: TextAlign.end,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
        ),
      ],
    );
  }
}

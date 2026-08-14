import 'package:flutter/material.dart';
import '../../../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';
import '../../../../../cart/presentation/providers/pos_new_sale_cart_provider.dart';
import 'cash_payment_order_item_row.dart';

class CashPaymentOrderItemsList extends StatelessWidget {
  const CashPaymentOrderItemsList({super.key, required this.items});

  final List<PosNewSaleCartItem> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: DefaultTextStyle(
            style: Theme.of(context).textTheme.labelSmall!.copyWith(
                  fontWeight: FontWeight.w700,
                  color: TenantAdminColors.posHomeAccentOrange,
                  fontSize: 10,
                ),
            child: const Row(
              children: [
                Expanded(flex: 5, child: Text('Item')),
                Expanded(
                  flex: 2,
                  child: Text('Qty', textAlign: TextAlign.center),
                ),
                Expanded(
                  flex: 3,
                  child: Text('Price', textAlign: TextAlign.right),
                ),
                Expanded(
                  flex: 3,
                  child: Text('Total', textAlign: TextAlign.right),
                ),
              ],
            ),
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: ListView.separated(
            padding: EdgeInsets.zero,
            itemCount: items.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              return CashPaymentOrderItemRow(item: items[index]);
            },
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';

import '../../../../../../cart/presentation/providers/pos_new_sale_cart_provider.dart';
import '../../payment_method_style.dart';
import 'applied_discount_card.dart';
import 'customer_card.dart';
import 'sale_summary_card.dart';

class LeftPaymentSummaryColumn extends StatelessWidget {
  const LeftPaymentSummaryColumn({super.key, required this.cart});
  final PosNewSaleCartState cart;

  @override
  Widget build(BuildContext context) => Column(children: [
        Expanded(child: SaleSummaryCard(cart: cart)),
        const SizedBox(height: PaymentMethodStyle.gap),
        SizedBox(height: 70, child: CustomerCard(cart: cart)),
        if (cart.hasDiscount) ...[
          const SizedBox(height: PaymentMethodStyle.gap),
          SizedBox(height: 70, child: AppliedDiscountCard(cart: cart)),
        ],
      ]);
}

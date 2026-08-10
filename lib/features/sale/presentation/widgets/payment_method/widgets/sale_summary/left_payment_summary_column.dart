import 'package:flutter/material.dart';

import '../../../../../../cart/presentation/providers/pos_new_sale_cart_provider.dart';
import '../../payment_method_style.dart';
import 'applied_discount_card.dart';
import 'customer_card.dart';
import 'sale_summary_card.dart';

class LeftPaymentSummaryColumn extends StatelessWidget {
  const LeftPaymentSummaryColumn({
    super.key,
    required this.cart,
    this.onCustomerTap,
  });
  final PosNewSaleCartState cart;
  final VoidCallback? onCustomerTap;

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: PaymentMethodStyle.border),
          borderRadius: BorderRadius.circular(PaymentMethodStyle.panelRadius),
        ),
        padding: const EdgeInsets.all(PaymentMethodStyle.padding),
        child: Column(children: [
          Expanded(child: SaleSummaryCard(cart: cart)),
          const SizedBox(height: 10),
          SizedBox(
            height: 64,
            child: CustomerCard(cart: cart, onTap: onCustomerTap),
          ),
          if (cart.hasDiscount) ...[
            const SizedBox(height: 10),
            SizedBox(height: 64, child: AppliedDiscountCard(cart: cart)),
          ],
        ]),
      );
}

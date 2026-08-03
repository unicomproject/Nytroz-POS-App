import 'package:flutter/material.dart';

import '../../../../../../cart/presentation/providers/pos_new_sale_cart_provider.dart';
import '../../payment_method_style.dart';
import 'customer_card.dart';

class AppliedDiscountCard extends StatelessWidget {
  const AppliedDiscountCard({super.key, required this.cart});
  final PosNewSaleCartState cart;

  @override
  Widget build(BuildContext context) {
    final discount = cart.cartDiscount;
    final label = discount?.reason?.trim().isNotEmpty == true
        ? discount!.reason!.trim()
        : (discount?.policyId ?? 'Applied discount');
    return PaymentInfoCard(
      key: const ValueKey('payment-discount-card'),
      icon: Icons.local_offer_outlined,
      title: 'Applied Discount',
      subtitle: label,
      trailing: '- ${paymentMoney(cart.discount)}',
      success: true,
    );
  }
}

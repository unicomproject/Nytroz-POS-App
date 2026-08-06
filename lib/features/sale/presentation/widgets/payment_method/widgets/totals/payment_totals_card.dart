import 'package:flutter/material.dart';

import '../../../../providers/pos_checkout_summary_provider.dart';
import '../../payment_method_style.dart';

class PaymentTotalsCard extends StatelessWidget {
  const PaymentTotalsCard({super.key, required this.summary});
  final PosCheckoutSummaryViewData summary;

  @override
  Widget build(BuildContext context) => Container(
        key: const ValueKey('payment-totals-card'),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: PaymentMethodStyle.border),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          PaymentTotalRow(label: 'Subtotal', value: summary.subtotal),
          if (summary.discount > 0)
            PaymentTotalRow(
                label: 'Discount',
                value: -summary.discount,
                colour: const Color(0xFF079529)),
          PaymentTotalRow(
              label: 'Tax',
              value: summary.tax,
              colour: PaymentMethodStyle.navy),
          const Divider(height: 10, color: PaymentMethodStyle.border),
          PaymentTotalRow(
              label: 'Total Amount', value: summary.totalPayable, strong: true),
        ]),
      );
}

class PaymentTotalRow extends StatelessWidget {
  const PaymentTotalRow(
      {super.key,
      required this.label,
      required this.value,
      this.colour,
      this.strong = false});
  final String label;
  final int value;
  final Color? colour;
  final bool strong;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(children: [
          Expanded(
              child: Text(label,
                  style: TextStyle(
                      fontSize: strong ? 17 : 14,
                      fontWeight: strong ? FontWeight.w900 : FontWeight.w600))),
          Text(paymentMoney(value),
              style: TextStyle(
                  color: colour,
                  fontSize: strong ? 21 : 14,
                  fontWeight: strong ? FontWeight.w900 : FontWeight.w700)),
        ]),
      );
}

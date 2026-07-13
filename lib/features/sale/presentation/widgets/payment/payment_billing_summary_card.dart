import 'package:flutter/material.dart';

import '../../../../cart/presentation/providers/pos_new_sale_cart_provider.dart';
import 'payment_panel_card.dart';

class PaymentBillingSummaryCard extends StatelessWidget {
  const PaymentBillingSummaryCard({
    super.key,
    required this.itemCount,
    required this.subtotal,
    required this.discount,
    required this.tax,
    required this.totalPayable,
  });

  final int itemCount;
  final int subtotal;
  final int discount;
  final int tax;
  final int totalPayable;

  @override
  Widget build(BuildContext context) {
    return PaymentPanelCard(
      title: 'Billing Summary',
      icon: Icons.receipt_long_outlined,
      child: Column(
        children: [
          _SummaryRow(label: 'Items', value: '$itemCount'),
          const SizedBox(height: 12),
          _SummaryRow(label: 'Subtotal', value: formatLkr(subtotal)),
          const SizedBox(height: 12),
          _SummaryRow(
            label: 'Discount',
            value:
                discount > 0 ? '- ${formatLkr(discount)}' : formatLkr(discount),
            valueColor: discount > 0 ? const Color(0xFF0F9F45) : null,
          ),
          const SizedBox(height: 12),
          _SummaryRow(label: 'Tax', value: formatLkr(tax)),
          const Divider(height: 24),
          _SummaryRow(
            label: 'Total Payable',
            value: formatLkr(totalPayable),
            emphasized: true,
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    this.emphasized = false,
    this.valueColor,
  });

  final String label;
  final String value;
  final bool emphasized;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final style = emphasized
        ? Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w900,
            )
        : Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w700,
            );

    return Row(
      children: [
        Expanded(child: Text(label, style: style)),
        Text(
          value,
          style: style?.copyWith(color: valueColor),
        ),
      ],
    );
  }
}

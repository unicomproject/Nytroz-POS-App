import 'package:flutter/material.dart';

import '../../../../cart/presentation/providers/pos_new_sale_cart_provider.dart';
import '../../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';
import '../payment/payment_panel_card.dart';

class CashSaleSummaryCard extends StatelessWidget {
  const CashSaleSummaryCard({
    super.key,
    required this.itemCount,
    required this.subtotal,
    required this.discount,
    required this.tax,
    required this.total,
    this.discountPercent,
    this.taxPercent,
  });

  final int itemCount;
  final int subtotal;
  final int discount;
  final int tax;
  final int total;
  final int? discountPercent;
  final int? taxPercent;

  @override
  Widget build(BuildContext context) {
    final resolvedDiscountPercent = discountPercent ??
        (subtotal > 0 ? ((discount / subtotal) * 100).round() : 0);
    final resolvedTaxPercent =
        taxPercent ?? (subtotal > 0 ? ((tax / subtotal) * 100).round() : 0);

    return PaymentPanelCard(
      title: 'Sale Summary',
      icon: Icons.receipt_long_outlined,
      child: Column(
        children: [
          _SummaryRow(
            label: 'Subtotal ($itemCount Items)',
            value: formatLkr(subtotal),
          ),
          const SizedBox(height: TenantAdminSpacing.md),
          _SummaryRow(
            label: 'Discount ($resolvedDiscountPercent%)',
            value: '- ${formatLkr(discount)}',
          ),
          const SizedBox(height: TenantAdminSpacing.md),
          _SummaryRow(
            label: 'Tax ($resolvedTaxPercent%)',
            value: formatLkr(tax),
          ),
          const Divider(height: TenantAdminSpacing.xl),
          _SummaryRow(
            label: 'Total to Pay',
            value: formatLkr(total),
            emphasized: true,
            valueColor: TenantAdminColors.info,
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
              color: TenantAdminColors.bodyText,
            )
        : Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: TenantAdminColors.bodyText,
            );

    return Row(
      children: [
        Expanded(child: Text(label, style: style)),
        Text(
          value,
          style: style?.copyWith(color: valueColor ?? style.color),
        ),
      ],
    );
  }
}

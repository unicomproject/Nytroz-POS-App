import 'package:flutter/material.dart';
import '../../../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';
import '../../../../../cart/presentation/providers/pos_new_sale_cart_provider.dart';

class CashPaymentOrderTotals extends StatelessWidget {
  const CashPaymentOrderTotals({
    super.key,
    required this.subtotal,
    required this.discount,
    required this.tax,
  });

  final int subtotal;
  final int discount;
  final int tax;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _SummaryRow(
          label: 'Subtotal',
          value: formatLkr(subtotal),
        ),
        const SizedBox(height: TenantAdminSpacing.sm),
        _SummaryRow(
          label: 'Discount',
          value: '- ${formatLkr(discount)}',
          valueColor: TenantAdminColors.danger,
          icon: Icons.local_offer_outlined,
          iconColor: TenantAdminColors.danger,
        ),
        const SizedBox(height: TenantAdminSpacing.sm),
        _SummaryRow(
          label: 'Tax',
          value: formatLkr(tax),
          valueColor: TenantAdminColors.primary,
        ),
      ],
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    this.valueColor,
    this.icon,
    this.iconColor,
  });

  final String label;
  final String value;
  final Color? valueColor;
  final IconData? icon;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w700,
          color: TenantAdminColors.bodyText,
        );

    return Row(
      children: [
        Expanded(
          child: Row(
            children: [
              Text(label, style: style),
              if (icon != null) ...[
                const SizedBox(width: TenantAdminSpacing.xs),
                Icon(icon,
                    size: 16, color: iconColor ?? TenantAdminColors.mutedText),
              ],
            ],
          ),
        ),
        Text(
          value,
          style: style?.copyWith(color: valueColor ?? style.color),
        ),
      ],
    );
  }
}

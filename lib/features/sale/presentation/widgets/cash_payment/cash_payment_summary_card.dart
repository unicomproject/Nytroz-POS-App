import 'package:flutter/material.dart';

import '../../../../cart/presentation/providers/pos_new_sale_cart_provider.dart';
import '../../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';
import '../../providers/pos_cash_payment_provider.dart';
import '../payment/payment_panel_card.dart';

class CashPaymentSummaryCard extends StatelessWidget {
  const CashPaymentSummaryCard({
    super.key,
    required this.total,
    required this.cashReceived,
  });

  final int total;
  final int cashReceived;

  @override
  Widget build(BuildContext context) {
    final changeDue = cashPaymentChangeDue(cashReceived, total);
    final isSufficient = changeDue >= 0;

    return PaymentPanelCard(
      title: 'Payment Summary',
      icon: Icons.payments_outlined,
      child: Column(
        children: [
          _SummaryRow(
              label: 'Total to Pay',
              value: formatLkr(total),
              valueColor: TenantAdminColors.info),
          const SizedBox(height: TenantAdminSpacing.md),
          _SummaryRow(
            label: 'Cash Received',
            value: formatLkr(cashReceived),
          ),
          const Divider(height: TenantAdminSpacing.xl),
          _SummaryRow(
            label: 'Change Due',
            value: isSufficient ? formatLkr(changeDue) : formatLkr(0),
            valueColor: isSufficient
                ? TenantAdminColors.success
                : TenantAdminColors.danger,
            emphasized: true,
          ),
          if (!isSufficient) ...[
            const SizedBox(height: TenantAdminSpacing.md),
            Text(
              'Short by ${formatLkr(changeDue.abs())}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: TenantAdminColors.danger,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ],
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
    final labelStyle = emphasized
        ? Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: TenantAdminColors.bodyText,
            )
        : Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: TenantAdminColors.bodyText,
            );

    final valueStyle = labelStyle?.copyWith(
      color: valueColor ?? TenantAdminColors.bodyText,
    );

    return Row(
      children: [
        Expanded(child: Text(label, style: labelStyle)),
        Text(value, style: valueStyle),
      ],
    );
  }
}

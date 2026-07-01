import 'package:flutter/material.dart';

import '../../../../cart/presentation/providers/pos_new_sale_cart_provider.dart';
import '../../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';
import '../payment/payment_panel_card.dart';

class PaymentDetailsCard extends StatelessWidget {
  const PaymentDetailsCard({
    super.key,
    required this.cashReceived,
    required this.changeDue,
  });

  final int cashReceived;
  final int changeDue;

  @override
  Widget build(BuildContext context) {
    return PaymentPanelCard(
      title: 'Payment Details',
      icon: Icons.payments_outlined,
      child: Column(
        children: [
          const _DetailRow(label: 'Payment Method', value: 'Cash'),
          const SizedBox(height: TenantAdminSpacing.md),
          _DetailRow(
            label: 'Cash Received',
            value: formatLkr(cashReceived),
          ),
          const SizedBox(height: TenantAdminSpacing.md),
          _DetailRow(
            label: 'Change Due',
            value: formatLkr(changeDue),
            valueColor: TenantAdminColors.success,
            emphasized: true,
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
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
              fontWeight: FontWeight.w800,
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
          style: style?.copyWith(color: valueColor ?? TenantAdminColors.bodyText),
        ),
      ],
    );
  }
}

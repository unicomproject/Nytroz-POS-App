import 'package:flutter/material.dart';

import '../../../../cart/presentation/providers/pos_new_sale_cart_provider.dart';
import '../../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';
import '../../providers/pos_cash_payment_success_provider.dart';
import '../payment/payment_panel_card.dart';

class EmailReceiptSaleSummaryCard extends StatelessWidget {
  const EmailReceiptSaleSummaryCard({
    super.key,
    required this.successData,
  });

  final PosCashPaymentSuccessData successData;

  @override
  Widget build(BuildContext context) {
    return PaymentPanelCard(
      title: 'Sale Summary',
      icon: Icons.receipt_long_outlined,
      child: Column(
        children: [
          _SummaryRow(
            label: 'Receipt No.',
            value: successData.receiptNumber,
          ),
          const SizedBox(height: TenantAdminSpacing.md),
          _SummaryRow(
            label: 'Total Amount',
            value: formatLkr(successData.total),
            emphasized: true,
          ),
          const SizedBox(height: TenantAdminSpacing.md),
          const _SummaryRow(
            label: 'Payment Method',
            value: 'Cash',
          ),
          const SizedBox(height: TenantAdminSpacing.md),
          _SummaryRow(
            label: 'Date & Time',
            value: formatReceiptDateTime(successData.completedAt),
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
  });

  final String label;
  final String value;
  final bool emphasized;

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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: Text(label, style: style)),
        Text(value, style: style, textAlign: TextAlign.end),
      ],
    );
  }
}

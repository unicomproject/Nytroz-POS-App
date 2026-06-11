import 'package:flutter/material.dart';

import '../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';
import '../../domain/entities/tenant_payment_summary.dart';

class PaymentSummaryCard extends StatelessWidget {
  const PaymentSummaryCard({
    super.key,
    required this.summary,
  });

  final TenantPaymentSummary summary;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(TenantAdminSpacing.lg),
      decoration: BoxDecoration(
        color: TenantAdminColors.background,
        borderRadius: BorderRadius.circular(TenantAdminRadius.lg),
        border: Border.all(color: TenantAdminColors.border),
      ),
      child: Column(
        children: [
          _row('Business', summary.tenantName),
          _row('Plan', summary.planName),
          _row('Billing period', summary.billingPeriod),
          _row('Amount', '${summary.currency} ${summary.amount}'),
          if (summary.taxAmount != null)
            _row('Tax/VAT', '${summary.currency} ${summary.taxAmount}'),
          const Divider(height: 28),
          _row(
            'Total payable',
            '${summary.currency} ${summary.totalPayable}',
            strong: true,
          ),
          _row('Payment status', summary.paymentStatus),
        ],
      ),
    );
  }

  Widget _row(String label, String value, {bool strong = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: TenantAdminSpacing.sm),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: TenantAdminColors.mutedText),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: TenantAdminColors.bodyText,
              fontWeight: strong ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

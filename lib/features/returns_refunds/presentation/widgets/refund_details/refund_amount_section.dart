import 'package:flutter/material.dart';

import '../../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';
import '../../providers/return_create_credit_provider.dart';

class RefundAmountSection extends StatelessWidget {
  const RefundAmountSection({
    super.key,
    required this.currency,
    required this.amount,
  });

  final String currency;
  final double amount;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Refund Amount',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: TenantAdminColors.mutedText,
              ),
        ),
        const SizedBox(height: TenantAdminSpacing.sm),
        Text(
          formatReturnCreditAmount(currency: currency, amount: amount),
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: TenantAdminColors.primary,
                fontWeight: FontWeight.w900,
              ),
        ),
      ],
    );
  }
}

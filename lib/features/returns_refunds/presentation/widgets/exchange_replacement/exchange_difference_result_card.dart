import 'package:flutter/material.dart';

import '../../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';
import '../../../domain/entities/exchange_difference_result.dart';
import '../../providers/return_create_credit_provider.dart';

class ExchangeDifferenceResultCard extends StatelessWidget {
  const ExchangeDifferenceResultCard({
    super.key,
    required this.difference,
  });

  final ExchangeDifferencePresentation difference;

  @override
  Widget build(BuildContext context) {
    final (label, color, background) = switch (difference.type) {
      ExchangeDifferenceType.customerPays => (
          'Customer Pays',
          TenantAdminColors.success,
          TenantAdminColors.success.withValues(alpha: 0.12),
        ),
      ExchangeDifferenceType.customerRefund => (
          'Customer Refund',
          TenantAdminColors.warning,
          TenantAdminColors.warning.withValues(alpha: 0.12),
        ),
      ExchangeDifferenceType.evenExchange => (
          'Even Exchange',
          TenantAdminColors.info,
          TenantAdminColors.info.withValues(alpha: 0.12),
        ),
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(TenantAdminSpacing.lg),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(TenantAdminRadius.md),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: TenantAdminSpacing.sm),
          Text(
            formatReturnCreditAmount(
              currency: difference.currencyCode,
              amount: difference.amount,
            ),
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w900,
                ),
          ),
        ],
      ),
    );
  }
}

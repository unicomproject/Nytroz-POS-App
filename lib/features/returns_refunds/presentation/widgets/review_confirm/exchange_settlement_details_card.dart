import 'package:flutter/material.dart';

import '../../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';
import '../../../domain/entities/exchange_difference_result.dart';
import '../../../domain/entities/exchange_replacement_selection.dart';
import '../../providers/return_create_credit_provider.dart';

class ExchangeSettlementDetailsCard extends StatelessWidget {
  const ExchangeSettlementDetailsCard({
    super.key,
    required this.currencyCode,
    required this.returnItemValue,
    required this.replacement,
    required this.difference,
    this.replacementValue,
  });

  final String currencyCode;
  final double returnItemValue;
  final double? replacementValue;
  final ExchangeReplacementSelection? replacement;
  final ExchangeDifferencePresentation? difference;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(TenantAdminSpacing.lg),
      decoration: BoxDecoration(
        color: TenantAdminColors.surface,
        borderRadius: BorderRadius.circular(TenantAdminRadius.lg),
        border: Border.all(color: TenantAdminColors.border),
        boxShadow: TenantAdminShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Settlement Details',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: TenantAdminSpacing.lg),
          _Row(
            label: 'Returned Value',
            value: formatReturnCreditAmount(
              currency: currencyCode,
              amount: returnItemValue,
            ),
          ),
          const SizedBox(height: TenantAdminSpacing.md),
          _Row(
            label: 'Replacement Value',
            value: formatReturnCreditAmount(
              currency: currencyCode,
              amount: replacementValue ?? 0,
            ),
          ),
          if (difference != null) ...[
            const SizedBox(height: TenantAdminSpacing.md),
            _Row(
              label: switch (difference!.type) {
                ExchangeDifferenceType.customerPays => 'Customer Pays',
                ExchangeDifferenceType.customerRefund => 'Customer Refund',
                ExchangeDifferenceType.evenExchange => 'Even Exchange',
              },
              value: formatReturnCreditAmount(
                currency: currencyCode,
                amount: difference!.amount,
              ),
              valueColor: TenantAdminColors.primary,
            ),
          ],
          if (replacement != null) ...[
            const SizedBox(height: TenantAdminSpacing.lg),
            Text(
              'Selected Replacement',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: TenantAdminColors.mutedText,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: TenantAdminSpacing.xs),
            Text(
              replacement!.productName,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            if (replacement!.variantDisplayName.isNotEmpty)
              Text(
                replacement!.variantDisplayName,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: TenantAdminColors.mutedText,
                    ),
              ),
          ],
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.label,
    required this.value,
    this.valueColor,
  });

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: valueColor,
              ),
        ),
      ],
    );
  }
}

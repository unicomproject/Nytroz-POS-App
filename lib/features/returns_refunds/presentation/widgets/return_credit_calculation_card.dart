import 'package:flutter/material.dart';

import '../../../cash_drawer/presentation/widgets/cash_drawer_section_card.dart';
import '../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';
import '../../domain/entities/return_credit_preview.dart';
import '../providers/return_create_credit_provider.dart';

class ReturnCreditCalculationCard extends StatelessWidget {
  const ReturnCreditCalculationCard({
    super.key,
    required this.currency,
    required this.calculation,
  });

  final String currency;
  final ReturnCreditCalculation calculation;

  @override
  Widget build(BuildContext context) {
    return CashDrawerSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Credit Calculation',
            style: TenantAdminTextStyles.sectionTitle(context),
          ),
          const SizedBox(height: TenantAdminSpacing.lg),
          _AmountRow(
            label: 'Item Value',
            value: formatReturnCreditAmount(
              currency: currency,
              amount: calculation.itemValue,
            ),
          ),
          const SizedBox(height: TenantAdminSpacing.md),
          _AmountRow(
            label: calculation.discountLabel.isEmpty
                ? 'Discount Adjustment'
                : calculation.discountLabel,
            value: formatReturnCreditAdjustment(
              currency: currency,
              amount: calculation.discountAdjustment,
            ),
            valueColor: TenantAdminColors.danger,
          ),
          const SizedBox(height: TenantAdminSpacing.md),
          _AmountRow(
            label: calculation.taxLabel.isEmpty
                ? 'Tax Adjustment'
                : calculation.taxLabel,
            value: formatReturnCreditAdjustment(
              currency: currency,
              amount: calculation.taxAdjustment,
            ),
            valueColor: TenantAdminColors.danger,
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: TenantAdminSpacing.lg),
            child: Divider(color: TenantAdminColors.border),
          ),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Net Credit Amount',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
              Text(
                formatReturnCreditAmount(
                  currency: currency,
                  amount: calculation.netCreditAmount,
                ),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: TenantAdminColors.primary,
                      fontWeight: FontWeight.w900,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AmountRow extends StatelessWidget {
  const _AmountRow({
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            label,
            style: TenantAdminTextStyles.muted(context),
          ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: valueColor ?? TenantAdminColors.bodyText,
                fontWeight: FontWeight.w700,
              ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';

import '../../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';
import '../../../domain/entities/return_credit_preview.dart';
import '../../providers/return_create_credit_provider.dart';

class RefundSummaryCard extends StatelessWidget {
  const RefundSummaryCard({
    super.key,
    required this.preview,
  });

  final ReturnCreditPreview preview;

  @override
  Widget build(BuildContext context) {
    final calculation = preview.calculation;
    final currency = preview.currency;
    final itemLabel = preview.selectedItemCount == 1
        ? '1 item'
        : '${preview.selectedItemCount} items';

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
            'Refund Summary',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: TenantAdminSpacing.lg),
          _SummaryRow(label: 'Returned Items', value: itemLabel),
          const SizedBox(height: TenantAdminSpacing.md),
          _SummaryRow(
            label: 'Subtotal',
            value: formatReturnCreditAmount(
              currency: currency,
              amount: calculation.itemValue,
            ),
          ),
          if (calculation.discountAdjustment != 0) ...[
            const SizedBox(height: TenantAdminSpacing.md),
            _SummaryRow(
              label: calculation.discountLabel.isEmpty
                  ? 'Discount Adjustment'
                  : calculation.discountLabel,
              value: formatReturnCreditAdjustment(
                currency: currency,
                amount: calculation.discountAdjustment,
              ),
            ),
          ],
          if (calculation.taxAdjustment != 0) ...[
            const SizedBox(height: TenantAdminSpacing.md),
            _SummaryRow(
              label: calculation.taxLabel.isEmpty
                  ? 'Tax Adjustment'
                  : calculation.taxLabel,
              value: formatReturnCreditAdjustment(
                currency: currency,
                amount: calculation.taxAdjustment,
              ),
            ),
          ],
          const Padding(
            padding: EdgeInsets.symmetric(vertical: TenantAdminSpacing.lg),
            child: Divider(color: TenantAdminColors.border),
          ),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Total Refund Amount',
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

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

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
              ),
        ),
      ],
    );
  }
}

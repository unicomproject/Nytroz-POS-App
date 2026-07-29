import 'package:flutter/material.dart';

import '../../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';
import '../../../domain/entities/exchange_difference_result.dart';
import '../../../domain/entities/exchange_replacement_selection.dart';
import '../../../domain/entities/return_credit_preview.dart';
import '../../../domain/entities/return_exchange.dart';
import '../../../domain/entities/return_resolution_type.dart';
import '../../providers/return_create_credit_provider.dart';
import '../exchange_replacement/exchange_difference_result_card.dart';

class ReturnFinancialSummaryCard extends StatelessWidget {
  const ReturnFinancialSummaryCard({
    super.key,
    required this.resolution,
    required this.preview,
    this.replacement,
    this.difference,
    this.exchangePreview,
  });

  final ReturnResolutionType? resolution;
  final ReturnCreditPreview preview;
  final ExchangeReplacementSelection? replacement;
  final ExchangeDifferencePresentation? difference;
  final ReturnExchangePreview? exchangePreview;

  @override
  Widget build(BuildContext context) {
    final isExchange = resolution == ReturnResolutionType.exchange;
    final calc = preview.calculation;
    final currency = exchangePreview?.currencyCode ?? preview.currency;
    final returnValue =
        exchangePreview?.returnItemValue ?? calc.netCreditAmount;
    final replacementValue = exchangePreview?.replacementItemValue;
    final replacementTax = exchangePreview?.replacementTax;
    final replacementDiscount = exchangePreview?.replacementDiscount;

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
            isExchange ? 'Exchange Summary' : 'Return Summary',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: TenantAdminSpacing.lg),
          if (isExchange) ...[
            _SummaryRow(
              label: 'Return Item Value',
              value: formatReturnCreditAmount(
                currency: currency,
                amount: returnValue,
              ),
            ),
            const SizedBox(height: TenantAdminSpacing.md),
            _SummaryRow(
              label: 'New Item Value',
              value: formatReturnCreditAmount(
                currency: currency,
                amount: replacementValue ?? 0,
              ),
            ),
            if (replacementTax != null && replacementTax != 0) ...[
              const SizedBox(height: TenantAdminSpacing.md),
              _SummaryRow(
                label: 'Replacement Tax',
                value: formatReturnCreditAdjustment(
                  currency: currency,
                  amount: replacementTax,
                ),
              ),
            ],
            if (replacementDiscount != null && replacementDiscount != 0) ...[
              const SizedBox(height: TenantAdminSpacing.md),
              _SummaryRow(
                label: 'Replacement Discount',
                value: formatReturnCreditAdjustment(
                  currency: currency,
                  amount: replacementDiscount,
                ),
              ),
            ],
            if (difference != null) ...[
              const SizedBox(height: TenantAdminSpacing.md),
              _SummaryRow(
                label: 'Difference',
                value: formatReturnCreditAmount(
                  currency: currency,
                  amount:
                      difference!.type == ExchangeDifferenceType.customerRefund
                          ? -difference!.amount
                          : difference!.amount,
                ),
                valueColor: TenantAdminColors.primary,
              ),
              const SizedBox(height: TenantAdminSpacing.lg),
              ExchangeDifferenceResultCard(difference: difference!),
            ],
            if (replacement != null) ...[
              const SizedBox(height: TenantAdminSpacing.lg),
              Text(
                'Replacement',
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
          ] else ...[
            _SummaryRow(
              label: 'Subtotal',
              value: formatReturnCreditAmount(
                currency: preview.currency,
                amount: calc.itemValue,
              ),
            ),
            const SizedBox(height: TenantAdminSpacing.md),
            _SummaryRow(
              label: calc.taxLabel.isEmpty ? 'Tax' : calc.taxLabel,
              value: formatReturnCreditAdjustment(
                currency: preview.currency,
                amount: calc.taxAdjustment,
              ),
            ),
            if (calc.discountAdjustment != 0) ...[
              const SizedBox(height: TenantAdminSpacing.md),
              _SummaryRow(
                label: calc.discountLabel.isEmpty
                    ? 'Discount'
                    : calc.discountLabel,
                value: formatReturnCreditAdjustment(
                  currency: preview.currency,
                  amount: calc.discountAdjustment,
                ),
              ),
            ],
            const SizedBox(height: TenantAdminSpacing.lg),
            const Divider(height: 1, color: TenantAdminColors.border),
            const SizedBox(height: TenantAdminSpacing.lg),
            Text(
              'Total Refund Amount',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: TenantAdminColors.mutedText,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: TenantAdminSpacing.xs),
            Text(
              formatReturnCreditAmount(
                currency: preview.currency,
                amount: calc.netCreditAmount,
              ),
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: TenantAdminColors.primary,
                    fontWeight: FontWeight.w900,
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

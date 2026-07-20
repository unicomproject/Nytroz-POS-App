import 'package:flutter/material.dart';

import '../../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';
import '../../../domain/entities/return_sale_eligibility.dart';
import 'eligibility_policy_note_card.dart';

class EligibilitySummaryCard extends StatelessWidget {
  const EligibilitySummaryCard({
    super.key,
    required this.result,
  });

  final ReturnSaleEligibility result;

  @override
  Widget build(BuildContext context) {
    final statusColor = result.isEligibleOverall
        ? TenantAdminColors.success
        : result.overallStatus == 'PARTIALLY_ELIGIBLE'
            ? TenantAdminColors.warning
            : TenantAdminColors.danger;

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
            'Eligibility Summary',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: TenantAdminColors.bodyText,
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: TenantAdminSpacing.lg),
          _SummaryRow(
            label: 'Invoice No.',
            value: result.invoiceNo,
            valueColor: TenantAdminColors.primary,
          ),
          const SizedBox(height: TenantAdminSpacing.md),
          _SummaryRow(
            label: 'Customer',
            value: result.customerDisplay,
          ),
          const SizedBox(height: TenantAdminSpacing.md),
          _SummaryRow(
            label: 'Eligible Items',
            value: _eligibleItemsLabel(result),
          ),
          const SizedBox(height: TenantAdminSpacing.md),
          _SummaryRow(
            label: 'Status',
            value: result.statusDisplayLabel,
            valueColor: statusColor,
          ),
          if (result.policyNote?.trim().isNotEmpty == true) ...[
            const SizedBox(height: TenantAdminSpacing.lg),
            EligibilityPolicyNoteCard(note: result.policyNote!.trim()),
          ],
        ],
      ),
    );
  }

  String _eligibleItemsLabel(ReturnSaleEligibility result) {
    final count = result.eligibleItemCount;
    final selected = result.selectedItemCount;
    if (selected <= 1) {
      return '$count item';
    }
    return '$count of $selected items';
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 42,
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: TenantAdminColors.mutedText,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ),
        Expanded(
          flex: 58,
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: valueColor ?? TenantAdminColors.bodyText,
                  fontWeight: FontWeight.w900,
                ),
          ),
        ),
      ],
    );
  }
}

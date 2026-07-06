import 'package:flutter/material.dart';

import '../../../cash_drawer/presentation/widgets/cash_drawer_section_card.dart';
import '../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';
import '../../../tenant_admin/presentation/widgets/tenant_admin_status_badge.dart';
import '../../domain/entities/return_receipt.dart';
import '../providers/return_receipt_provider.dart';

class ReturnReceiptSummaryPanel extends StatelessWidget {
  const ReturnReceiptSummaryPanel({
    super.key,
    required this.receipt,
  });

  final ReturnReceipt receipt;

  @override
  Widget build(BuildContext context) {
    final refundAmount = receipt.refundAmount > 0
        ? receipt.refundAmount
        : receipt.customerCreditAmount;

    return CashDrawerSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Return Summary',
            style: TenantAdminTextStyles.sectionTitle(context),
          ),
          const SizedBox(height: TenantAdminSpacing.lg),
          Text(
            'Total Refund Amount',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: TenantAdminColors.mutedText,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: TenantAdminSpacing.xs),
          Text(
            formatReturnReceiptAmount(
              currency: receipt.currency,
              amount: refundAmount,
            ),
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: TenantAdminColors.primary,
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: TenantAdminSpacing.lg),
          Text(
            'Settlement Result',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: TenantAdminColors.mutedText,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: TenantAdminSpacing.sm),
          TenantAdminStatusBadge(
            label: receipt.settlementResult,
            status: TenantAdminStatusType.success,
          ),
          const SizedBox(height: TenantAdminSpacing.lg),
          _SummaryField(label: 'Receipt No.', value: receipt.receiptNumber),
          const SizedBox(height: TenantAdminSpacing.md),
          Text(
            'Return Status',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: TenantAdminColors.mutedText,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: TenantAdminSpacing.sm),
          TenantAdminStatusBadge(
            label: receipt.returnStatus,
            status: TenantAdminStatusType.success,
          ),
          const SizedBox(height: TenantAdminSpacing.lg),
          Container(
            padding: const EdgeInsets.all(TenantAdminSpacing.lg),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(TenantAdminRadius.md),
              border: Border.all(color: const Color(0xFFBBF7D0)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.verified_user_outlined,
                  color: TenantAdminColors.success,
                  size: 20,
                ),
                const SizedBox(width: TenantAdminSpacing.sm),
                Expanded(
                  child: Text(
                    'The refund has been issued successfully and recorded in the system.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryField extends StatelessWidget {
  const _SummaryField({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: TenantAdminColors.mutedText,
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: TenantAdminSpacing.xs),
        Text(
          value,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
      ],
    );
  }
}

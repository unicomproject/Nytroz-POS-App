import 'package:flutter/material.dart';

import '../../../cash_drawer/presentation/widgets/cash_drawer_section_card.dart';
import '../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';
import '../../domain/entities/return_receipt.dart';
import '../providers/return_receipt_provider.dart';

class ReturnReceiptPreviewCard extends StatelessWidget {
  const ReturnReceiptPreviewCard({
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
          Row(
            children: [
              const Icon(
                Icons.receipt_long_outlined,
                color: TenantAdminColors.primary,
              ),
              const SizedBox(width: TenantAdminSpacing.sm),
              Text(
                'Receipt Preview',
                style: TenantAdminTextStyles.sectionTitle(context),
              ),
            ],
          ),
          const SizedBox(height: TenantAdminSpacing.lg),
          _Field(label: 'Receipt No.', value: receipt.receiptNumber),
          const SizedBox(height: TenantAdminSpacing.md),
          _Field(
            label: 'Original Sale No.',
            value: receipt.originalInvoiceNo,
          ),
          const SizedBox(height: TenantAdminSpacing.md),
          _Field(
            label: 'Returned Items',
            value:
                '${receipt.returnedItemCount} item${receipt.returnedItemCount == 1 ? '' : 's'}',
          ),
          const SizedBox(height: TenantAdminSpacing.md),
          _Field(
            label: 'Settlement Method',
            value: receipt.settlementDisplay.isEmpty
                ? receipt.settlementMethodLabel
                : receipt.settlementDisplay,
          ),
          const SizedBox(height: TenantAdminSpacing.md),
          _Field(
            label: 'Refund / Credit Amount',
            value: formatReturnReceiptAmount(
              currency: receipt.currency,
              amount: refundAmount,
            ),
            emphasize: true,
          ),
          const SizedBox(height: TenantAdminSpacing.md),
          _Field(
            label: 'Date & Time',
            value: formatReturnReceiptDateTime(receipt.completedAt),
          ),
        ],
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.label,
    required this.value,
    this.emphasize = false,
  });

  final String label;
  final String value;
  final bool emphasize;

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
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: emphasize ? TenantAdminColors.primary : null,
                fontWeight: emphasize ? FontWeight.w900 : FontWeight.w800,
              ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';

import '../../../cash_drawer/presentation/widgets/cash_drawer_section_card.dart';
import '../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';
import '../../domain/entities/return_credit_preview.dart';
import '../../domain/entities/return_settlement_method.dart';
import '../providers/return_create_credit_provider.dart';
import '../providers/return_search_provider.dart';

class ReturnSettlementSummaryPanel extends StatelessWidget {
  const ReturnSettlementSummaryPanel({
    super.key,
    required this.preview,
    required this.settlementValues,
  });

  final ReturnCreditPreview preview;
  final ReturnSettlementPreviewValues? settlementValues;

  @override
  Widget build(BuildContext context) {
    final currency = preview.currency;
    final netCredit = preview.calculation.netCreditAmount;

    return CashDrawerSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Return Summary',
            style: TenantAdminTextStyles.sectionTitle(context),
          ),
          const SizedBox(height: TenantAdminSpacing.lg),
          _SummaryField(
            label: 'Original Sale',
            value: preview.invoiceNo,
            valueColor: TenantAdminColors.primary,
          ),
          const SizedBox(height: TenantAdminSpacing.md),
          _SummaryField(
            label: 'Sale Date & Time',
            value: formatReturnSaleDateTime(preview.saleDate),
          ),
          const SizedBox(height: TenantAdminSpacing.md),
          _SummaryField(
            label: 'Customer',
            value: preview.customerName.isEmpty
                ? 'Walk-in customer'
                : preview.customerName,
          ),
          const SizedBox(height: TenantAdminSpacing.md),
          _SummaryField(
            label: 'Returned Items',
            value:
                '${preview.selectedItemCount} item${preview.selectedItemCount == 1 ? '' : 's'}',
          ),
          const SizedBox(height: TenantAdminSpacing.md),
          _SummaryField(
            label: 'Return Value',
            value: formatReturnCreditAmount(
              currency: currency,
              amount: netCredit,
            ),
          ),
          const SizedBox(height: TenantAdminSpacing.md),
          _SummaryField(
            label: 'Customer Credit',
            value: formatReturnCreditAmount(
              currency: currency,
              amount: netCredit,
            ),
            valueColor: TenantAdminColors.success,
            emphasize: true,
          ),
          const SizedBox(height: TenantAdminSpacing.md),
          _SummaryField(
            label: 'Settlement Type',
            value: settlementValues?.settlementTypeLabel ?? '-',
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
    this.valueColor,
    this.emphasize = false,
  });

  final String label;
  final String value;
  final Color? valueColor;
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
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: valueColor ?? TenantAdminColors.bodyText,
                fontWeight: emphasize ? FontWeight.w900 : FontWeight.w800,
              ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';

import '../../../cash_drawer/presentation/widgets/cash_drawer_section_card.dart';
import '../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';
import '../../domain/entities/return_credit_preview.dart';
import '../providers/return_create_credit_provider.dart';
import '../providers/return_search_provider.dart';

class ReturnCreditSaleSummaryPanel extends StatelessWidget {
  const ReturnCreditSaleSummaryPanel({
    super.key,
    required this.preview,
  });

  final ReturnCreditPreview preview;

  @override
  Widget build(BuildContext context) {
    final currency = preview.currency;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CashDrawerSectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Original Sale Summary',
                style: TenantAdminTextStyles.sectionTitle(context),
              ),
              const SizedBox(height: TenantAdminSpacing.lg),
              _SummaryField(
                label: 'Invoice No',
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
                label: 'Payment Method',
                value: preview.paymentDisplay.isEmpty
                    ? '-'
                    : preview.paymentDisplay,
              ),
              const SizedBox(height: TenantAdminSpacing.md),
              _SummaryField(
                label: 'Total Amount',
                value: formatReturnCreditAmount(
                  currency: currency,
                  amount: preview.saleTotal,
                ),
                valueColor: TenantAdminColors.primary,
                emphasize: true,
              ),
              const SizedBox(height: TenantAdminSpacing.md),
              _SummaryField(
                label: 'Items in Sale',
                value:
                    '${preview.saleItemCount} item${preview.saleItemCount == 1 ? '' : 's'}',
              ),
            ],
          ),
        ),
        const SizedBox(height: TenantAdminSpacing.lg),
        CashDrawerSectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Selected Return Summary',
                style: TenantAdminTextStyles.sectionTitle(context),
              ),
              const SizedBox(height: TenantAdminSpacing.lg),
              _SummaryField(
                label: 'Items',
                value:
                    '${preview.selectedItemCount} item${preview.selectedItemCount == 1 ? '' : 's'}',
              ),
              const SizedBox(height: TenantAdminSpacing.md),
              _SummaryField(
                label: 'Return Value',
                value: formatReturnCreditAmount(
                  currency: currency,
                  amount: preview.calculation.netCreditAmount,
                ),
                emphasize: true,
              ),
            ],
          ),
        ),
        const SizedBox(height: TenantAdminSpacing.lg),
        CashDrawerSectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Net Credit Amount',
                style: TenantAdminTextStyles.sectionTitle(context),
              ),
              const SizedBox(height: TenantAdminSpacing.md),
              Text(
                formatReturnCreditAmount(
                  currency: currency,
                  amount: preview.calculation.netCreditAmount,
                ),
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: TenantAdminColors.primary,
                      fontWeight: FontWeight.w900,
                    ),
              ),
            ],
          ),
        ),
      ],
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

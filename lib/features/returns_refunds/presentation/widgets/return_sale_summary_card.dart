import 'package:flutter/material.dart';

import '../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';
import '../../domain/entities/return_sale_summary.dart';
import '../providers/return_search_provider.dart';

class ReturnSaleSummaryCard extends StatelessWidget {
  const ReturnSaleSummaryCard({
    super.key,
    required this.sale,
  });

  final ReturnSaleSummary? sale;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(TenantAdminSpacing.xl),
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
            'Original Sale Summary',
            style: TenantAdminTextStyles.sectionTitle(context),
          ),
          const SizedBox(height: TenantAdminSpacing.lg),
          if (sale == null) ...[
            Text(
              'Select a sale from the search results to view the summary.',
              style: TenantAdminTextStyles.muted(context),
            ),
          ] else ...[
            _SummaryRow(
              label: 'Invoice No',
              value: sale!.invoiceNo,
              valueColor: TenantAdminColors.primary,
            ),
            const SizedBox(height: TenantAdminSpacing.md),
            _SummaryRow(
              label: 'Customer',
              value: sale!.customerName.isEmpty
                  ? 'Walk-in customer'
                  : sale!.customerName,
            ),
            const SizedBox(height: TenantAdminSpacing.md),
            _SummaryRow(
              label: 'Sale Date & Time',
              value: formatReturnSaleDateTime(sale!.saleDate),
            ),
            const SizedBox(height: TenantAdminSpacing.md),
            _SummaryRow(
              label: 'Payment Method',
              value: sale!.paymentDisplay.isEmpty ? '-' : sale!.paymentDisplay,
            ),
            const SizedBox(height: TenantAdminSpacing.md),
            _SummaryRow(
              label: 'Total Amount',
              value: formatReturnSaleAmount(sale!),
              valueColor: TenantAdminColors.primary,
              emphasize: true,
            ),
            const SizedBox(height: TenantAdminSpacing.lg),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: TenantAdminSpacing.md,
                vertical: TenantAdminSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: TenantAdminColors.secondary,
                borderRadius: BorderRadius.circular(TenantAdminRadius.md),
              ),
              child: Text(
                '${sale!.itemCount} item${sale!.itemCount == 1 ? '' : 's'}',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: TenantAdminColors.bodyText,
                      fontWeight: FontWeight.w700,
                    ),
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
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: valueColor ?? TenantAdminColors.bodyText,
                fontWeight: emphasize ? FontWeight.w900 : FontWeight.w800,
              ),
        ),
      ],
    );
  }
}

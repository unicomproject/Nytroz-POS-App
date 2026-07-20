import 'package:flutter/material.dart';

import '../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';
import '../../domain/entities/return_sale_summary.dart';
import '../providers/return_search_provider.dart';

class ReturnSaleSummaryCard extends StatelessWidget {
  const ReturnSaleSummaryCard({
    super.key,
    required this.sale,
    this.compact = false,
  });

  final ReturnSaleSummary? sale;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(
        compact ? TenantAdminSpacing.lg : TenantAdminSpacing.xl,
      ),
      decoration: BoxDecoration(
        color: TenantAdminColors.surface,
        borderRadius: BorderRadius.circular(TenantAdminRadius.md),
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
          if (sale == null)
            Text(
              'Select a sale from the search results to view the summary.',
              style: TenantAdminTextStyles.muted(context),
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _SummaryItem(
                  label: 'Invoice No.',
                  value: sale!.invoiceNo,
                  emphasize: true,
                ),
                const _SummaryDivider(),
                _SummaryItem(label: 'Customer', value: _customerName(sale!)),
                const _SummaryDivider(),
                _SummaryItem(
                  label: 'Sale Date & Time',
                  value: formatReturnSaleDateTime(sale!.saleDate),
                ),
                const _SummaryDivider(),
                _SummaryItem(
                  label: 'Payment Method',
                  value:
                      sale!.paymentDisplay.isEmpty ? '-' : sale!.paymentDisplay,
                ),
                const _SummaryDivider(),
                _SummaryItem(
                  label: 'Total Amount',
                  value: formatReturnSaleAmount(sale!),
                  emphasize: true,
                ),
                const SizedBox(height: TenantAdminSpacing.lg),
                Container(
                  padding: const EdgeInsets.all(TenantAdminSpacing.md),
                  decoration: BoxDecoration(
                    color: TenantAdminColors.background,
                    borderRadius: BorderRadius.circular(TenantAdminRadius.md),
                    border: Border.all(color: TenantAdminColors.border),
                  ),
                  child: _SummaryItem(
                    label: 'Items',
                    value: _itemCount(sale!),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  const _SummaryItem({
    required this.label,
    required this.value,
    this.emphasize = false,
  });

  final String label;
  final String value;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: TenantAdminColors.info,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ),
        const SizedBox(width: TenantAdminSpacing.md),
        Expanded(
          child: Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.right,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: emphasize
                      ? TenantAdminColors.primary
                      : TenantAdminColors.bodyText,
                  fontWeight: emphasize ? FontWeight.w900 : FontWeight.w800,
                ),
          ),
        ),
      ],
    );
  }
}

class _SummaryDivider extends StatelessWidget {
  const _SummaryDivider();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: TenantAdminSpacing.lg),
      child: Divider(height: 1, color: TenantAdminColors.border),
    );
  }
}

String _customerName(ReturnSaleSummary sale) {
  return sale.customerName.trim().isEmpty
      ? 'Walk-in customer'
      : sale.customerName.trim();
}

String _itemCount(ReturnSaleSummary sale) {
  return '${sale.itemCount} item${sale.itemCount == 1 ? '' : 's'}';
}

import 'package:flutter/material.dart';

import '../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';
import '../../domain/entities/return_sale_eligibility.dart';
import '../../domain/entities/return_sale_summary.dart';
import '../providers/return_eligibility_provider.dart';
import '../providers/return_search_provider.dart';

class ReturnSelectOriginalSaleSummaryCard extends StatelessWidget {
  const ReturnSelectOriginalSaleSummaryCard({
    super.key,
    required this.sale,
    required this.eligibility,
  });

  final ReturnSaleSummary sale;
  final ReturnSaleEligibility eligibility;

  @override
  Widget build(BuildContext context) {
    final total = sale.total > 0
        ? sale.total
        : eligibility.items
            .fold<double>(0, (sum, item) => sum + item.lineTotal);
    final currency = eligibility.currency.trim().isEmpty
        ? sale.currency
        : eligibility.currency;

    return _PanelCard(
      title: 'Original Sale Summary',
      children: [
        _SummaryRow(label: 'Invoice No.', value: sale.invoiceNo),
        _SummaryRow(
          label: 'Sale Date & Time',
          value:
              formatReturnSaleDateTime(sale.saleDate ?? eligibility.saleDate),
        ),
        _SummaryRow(label: 'Customer', value: _customerName(sale, eligibility)),
        _SummaryRow(label: 'Total Items', value: _itemCount(sale.itemCount)),
        const Divider(height: 20, color: TenantAdminColors.border),
        _SummaryRow(
          label: 'Total Amount',
          value: formatReturnEligibilityAmount(
            currency: currency,
            amount: total,
          ),
          emphasize: true,
        ),
      ],
    );
  }
}

class ReturnSelectionSummaryCard extends StatelessWidget {
  const ReturnSelectionSummaryCard({
    super.key,
    required this.selectedItemCount,
    required this.totalReturnValue,
    required this.currency,
  });

  final int selectedItemCount;
  final double totalReturnValue;
  final String currency;

  @override
  Widget build(BuildContext context) {
    return _PanelCard(
      title: 'Return Summary',
      children: [
        _SummaryRow(
          label: 'Selected Items',
          value: _itemCount(selectedItemCount),
        ),
        const Divider(height: 20, color: TenantAdminColors.border),
        _SummaryRow(
          label: 'Estimated Return Value',
          value: formatReturnEligibilityAmount(
            currency: currency,
            amount: totalReturnValue,
          ),
          emphasize: true,
        ),
      ],
    );
  }
}

class _PanelCard extends StatelessWidget {
  const _PanelCard({
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(TenantAdminSpacing.lg),
      decoration: BoxDecoration(
        color: TenantAdminColors.surface,
        borderRadius: BorderRadius.circular(TenantAdminRadius.md),
        border: Border.all(color: TenantAdminColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: TenantAdminColors.bodyText,
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: TenantAdminSpacing.md),
          const Divider(height: 1, color: TenantAdminColors.border),
          const SizedBox(height: TenantAdminSpacing.lg),
          for (var index = 0; index < children.length; index++) ...[
            if (index > 0 && children[index] is! Divider)
              const SizedBox(height: TenantAdminSpacing.lg),
            children[index],
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
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: TenantAdminColors.primary,
                  fontWeight: FontWeight.w800,
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
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: emphasize
                      ? TenantAdminColors.primary
                      : TenantAdminColors.bodyText,
                  fontSize: emphasize ? 18 : null,
                  fontWeight: emphasize ? FontWeight.w900 : FontWeight.w800,
                ),
          ),
        ),
      ],
    );
  }
}

String _customerName(
  ReturnSaleSummary sale,
  ReturnSaleEligibility eligibility,
) {
  final name = sale.customerName.trim().isNotEmpty
      ? sale.customerName.trim()
      : eligibility.customerName.trim();
  return name.isEmpty ? 'Walk-in customer' : name;
}

String _itemCount(int count) => '$count item${count == 1 ? '' : 's'}';

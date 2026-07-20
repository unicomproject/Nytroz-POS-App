import 'package:flutter/material.dart';

import '../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';
import '../../domain/entities/return_sale_eligibility.dart';
import '../../domain/entities/return_sale_summary.dart';
import '../providers/return_eligibility_provider.dart';
import '../providers/return_search_provider.dart';

class ReturnSaleDetailsCard extends StatelessWidget {
  const ReturnSaleDetailsCard({
    super.key,
    required this.sale,
    required this.eligibility,
  });

  final ReturnSaleSummary sale;
  final ReturnSaleEligibility eligibility;

  @override
  Widget build(BuildContext context) {
    return _SummaryCard(
      title: 'Sale Details',
      children: [
        _LabelValueRow(label: 'Invoice No.', value: sale.invoiceNo),
        _LabelValueRow(label: 'Customer', value: _customerName(sale)),
        _LabelValueRow(
          label: 'Sale Date & Time',
          value:
              formatReturnSaleDateTime(sale.saleDate ?? eligibility.saleDate),
        ),
        _LabelValueRow(
          label: 'Payment Method',
          value: sale.paymentDisplay.isEmpty
              ? eligibility.paymentDisplay
              : sale.paymentDisplay,
        ),
        _LabelValueRow(
          label: 'Total Amount',
          value: formatReturnSaleAmount(sale),
          emphasize: true,
        ),
      ],
    );
  }
}

class ReturnSaleFinancialSummaryCard extends StatelessWidget {
  const ReturnSaleFinancialSummaryCard({
    super.key,
    required this.sale,
    required this.eligibility,
  });

  final ReturnSaleSummary sale;
  final ReturnSaleEligibility eligibility;

  @override
  Widget build(BuildContext context) {
    final subtotal = eligibility.items.fold<double>(
      0,
      (total, item) => total + item.lineTotal,
    );
    final currency = eligibility.currency.trim().isEmpty
        ? sale.currency
        : eligibility.currency;
    final total = sale.total > 0 ? sale.total : subtotal;

    return _SummaryCard(
      title: 'Sale Summary',
      children: [
        _LabelValueRow(label: 'Items', value: _itemCount(sale.itemCount)),
        _LabelValueRow(
          label: 'Subtotal',
          value: formatReturnEligibilityAmount(
            currency: currency,
            amount: subtotal,
          ),
        ),
        const _LabelValueRow(label: 'Discount', value: 'Not available'),
        const _LabelValueRow(label: 'Tax', value: 'Not available'),
        const Divider(height: 18, color: TenantAdminColors.border),
        _LabelValueRow(
          label: 'Total Amount',
          value: formatReturnEligibilityAmount(
            currency: currency,
            amount: total,
          ),
          emphasize: true,
        ),
        _LabelValueRow(
          label: 'Payment Method',
          value: sale.paymentDisplay.isEmpty
              ? eligibility.paymentDisplay
              : sale.paymentDisplay,
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
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
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: TenantAdminColors.bodyText,
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: TenantAdminSpacing.md),
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) const SizedBox(height: TenantAdminSpacing.md),
            children[i],
          ],
        ],
      ),
    );
  }
}

class _LabelValueRow extends StatelessWidget {
  const _LabelValueRow({
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
                  color: TenantAdminColors.primary,
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
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
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

String _customerName(ReturnSaleSummary sale) {
  final name = sale.customerName.trim();
  return name.isEmpty ? 'Walk-in customer' : name;
}

String _itemCount(int count) => '$count item${count == 1 ? '' : 's'}';

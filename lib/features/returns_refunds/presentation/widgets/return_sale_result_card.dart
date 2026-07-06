import 'package:flutter/material.dart';

import '../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';
import '../../domain/entities/return_sale_summary.dart';
import '../providers/return_search_provider.dart';

class ReturnSaleResultCard extends StatelessWidget {
  const ReturnSaleResultCard({
    super.key,
    required this.sale,
    required this.selected,
    required this.onSelected,
  });

  final ReturnSaleSummary sale;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onSelected,
        borderRadius: BorderRadius.circular(TenantAdminRadius.lg),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(TenantAdminSpacing.lg),
          decoration: BoxDecoration(
            color: TenantAdminColors.surface,
            borderRadius: BorderRadius.circular(TenantAdminRadius.lg),
            border: Border.all(
              color: selected
                  ? TenantAdminColors.primary
                  : TenantAdminColors.border,
              width: selected ? 2 : 1,
            ),
            boxShadow: selected ? TenantAdminShadows.card : null,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SelectionIndicator(selected: selected),
              const SizedBox(width: TenantAdminSpacing.sm),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final useGrid =
                        constraints.maxWidth >= TenantAdminBreakpoints.mobile;

                    final fields = [
                      _Field(label: 'Invoice No', value: sale.invoiceNo),
                      _Field(
                        label: 'Customer Name',
                        value: sale.customerName.isEmpty
                            ? 'Walk-in customer'
                            : sale.customerName,
                      ),
                      _Field(
                        label: 'Sale Date & Time',
                        value: formatReturnSaleDateTime(sale.saleDate),
                      ),
                      _Field(
                        label: 'Payment Method',
                        value: sale.paymentDisplay.isEmpty
                            ? '-'
                            : sale.paymentDisplay,
                      ),
                      _Field(
                        label: 'Total Amount',
                        value: formatReturnSaleAmount(sale),
                        emphasize: true,
                      ),
                      _Field(
                        label: 'Items',
                        value:
                            '${sale.itemCount} item${sale.itemCount == 1 ? '' : 's'}',
                      ),
                    ];

                    if (useGrid) {
                      return Column(
                        children: [
                          Row(
                            children: [
                              Expanded(child: fields[0]),
                              Expanded(child: fields[1]),
                              Expanded(child: fields[2]),
                            ],
                          ),
                          const SizedBox(height: TenantAdminSpacing.md),
                          Row(
                            children: [
                              Expanded(child: fields[3]),
                              Expanded(child: fields[4]),
                              Expanded(child: fields[5]),
                            ],
                          ),
                        ],
                      );
                    }

                    return Column(
                      children: [
                        for (var index = 0; index < fields.length; index += 1) ...[
                          if (index > 0)
                            const SizedBox(height: TenantAdminSpacing.sm),
                          fields[index],
                        ],
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SelectionIndicator extends StatelessWidget {
  const _SelectionIndicator({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      margin: const EdgeInsets.only(top: 2),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: selected
              ? TenantAdminColors.primary
              : TenantAdminColors.border,
          width: 2,
        ),
        color: selected ? TenantAdminColors.primary : Colors.transparent,
      ),
      child: selected
          ? const Icon(Icons.check, size: 14, color: Colors.white)
          : null,
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
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: emphasize
                    ? TenantAdminColors.primary
                    : TenantAdminColors.bodyText,
                fontWeight: emphasize ? FontWeight.w900 : FontWeight.w700,
              ),
        ),
      ],
    );
  }
}

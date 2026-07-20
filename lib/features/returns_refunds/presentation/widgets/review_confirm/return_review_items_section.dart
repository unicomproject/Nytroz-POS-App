import 'package:flutter/material.dart';

import '../../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';
import '../../../domain/entities/return_credit_preview.dart';
import 'return_review_item_row.dart';

class ReturnReviewItemsSection extends StatelessWidget {
  const ReturnReviewItemsSection({
    super.key,
    required this.items,
    required this.currencyCode,
    required this.invoiceNo,
    required this.conditionBySaleLineId,
  });

  final List<ReturnCreditPreviewItem> items;
  final String currencyCode;
  final String invoiceNo;
  final Map<String, String> conditionBySaleLineId;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: TenantAdminColors.surface,
        borderRadius: BorderRadius.circular(TenantAdminRadius.lg),
        border: Border.all(color: TenantAdminColors.border),
        boxShadow: TenantAdminShadows.card,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 700;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  TenantAdminSpacing.lg,
                  TenantAdminSpacing.lg,
                  TenantAdminSpacing.lg,
                  TenantAdminSpacing.md,
                ),
                child: Text(
                  'Returned Items',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                ),
              ),
              if (!compact) ...[
                const Divider(height: 1, color: TenantAdminColors.border),
                const Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: TenantAdminSpacing.lg,
                    vertical: TenantAdminSpacing.md,
                  ),
                  child: Row(
                    children: [
                      Expanded(flex: 4, child: _HeaderCell('Item')),
                      Expanded(flex: 2, child: _HeaderCell('Condition')),
                      Expanded(child: _HeaderCell('Qty', alignCenter: true)),
                      Expanded(
                        flex: 2,
                        child: _HeaderCell('Unit Price', alignEnd: true),
                      ),
                      Expanded(
                        flex: 2,
                        child: _HeaderCell('Amount', alignEnd: true),
                      ),
                    ],
                  ),
                ),
              ],
              const Divider(height: 1, color: TenantAdminColors.border),
              if (items.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(TenantAdminSpacing.lg),
                  child: Text(
                    'No returned items available for preview.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: TenantAdminColors.mutedText,
                        ),
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: items.length,
                  separatorBuilder: (_, __) =>
                      const Divider(height: 1, color: TenantAdminColors.border),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    final condition =
                        conditionBySaleLineId[item.saleLineId] ?? '-';
                    final invoiceLabel = invoiceNo.isEmpty
                        ? (item.sku.isEmpty ? '' : item.sku)
                        : invoiceNo;
                    return ReturnReviewItemRow(
                      item: item,
                      currencyCode: currencyCode,
                      conditionLabel: condition,
                      invoiceLabel: invoiceLabel,
                      compact: compact,
                    );
                  },
                ),
              const Divider(height: 1, color: TenantAdminColors.border),
              Padding(
                padding: const EdgeInsets.all(TenantAdminSpacing.lg),
                child: Text(
                  'Total Items: ${items.length}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  const _HeaderCell(
    this.label, {
    this.alignEnd = false,
    this.alignCenter = false,
  });

  final String label;
  final bool alignEnd;
  final bool alignCenter;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      textAlign: alignCenter
          ? TextAlign.center
          : alignEnd
              ? TextAlign.end
              : TextAlign.start,
      style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: TenantAdminColors.mutedText,
            fontWeight: FontWeight.w800,
          ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';
import '../../providers/return_success_display.dart';
import 'completed_item_row.dart';

class CompletedItemsSummaryCard extends StatelessWidget {
  const CompletedItemsSummaryCard({
    super.key,
    required this.items,
    required this.currencyCode,
    required this.totalItems,
  });

  final List<CompletedItemDisplay> items;
  final String currencyCode;
  final int totalItems;

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
      child: Column(
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
              'Returned Items Summary',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
            ),
          ),
          const Divider(height: 1, color: TenantAdminColors.border),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: TenantAdminSpacing.lg,
              vertical: TenantAdminSpacing.sm,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Item',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: TenantAdminColors.mutedText,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ),
                Text(
                  'Amount',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: TenantAdminColors.mutedText,
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: TenantAdminColors.border),
          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.all(TenantAdminSpacing.lg),
              child: Text(
                'No completed item details are available.',
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
                return CompletedItemRow(
                  item: items[index],
                  currencyCode: currencyCode,
                );
              },
            ),
          const Divider(height: 1, color: TenantAdminColors.border),
          Padding(
            padding: const EdgeInsets.all(TenantAdminSpacing.lg),
            child: Text(
              'Total Items: $totalItems',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

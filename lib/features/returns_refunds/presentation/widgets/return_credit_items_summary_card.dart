import 'package:flutter/material.dart';

import '../../../cash_drawer/presentation/widgets/cash_drawer_section_card.dart';
import '../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';
import '../../domain/entities/return_credit_preview.dart';
import '../providers/return_create_credit_provider.dart';

class ReturnCreditItemsSummaryCard extends StatelessWidget {
  const ReturnCreditItemsSummaryCard({
    super.key,
    required this.items,
    required this.currency,
    required this.onEditItems,
  });

  final List<ReturnCreditPreviewItem> items;
  final String currency;
  final VoidCallback onEditItems;

  @override
  Widget build(BuildContext context) {
    return CashDrawerSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Returned Items Summary',
                  style: TenantAdminTextStyles.sectionTitle(context),
                ),
              ),
              TextButton(
                onPressed: onEditItems,
                child: const Text('Edit Items'),
              ),
            ],
          ),
          const SizedBox(height: TenantAdminSpacing.lg),
          LayoutBuilder(
            builder: (context, constraints) {
              final useRow =
                  constraints.maxWidth >= TenantAdminBreakpoints.tablet &&
                      items.length <= 3;

              if (useRow) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (var index = 0; index < items.length; index += 1) ...[
                      if (index > 0)
                        const SizedBox(width: TenantAdminSpacing.md),
                      Expanded(
                          child: _CreditItemTile(
                        item: items[index],
                        currency: currency,
                      )),
                    ],
                  ],
                );
              }

              return Column(
                children: [
                  for (var index = 0; index < items.length; index += 1) ...[
                    if (index > 0)
                      const SizedBox(height: TenantAdminSpacing.md),
                    _CreditItemTile(item: items[index], currency: currency),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _CreditItemTile extends StatelessWidget {
  const _CreditItemTile({
    required this.item,
    required this.currency,
  });

  final ReturnCreditPreviewItem item;
  final String currency;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(TenantAdminSpacing.md),
      decoration: BoxDecoration(
        color: TenantAdminColors.background,
        borderRadius: BorderRadius.circular(TenantAdminRadius.md),
        border: Border.all(color: TenantAdminColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ItemThumbnail(name: item.name),
          const SizedBox(width: TenantAdminSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                if (item.sku.isNotEmpty || item.variantLabel.isNotEmpty) ...[
                  const SizedBox(height: TenantAdminSpacing.xs),
                  Text(
                    _skuDisplay,
                    style: TenantAdminTextStyles.muted(context),
                  ),
                ],
                const SizedBox(height: TenantAdminSpacing.xs),
                Text(
                  'Qty ${item.returnQty % 1 == 0 ? item.returnQty.toInt() : item.returnQty}',
                  style: TenantAdminTextStyles.muted(context),
                ),
              ],
            ),
          ),
          Text(
            formatReturnCreditAmount(
                currency: currency, amount: item.lineAmount),
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
        ],
      ),
    );
  }

  String get _skuDisplay {
    if (item.sku.isEmpty) {
      return item.variantLabel;
    }
    if (item.variantLabel.isEmpty) {
      return 'SKU: ${item.sku}';
    }
    return 'SKU: ${item.sku} | ${item.variantLabel}';
  }
}

class _ItemThumbnail extends StatelessWidget {
  const _ItemThumbnail({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: TenantAdminColors.secondary,
        borderRadius: BorderRadius.circular(TenantAdminRadius.md),
      ),
      child: Icon(
        Icons.inventory_2_outlined,
        color: TenantAdminColors.info,
        semanticLabel: name,
      ),
    );
  }
}

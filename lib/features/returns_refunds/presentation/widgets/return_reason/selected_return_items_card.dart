import 'package:flutter/material.dart';

import '../../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';
import '../../providers/return_flow_provider.dart';
import 'selected_return_item_tile.dart';

class SelectedReturnItemsCard extends StatelessWidget {
  const SelectedReturnItemsCard({
    super.key,
    required this.items,
    required this.currency,
  });

  final List<ReturnSelectedReturnLine> items;
  final String currency;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(TenantAdminSpacing.lg),
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
            'Selected Items (${items.length})',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: TenantAdminColors.bodyText,
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: TenantAdminSpacing.lg),
          for (var index = 0; index < items.length; index += 1) ...[
            if (index > 0)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: TenantAdminSpacing.md),
                child: Divider(color: TenantAdminColors.border, height: 1),
              ),
            SelectedReturnItemTile(
              item: items[index],
              currency: currency,
            ),
          ],
        ],
      ),
    );
  }
}

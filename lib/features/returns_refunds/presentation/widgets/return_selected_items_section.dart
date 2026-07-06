import 'package:flutter/material.dart';

import '../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';
import '../providers/return_flow_provider.dart';
import 'return_selected_item_card.dart';

class ReturnSelectedItemsSection extends StatelessWidget {
  const ReturnSelectedItemsSection({
    super.key,
    required this.items,
  });

  final List<ReturnSelectedReturnLine> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Selected Items (${items.length})',
          style: TenantAdminTextStyles.sectionTitle(context),
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
                    if (index > 0) const SizedBox(width: TenantAdminSpacing.md),
                    Expanded(
                      child: ReturnSelectedItemCard(item: items[index]),
                    ),
                  ],
                ],
              );
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var index = 0; index < items.length; index += 1) ...[
                  if (index > 0) const SizedBox(height: TenantAdminSpacing.md),
                  ReturnSelectedItemCard(item: items[index]),
                ],
              ],
            );
          },
        ),
      ],
    );
  }
}

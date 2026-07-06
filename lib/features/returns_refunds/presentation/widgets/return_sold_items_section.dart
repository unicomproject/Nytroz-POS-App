import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../cash_drawer/presentation/widgets/cash_drawer_section_card.dart';
import '../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';
import '../providers/return_eligibility_provider.dart';
import 'return_sold_item_row.dart';

class ReturnSoldItemsSection extends ConsumerWidget {
  const ReturnSoldItemsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(returnEligibilityProvider);
    final items = state.eligibility?.items ?? const [];

    return CashDrawerSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Sold Items (${items.length})',
            style: TenantAdminTextStyles.sectionTitle(context),
          ),
          const SizedBox(height: TenantAdminSpacing.lg),
          if (items.isEmpty)
            Text(
              'No sold items were found for this sale.',
              style: TenantAdminTextStyles.muted(context),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: items.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(height: TenantAdminSpacing.md),
              itemBuilder: (context, index) {
                final item = items[index];
                final selection = state.selectionFor(item.saleLineId);
                return ReturnSoldItemRow(
                  item: item,
                  isSelected: selection?.isSelected ?? false,
                  returnQty: selection?.returnQty ?? 0,
                );
              },
            ),
        ],
      ),
    );
  }
}

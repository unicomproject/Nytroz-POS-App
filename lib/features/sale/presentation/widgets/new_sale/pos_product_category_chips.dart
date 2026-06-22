import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nytroz_pos/features/cart/presentation/providers/pos_new_sale_cart_provider.dart';

import '../../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';

class PosProductCategoryChips extends ConsumerWidget {
  const PosProductCategoryChips({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedCategory = ref.watch(posNewSaleSelectedCategoryProvider);

    return SizedBox(
      height: 34,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: posNewSaleCategories.length,
        separatorBuilder: (_, __) => const SizedBox(
          width: TenantAdminSpacing.sm,
        ),
        itemBuilder: (context, index) {
          final category = posNewSaleCategories[index];
          final selected = selectedCategory == category;

          return ChoiceChip(
            visualDensity: VisualDensity.compact,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            showCheckmark: true,
            selected: selected,
            label: Text(category),
            onSelected: (isSelected) {
              if (isSelected) {
                ref.read(posNewSaleSelectedCategoryProvider.notifier).state =
                    category;
              }
            },
            selectedColor: TenantAdminColors.info,
            backgroundColor: TenantAdminColors.surface,
            labelStyle: TextStyle(
              color: selected ? Colors.white : TenantAdminColors.bodyText,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
            labelPadding: const EdgeInsets.symmetric(
              horizontal: TenantAdminSpacing.sm,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(TenantAdminRadius.xl),
              side: const BorderSide(color: TenantAdminColors.border),
            ),
          );
        },
      ),
    );
  }
}

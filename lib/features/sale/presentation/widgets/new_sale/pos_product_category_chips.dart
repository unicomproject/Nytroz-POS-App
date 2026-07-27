import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nytroz_pos/core/access/pos_permission_access.dart';
import 'package:nytroz_pos/features/auth/presentation/providers/session_provider.dart';
import 'package:nytroz_pos/features/cart/presentation/providers/pos_catalog_provider.dart';

import '../../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';

class PosProductCategoryChips extends ConsumerWidget {
  const PosProductCategoryChips({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authSessionProvider);
    if (!PosPermissionAccess.canViewProductsSession(session)) {
      return const SizedBox.shrink();
    }

    final categoriesAsync = ref.watch(posNewSaleCategoriesProvider);
    final selectedCategoryId = ref.watch(posNewSaleSelectedCategoryIdProvider);

    return categoriesAsync.when(
      loading: () => const SizedBox(
        height: 34,
        child: Center(
          child: SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      ),
      error: (_, __) => const SizedBox.shrink(),
      data: (categories) {
        return SizedBox(
          height: 34,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: categories.length,
            separatorBuilder: (_, __) => const SizedBox(
              width: TenantAdminSpacing.sm,
            ),
            itemBuilder: (context, index) {
              final category = categories[index];
              final selected = selectedCategoryId == category.id;

              return ChoiceChip(
                visualDensity: VisualDensity.compact,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                showCheckmark: true,
                selected: selected,
                label: Text(category.name),
                onSelected: (isSelected) {
                  if (isSelected) {
                    ref
                        .read(posNewSaleSelectedCategoryIdProvider.notifier)
                        .state = category.id;
                  }
                },
                selectedColor: TenantAdminColors.posNewSaleAccent,
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
      },
    );
  }
}

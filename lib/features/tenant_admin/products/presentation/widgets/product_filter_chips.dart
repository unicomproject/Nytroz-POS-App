import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../presentation/theme/tenant_admin_theme.dart';
import '../providers/product_providers.dart';
import '../utils/product_list_filters.dart';

class ProductFilterChips extends ConsumerWidget {
  const ProductFilterChips({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(productStatusFilterProvider);

    return Wrap(
      spacing: TenantAdminSpacing.sm,
      runSpacing: TenantAdminSpacing.sm,
      children: ProductStatusFilter.values.map((filter) {
        final isSelected = selected == filter;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                ref.read(productStatusFilterProvider.notifier).state = filter;
                ref.read(productPageProvider.notifier).state = 1;
              },
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? TenantAdminColors.primary.withValues(alpha: 0.1)
                      : TenantAdminColors.background,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected
                        ? TenantAdminColors.primary.withValues(alpha: 0.3)
                        : TenantAdminColors.border,
                    width: 1,
                  ),
                ),
                child: Text(
                  filter.label,
                  style: TextStyle(
                    color: isSelected
                        ? TenantAdminColors.primary
                        : TenantAdminColors.mutedText,
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                    letterSpacing: 0.1,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(growable: false),
    );
  }
}

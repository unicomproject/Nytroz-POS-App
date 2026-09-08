import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nytroz_pos/core/access/permission_access_providers.dart';
import 'package:nytroz_pos/core/access/pos_sales_permission_visibility.dart';

import '../../../../../cart/presentation/providers/pos_parked_sale_provider.dart';
import '../../../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';

class ParkedSaleScopeFilters extends ConsumerWidget {
  const ParkedSaleScopeFilters({
    super.key,
    required this.selected,
    required this.loading,
    required this.onSelected,
  });

  final PosParkedSaleScope selected;
  final bool loading;
  final ValueChanged<PosParkedSaleScope> onSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final permissions = ref.watch(effectivePermissionSetProvider);
    if (!PosSalesPermissionVisibility.canShowHeldFilters(permissions)) {
      return const SizedBox.shrink();
    }

    // Today / This Shift / All share one canonical code: list.filters.
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: TenantAdminSpacing.lg),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Wrap(
          spacing: TenantAdminSpacing.sm,
          runSpacing: TenantAdminSpacing.sm,
          children: PosParkedSaleScope.values.map((scope) {
            final isSelected = selected == scope;
            return InkWell(
              key: ValueKey('parked-sales-scope-${scope.apiValue}'),
              onTap: loading ? null : () => onSelected(scope),
              borderRadius: BorderRadius.circular(TenantAdminRadius.md),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? TenantAdminColors.posNewSaleAccent
                      : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(TenantAdminRadius.md),
                  border: Border.all(
                    color: isSelected
                        ? TenantAdminColors.posNewSaleAccent
                        : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      scope == PosParkedSaleScope.today
                          ? Icons.calendar_today_outlined
                          : scope == PosParkedSaleScope.currentShift
                              ? Icons.schedule_outlined
                              : Icons.layers_outlined,
                      size: 16,
                      color: isSelected
                          ? Colors.white
                          : const Color(0xFF64748B),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      scope.label,
                      style: TextStyle(
                        color: isSelected
                            ? Colors.white
                            : const Color(0xFF334155),
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(growable: false),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';
import '../../domain/entities/return_flow_steps.dart';

class ReturnSearchFilterTabs extends StatelessWidget {
  const ReturnSearchFilterTabs({
    super.key,
    required this.selectedTab,
    required this.onTabSelected,
  });

  final ReturnSearchTab selectedTab;
  final ValueChanged<ReturnSearchTab> onTabSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: TenantAdminSpacing.sm,
      runSpacing: TenantAdminSpacing.sm,
      children: ReturnSearchTab.values.map((tab) {
        final selected = tab == selectedTab;
        return Material(
          color: selected
              ? TenantAdminColors.primary.withValues(alpha: 0.08)
              : TenantAdminColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(TenantAdminRadius.sm),
            side: BorderSide(
              color: selected
                  ? TenantAdminColors.primary
                  : TenantAdminColors.border,
            ),
          ),
          child: InkWell(
            onTap: () => onTabSelected(tab),
            borderRadius: BorderRadius.circular(TenantAdminRadius.sm),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 76, minHeight: 36),
              child: Center(
                child: Text(
                  tab.label,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: selected
                            ? TenantAdminColors.primary
                            : TenantAdminColors.bodyText,
                        fontWeight:
                            selected ? FontWeight.w900 : FontWeight.w700,
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

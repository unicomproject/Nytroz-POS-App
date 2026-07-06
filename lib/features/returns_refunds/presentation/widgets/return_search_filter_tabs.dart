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
        return ChoiceChip(
          label: Text(tab.label),
          selected: selected,
          onSelected: (_) => onTabSelected(tab),
          selectedColor: TenantAdminColors.primary.withValues(alpha: 0.12),
          labelStyle: TextStyle(
            color: selected
                ? TenantAdminColors.primary
                : TenantAdminColors.bodyText,
            fontWeight: FontWeight.w700,
          ),
          side: BorderSide(
            color: selected
                ? TenantAdminColors.primary
                : TenantAdminColors.border,
          ),
        );
      }).toList(growable: false),
    );
  }
}

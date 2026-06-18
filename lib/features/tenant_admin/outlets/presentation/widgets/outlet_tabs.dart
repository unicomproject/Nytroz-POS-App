import 'package:flutter/material.dart';

import '../config/outlet_details_tab_configs.dart';
import '../../../presentation/theme/tenant_admin_theme.dart';

class OutletTabs extends StatelessWidget {
  const OutletTabs({
    super.key,
    required this.tabs,
    required this.selectedIndex,
    required this.onChanged,
  });

  final List<OutletDetailsTabConfig> tabs;
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    if (tabs.isEmpty) {
      return const SizedBox.shrink();
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Container(
        padding: const EdgeInsets.all(TenantAdminSpacing.xs),
        decoration: BoxDecoration(
          color: TenantAdminColors.surface,
          borderRadius: BorderRadius.circular(TenantAdminRadius.lg),
          border: Border.all(color: TenantAdminColors.border),
        ),
        child: Row(
          children: [
            for (var index = 0; index < tabs.length; index++) ...[
              _TabChip(
                label: tabs[index].label,
                icon: tabs[index].icon,
                selected: selectedIndex == index,
                onTap: () => onChanged(index),
              ),
              if (index != tabs.length - 1)
                const SizedBox(width: TenantAdminSpacing.xs),
            ],
          ],
        ),
      ),
    );
  }
}

class _TabChip extends StatelessWidget {
  const _TabChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? TenantAdminColors.primary : Colors.transparent,
      borderRadius: BorderRadius.circular(TenantAdminRadius.md),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(TenantAdminRadius.md),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: TenantAdminSpacing.lg,
            vertical: TenantAdminSpacing.md,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 18,
                color: selected ? Colors.white : TenantAdminColors.mutedText,
              ),
              const SizedBox(width: TenantAdminSpacing.sm),
              Text(
                label,
                style: TextStyle(
                  color: selected ? Colors.white : TenantAdminColors.bodyText,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

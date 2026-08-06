import 'package:flutter/material.dart';

import '../../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';
import '../../../domain/entities/return_inspection.dart';

class InspectionConditionSelector extends StatelessWidget {
  const InspectionConditionSelector({
    super.key,
    required this.conditions,
    required this.selectedConditionCode,
    required this.onConditionSelected,
  });

  final List<InspectionConditionOption> conditions;
  final String? selectedConditionCode;
  final ValueChanged<String> onConditionSelected;

  @override
  Widget build(BuildContext context) {
    if (conditions.isEmpty) {
      return Text(
        'No inspection conditions are configured for this tenant.',
        style: TenantAdminTextStyles.muted(context),
      );
    }

    return Wrap(
      spacing: TenantAdminSpacing.sm,
      runSpacing: TenantAdminSpacing.sm,
      children: [
        for (final condition in conditions)
          _ConditionPill(
            label: condition.displayName,
            selected: selectedConditionCode == condition.code,
            color: _colorForCategory(condition.statusCategory),
            onTap: () => onConditionSelected(condition.code),
          ),
      ],
    );
  }

  Color _colorForCategory(String category) {
    switch (category.toUpperCase()) {
      case 'GOOD':
        return TenantAdminColors.primary;
      case 'WARNING':
        return TenantAdminColors.warning;
      case 'DANGER':
        return TenantAdminColors.danger;
      default:
        return TenantAdminColors.mutedText;
    }
  }
}

class _ConditionPill extends StatelessWidget {
  const _ConditionPill({
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(TenantAdminRadius.sm),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: TenantAdminSpacing.md,
          vertical: TenantAdminSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: selected
              ? color.withValues(alpha: 0.12)
              : TenantAdminColors.surface,
          borderRadius: BorderRadius.circular(TenantAdminRadius.sm),
          border: Border.all(
            color: selected ? color : TenantAdminColors.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_off,
              size: 18,
              color: selected ? color : TenantAdminColors.mutedText,
            ),
            const SizedBox(width: TenantAdminSpacing.xs),
            Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: selected ? color : TenantAdminColors.bodyText,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

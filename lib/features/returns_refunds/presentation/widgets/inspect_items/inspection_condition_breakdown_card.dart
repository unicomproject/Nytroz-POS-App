import 'package:flutter/material.dart';

import '../../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';
import '../../providers/return_inspection_provider.dart';

class InspectionConditionBreakdownCard extends StatelessWidget {
  const InspectionConditionBreakdownCard({
    super.key,
    required this.state,
  });

  final ReturnInspectionState state;

  @override
  Widget build(BuildContext context) {
    final breakdown = state.conditionBreakdown;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(TenantAdminSpacing.lg),
      decoration: BoxDecoration(
        color: TenantAdminColors.surface,
        borderRadius: BorderRadius.circular(TenantAdminRadius.lg),
        border: Border.all(color: TenantAdminColors.border),
        boxShadow: TenantAdminShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Condition Breakdown',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: TenantAdminSpacing.lg),
          for (final condition in state.conditions) ...[
            _BreakdownRow(
              label: condition.displayName,
              count: breakdown[condition.code] ?? 0,
              color: _colorForCategory(condition.statusCategory),
            ),
            const SizedBox(height: TenantAdminSpacing.sm),
          ],
          _BreakdownRow(
            label: 'Pending',
            count: breakdown['PENDING'] ?? 0,
            color: TenantAdminColors.mutedText,
          ),
        ],
      ),
    );
  }

  Color _colorForCategory(String category) {
    switch (category.toUpperCase()) {
      case 'GOOD':
        return TenantAdminColors.success;
      case 'WARNING':
        return TenantAdminColors.warning;
      case 'DANGER':
        return TenantAdminColors.danger;
      default:
        return TenantAdminColors.mutedText;
    }
  }
}

class _BreakdownRow extends StatelessWidget {
  const _BreakdownRow({
    required this.label,
    required this.count,
    required this.color,
  });

  final String label;
  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: TenantAdminSpacing.sm),
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
        Text(
          '$count',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w900,
              ),
        ),
      ],
    );
  }
}

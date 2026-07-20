import 'package:flutter/material.dart';

import '../../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';
import '../../providers/return_inspection_provider.dart';

class InspectionSummaryCard extends StatelessWidget {
  const InspectionSummaryCard({
    super.key,
    required this.state,
  });

  final ReturnInspectionState state;

  @override
  Widget build(BuildContext context) {
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
            'Inspection Summary',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: TenantAdminSpacing.lg),
          _Row(
            label: 'Selected Items',
            value: '${state.selectedItemCount}',
            valueColor: TenantAdminColors.primary,
          ),
          const SizedBox(height: TenantAdminSpacing.md),
          _Row(
            label: 'Inspected',
            value: '${state.inspectedItemCount}',
            valueColor: TenantAdminColors.success,
          ),
          const SizedBox(height: TenantAdminSpacing.md),
          _Row(
            label: 'Pending',
            value: '${state.pendingItemCount}',
            valueColor: TenantAdminColors.warning,
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.label,
    required this.value,
    required this.valueColor,
  });

  final String label;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: valueColor,
                fontWeight: FontWeight.w900,
              ),
        ),
      ],
    );
  }
}

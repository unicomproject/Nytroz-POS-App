import 'package:flutter/material.dart';

import '../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';
import '../../domain/entities/pos_home_action.dart';
import 'pos_home_action_card.dart';

class PosCashDrawerSummaryCard extends StatelessWidget {
  const PosCashDrawerSummaryCard({
    super.key,
    required this.action,
    this.onViewCashDrawer,
  });

  final PosHomeAction action;
  final VoidCallback? onViewCashDrawer;

  @override
  Widget build(BuildContext context) {
    return PosHomeActionCard(
      action: action,
      icon: Icons.point_of_sale_outlined,
      description: 'View drawer status and current balance.',
      metrics: const [
        _OpenStatusChip(),
        SizedBox(height: TenantAdminSpacing.sm),
        PosActionMetricLine(
          value: 'LKR 1,245.30',
          label: 'Current Balance',
        ),
      ],
      // TODO: Enable when a confirmed cash-drawer route exists.
      onTap: action.routeExists ? onViewCashDrawer : null,
    );
  }
}

class _OpenStatusChip extends StatelessWidget {
  const _OpenStatusChip();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: TenantAdminSpacing.md,
          vertical: TenantAdminSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: TenantAdminColors.success.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(TenantAdminRadius.xl),
        ),
        child: const Text(
          'Open',
          style: TextStyle(
            color: TenantAdminColors.success,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

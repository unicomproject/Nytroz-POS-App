import 'package:flutter/material.dart';

import '../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';
import '../../domain/entities/pos_home_action.dart';
import 'home/pos_home_action_card.dart';

class PosReturnsSummaryCard extends StatelessWidget {
  const PosReturnsSummaryCard({
    super.key,
    required this.action,
    this.onViewReturns,
  });

  final PosHomeAction action;
  final VoidCallback? onViewReturns;

  @override
  Widget build(BuildContext context) {
    return PosHomeActionCard(
      action: action,
      icon: Icons.assignment_return_outlined,
      description: 'Process returns and issue refunds quickly.',
      buttonLabel: 'View Returns',
      metrics: const [
        PosActionMetricLine(value: '5', label: 'Returns Today'),
        PosActionMetricLine(
          value: 'LKR 124.50',
          label: 'Refunded Today',
          color: TenantAdminColors.danger,
        ),
      ],
      onTap: action.routeExists ? onViewReturns : null,
    );
  }
}

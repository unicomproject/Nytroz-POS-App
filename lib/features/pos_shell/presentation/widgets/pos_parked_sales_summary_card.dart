import 'package:flutter/material.dart';

import '../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';
import '../../domain/entities/pos_home_action.dart';
import 'pos_home_action_card.dart';

class PosParkedSalesSummaryCard extends StatelessWidget {
  const PosParkedSalesSummaryCard({
    super.key,
    required this.action,
    this.onViewParkedSales,
  });

  final PosHomeAction action;
  final VoidCallback? onViewParkedSales;

  @override
  Widget build(BuildContext context) {
    return PosHomeActionCard(
      action: action,
      icon: Icons.pause_circle_outline_rounded,
      description: 'Retrieve and continue parked sales.',
      metrics: const [
        PosActionMetricLine(value: '7', label: 'Parked Sales Today'),
        PosActionMetricLine(
          value: '2',
          label: 'Older than 30 mins',
          color: TenantAdminColors.warning,
        ),
      ],
      onTap: action.routeExists ? onViewParkedSales : null,
    );
  }
}

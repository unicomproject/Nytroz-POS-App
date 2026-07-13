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
      iconColor: TenantAdminColors.info,
      iconBackgroundColor: const Color(0xFFE8F1FF),
      onTap: action.routeExists ? onViewReturns : null,
    );
  }
}

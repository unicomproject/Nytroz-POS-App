import 'package:flutter/material.dart';

import '../../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';
import '../../../domain/entities/pos_home_action.dart';
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
      iconColor: TenantAdminColors.pending,
      iconBackgroundColor: const Color(0xFFF3E8FF),
      onTap: action.routeExists ? onViewCashDrawer : null,
    );
  }
}

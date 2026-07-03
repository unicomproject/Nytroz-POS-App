import 'package:flutter/material.dart';

import '../../../domain/entities/pos_home_action.dart';
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
      onTap: action.routeExists ? onViewParkedSales : null,
    );
  }
}

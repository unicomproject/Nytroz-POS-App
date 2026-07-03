import 'package:flutter/material.dart';

import '../../../domain/entities/pos_home_action.dart';
import 'pos_home_action_card.dart';

class PosCustomerSummaryCard extends StatelessWidget {
  const PosCustomerSummaryCard({
    super.key,
    required this.action,
    this.onAddCustomer,
  });

  final PosHomeAction action;
  final VoidCallback? onAddCustomer;

  @override
  Widget build(BuildContext context) {
    return PosHomeActionCard(
      action: action,
      icon: Icons.person_add_alt_1_outlined,
      description: 'Create new customer profiles and manage details.',
      onTap: action.routeExists ? onAddCustomer : null,
    );
  }
}

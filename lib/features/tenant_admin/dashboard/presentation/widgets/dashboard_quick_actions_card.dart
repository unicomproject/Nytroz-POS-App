import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../domain/entities/tenant_dashboard.dart';
import '../../../presentation/theme/tenant_admin_theme.dart';
import '../../../presentation/widgets/tenant_admin_quick_action_card.dart';

class DashboardQuickActionsCard extends StatelessWidget {
  const DashboardQuickActionsCard({
    super.key,
    required this.actions,
  });

  final List<TenantDashboardQuickAction> actions;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: TenantAdminColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: TenantAdminColors.border),
        boxShadow: TenantAdminShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Quick actions',
              style: TenantAdminTextStyles.sectionTitle(context)),
          const SizedBox(height: 14),
          if (actions.isEmpty)
            Text(
              'No quick actions available.',
              style: TenantAdminTextStyles.muted(context),
            )
          else
            for (var index = 0; index < actions.length; index++) ...[
              TenantAdminQuickActionCard(
                title: actions[index].title,
                subtitle: actions[index].subtitle,
                icon: _iconFor(actions[index].iconKey ?? actions[index].key),
                onTap: () => context.go(actions[index].route),
              ),
              if (index != actions.length - 1) const SizedBox(height: 10),
            ],
        ],
      ),
    );
  }
}

IconData _iconFor(String key) {
  switch (key) {
    case 'add_outlet':
    case 'outlet':
      return Icons.store;
    case 'add_till':
    case 'till':
      return Icons.payment;
    case 'add_staff':
    case 'staff':
      return Icons.people;
    case 'add_product':
    case 'product':
      return Icons.add_box;
    default:
      return Icons.flash_on;
  }
}

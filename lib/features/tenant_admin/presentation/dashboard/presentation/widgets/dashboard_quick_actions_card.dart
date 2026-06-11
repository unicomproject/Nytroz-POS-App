import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../domain/entities/tenant_dashboard.dart';
import '../../../theme/tenant_admin_theme.dart';
import '../../../widgets/tenant_admin_quick_action_card.dart';
import '../../../widgets/tenant_admin_states.dart';

class DashboardQuickActionsCard extends StatelessWidget {
  const DashboardQuickActionsCard({
    super.key,
    required this.actions,
  });

  final List<TenantDashboardQuickAction> actions;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(TenantAdminSpacing.xl),
      decoration: BoxDecoration(
        color: TenantAdminColors.surface,
        borderRadius: BorderRadius.circular(TenantAdminRadius.lg),
        border: Border.all(color: TenantAdminColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Quick actions', style: TenantAdminTextStyles.sectionTitle(context)),
          const SizedBox(height: TenantAdminSpacing.lg),
          if (actions.isEmpty)
            const TenantAdminEmptyState(
              title: 'No quick actions',
              message: 'Allowed quick actions will appear here.',
            )
          else
            for (var index = 0; index < actions.length; index++) ...[
              TenantAdminQuickActionCard(
                title: actions[index].title,
                subtitle: actions[index].subtitle,
                icon: _iconFor(actions[index].iconKey ?? actions[index].key),
                onTap: () => context.go(actions[index].route),
              ),
              if (index != actions.length - 1)
                const SizedBox(height: TenantAdminSpacing.md),
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

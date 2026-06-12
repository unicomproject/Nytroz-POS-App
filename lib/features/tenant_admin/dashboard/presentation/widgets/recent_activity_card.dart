import 'package:flutter/material.dart';

import '../../domain/entities/tenant_dashboard.dart';
import '../../../presentation/theme/tenant_admin_theme.dart';
import '../../../presentation/widgets/tenant_admin_activity_item.dart';
import '../../../presentation/widgets/tenant_admin_states.dart';

class RecentActivityCard extends StatelessWidget {
  const RecentActivityCard({
    super.key,
    required this.items,
  });

  final List<TenantDashboardActivity> items;

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
          Text('Recent activity',
              style: TenantAdminTextStyles.sectionTitle(context)),
          const SizedBox(height: TenantAdminSpacing.lg),
          if (items.isEmpty)
            const TenantAdminEmptyState(
              title: 'No recent activity',
              message: 'Tenant activity will appear here.',
            )
          else
            for (var index = 0; index < items.length; index++) ...[
              TenantAdminActivityItem(
                title: items[index].title,
                subtitle: items[index].subtitle,
                timeLabel: items[index].timeLabel,
                icon: _iconFor(items[index].iconKey),
              ),
              if (index != items.length - 1)
                const SizedBox(height: TenantAdminSpacing.lg),
            ],
        ],
      ),
    );
  }
}

IconData _iconFor(String? iconKey) {
  switch (iconKey) {
    case 'staff':
      return Icons.people;
    case 'product':
      return Icons.list;
    case 'stock':
      return Icons.storage;
    case 'billing':
      return Icons.receipt;
    default:
      return Icons.history;
  }
}

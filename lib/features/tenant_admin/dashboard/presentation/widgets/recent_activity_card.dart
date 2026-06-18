import 'package:flutter/material.dart';

import 'package:go_router/go_router.dart';

import '../../domain/entities/tenant_dashboard.dart';
import '../../../presentation/theme/tenant_admin_theme.dart';
import '../../../presentation/widgets/tenant_admin_activity_item.dart';

class RecentActivityCard extends StatelessWidget {
  const RecentActivityCard({
    super.key,
    required this.items,
    this.showViewAll = false,
  });

  final List<TenantDashboardActivity> items;
  final bool showViewAll;

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
          Row(
            children: [
              Expanded(
                child: Text(
                  'Recent activity',
                  style: TenantAdminTextStyles.sectionTitle(context),
                ),
              ),
              if (showViewAll)
                TextButton(
                  onPressed: () => context.go('/tenant-admin/activity'),
                  child: const Text('View all activity'),
                ),
            ],
          ),
          const SizedBox(height: TenantAdminSpacing.lg),
          if (items.isEmpty)
            Text(
              'No recent activity yet.',
              style: TenantAdminTextStyles.muted(context),
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

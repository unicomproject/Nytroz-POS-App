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
          const SizedBox(height: 14),
          if (items.isEmpty)
            Text(
              'No recent activity yet.',
              style: TenantAdminTextStyles.muted(context),
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final stackItems = constraints.maxWidth < 760;
                final visibleItems = items.take(3).toList(growable: false);

                if (stackItems) {
                  return Column(
                    children: [
                      for (var index = 0;
                          index < visibleItems.length;
                          index++) ...[
                        TenantAdminActivityItem(
                          title: visibleItems[index].title,
                          subtitle: visibleItems[index].subtitle,
                          timeLabel: visibleItems[index].timeLabel,
                          icon: _iconFor(visibleItems[index].iconKey),
                        ),
                        if (index != visibleItems.length - 1)
                          const SizedBox(height: TenantAdminSpacing.lg),
                      ],
                    ],
                  );
                }

                return Row(
                  children: [
                    for (var index = 0;
                        index < visibleItems.length;
                        index++) ...[
                      Expanded(
                        child: TenantAdminActivityItem(
                          title: visibleItems[index].title,
                          subtitle: visibleItems[index].subtitle,
                          timeLabel: visibleItems[index].timeLabel,
                          icon: _iconFor(visibleItems[index].iconKey),
                        ),
                      ),
                      if (index != visibleItems.length - 1)
                        const SizedBox(width: TenantAdminSpacing.lg),
                    ],
                  ],
                );
              },
            ),
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

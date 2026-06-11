import 'package:flutter/material.dart';

import '../../domain/entities/outlet.dart';
import '../../../widgets/tenant_admin_metric_card.dart';
import '../../../widgets/tenant_admin_status_badge.dart';

class OutletMetricCards extends StatelessWidget {
  const OutletMetricCards({
    super.key,
    required this.summary,
    required this.compact,
  });

  final OutletListSummary summary;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final cards = [
      TenantAdminMetricCard(
        title: 'Total Outlets',
        value: '${summary.totalOutlets}',
        subtitle: '${summary.activeOutlets} Active • ${summary.inactiveOutlets} Inactive',
        icon: Icons.store,
      ),
      TenantAdminMetricCard(
        title: 'Active Outlets',
        value: '${summary.activeOutlets}',
        subtitle: '${_percent(summary.activeOutlets, summary.totalOutlets)}% of total',
        icon: Icons.check_circle,
        status: TenantAdminStatusType.active,
      ),
      TenantAdminMetricCard(
        title: 'Inactive Outlets',
        value: '${summary.inactiveOutlets}',
        subtitle: '${_percent(summary.inactiveOutlets, summary.totalOutlets)}% of total',
        icon: Icons.pause_circle_filled,
        status: TenantAdminStatusType.inactive,
      ),
      TenantAdminMetricCard(
        title: 'Total Locations',
        value: '${summary.totalLocations}',
        subtitle: 'Across all outlets',
        icon: Icons.location_on,
      ),
    ];

    return GridView.count(
      crossAxisCount: compact ? 2 : 4,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: compact ? 1.05 : 1.55,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: cards,
    );
  }
}

int _percent(int value, int total) {
  if (total <= 0) {
    return 0;
  }

  return ((value / total) * 100).round();
}

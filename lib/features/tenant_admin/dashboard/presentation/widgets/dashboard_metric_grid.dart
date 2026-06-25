import 'package:flutter/material.dart';

import '../../domain/entities/tenant_dashboard.dart';
import '../../../presentation/widgets/tenant_admin_metric_card.dart';
import '../../../presentation/widgets/tenant_admin_status_badge.dart';

class DashboardMetricGrid extends StatelessWidget {
  const DashboardMetricGrid({
    super.key,
    required this.metrics,
    required this.compact,
  });

  final List<TenantDashboardMetric> metrics;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (metrics.isEmpty) {
      return const SizedBox.shrink();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxColumns = compact
            ? 2
            : constraints.maxWidth >= 1080
                ? 4
                : constraints.maxWidth >= 520
                    ? 2
                    : 1;
        final crossAxisCount =
            metrics.length < maxColumns ? metrics.length : maxColumns;
        final childAspectRatio = crossAxisCount == 1
            ? 2.9
            : compact
                ? 1.45
                : crossAxisCount == 4
                    ? 1.65
                    : 2.45;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: metrics.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            childAspectRatio: childAspectRatio,
          ),
          itemBuilder: (context, index) {
            final metric = metrics[index];

            return TenantAdminMetricCard(
              title: metric.title,
              value: metric.value,
              subtitle: metric.subtitle,
              icon: _metricIcon(metric.iconKey ?? metric.key),
              trend: metric.trend,
              status: _statusType(metric.status),
            );
          },
        );
      },
    );
  }
}

IconData _metricIcon(String key) {
  switch (key) {
    case 'sales':
    case 'todays_sales':
      return Icons.payments;
    case 'orders':
      return Icons.shopping_cart;
    case 'outlets':
    case 'active_outlets':
      return Icons.store;
    case 'stock':
    case 'stock_alerts':
      return Icons.warning;
    default:
      return Icons.insert_chart;
  }
}

TenantAdminStatusType? _statusType(String? status) {
  switch (status) {
    case 'active':
      return TenantAdminStatusType.active;
    case 'inactive':
      return TenantAdminStatusType.inactive;
    case 'online':
      return TenantAdminStatusType.online;
    case 'offline':
      return TenantAdminStatusType.offline;
    case 'pending':
      return TenantAdminStatusType.pending;
    case 'warning':
      return TenantAdminStatusType.warning;
    case 'danger':
      return TenantAdminStatusType.danger;
    case 'success':
      return TenantAdminStatusType.success;
    default:
      return null;
  }
}

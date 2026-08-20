import 'package:flutter/material.dart';

import '../../../presentation/theme/tenant_admin_theme.dart';
import '../../domain/entities/tenant_dashboard.dart';

class DashboardMetricGrid extends StatelessWidget {
  const DashboardMetricGrid({
    super.key,
    required this.metrics,
    required this.compact,
    this.cardHeight,
    this.spacing,
  });

  final List<TenantDashboardMetric> metrics;
  final bool compact;
  final double? cardHeight;
  final double? spacing;

  @override
  Widget build(BuildContext context) {
    if (metrics.isEmpty) {
      return const SizedBox.shrink();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxColumns = compact
            ? constraints.maxWidth >= 520
                ? 2
                : 1
            : constraints.maxWidth >= 900
                ? 4
                : constraints.maxWidth >= 520
                    ? 2
                    : 1;
        final crossAxisCount =
            metrics.length < maxColumns ? metrics.length : maxColumns;
        final resolvedSpacing = spacing ?? (compact ? 12.0 : 16.0);

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: metrics.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: resolvedSpacing,
            mainAxisSpacing: resolvedSpacing,
            mainAxisExtent: cardHeight ?? (compact ? 142 : 150),
          ),
          itemBuilder: (context, index) {
            return _NewDashboardMetricCard(
              metric: metrics[index],
              compact: compact,
            );
          },
        );
      },
    );
  }
}

class _NewDashboardMetricCard extends StatelessWidget {
  const _NewDashboardMetricCard({
    required this.metric,
    this.compact = false,
  });

  final TenantDashboardMetric metric;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final (icon, color) = _getMetricConfig(metric.key);

    // Parse trend logic
    final isUp = metric.trend?.contains('+') == true ||
        metric.trend?.contains('↑') == true ||
        (metric.trend != null &&
            !metric.trend!.contains('-') &&
            metric.trend!.contains('%'));
    final trendColor = metric.trend == null
        ? Colors.transparent
        : (isUp ? TenantAdminColors.success : TenantAdminColors.danger);

    return Container(
      padding: EdgeInsets.all(compact ? 12 : 14),
      decoration: BoxDecoration(
        color: TenantAdminColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: TenantAdminColors.border),
        boxShadow: TenantAdminShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: compact ? 36 : 42,
                  height: compact ? 36 : 42,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: Colors.white, size: compact ? 18 : 22),
                ),
                SizedBox(width: compact ? 10 : 14),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          metric.title.toUpperCase(),
                          style: const TextStyle(
                            color: TenantAdminColors.navy,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            metric.value,
                            style: TextStyle(
                              color: TenantAdminColors.navy,
                              fontSize: compact ? 18 : 22,
                              fontWeight: FontWeight.w800,
                            ),
                            maxLines: 1,
                          ),
                        ),
                        const SizedBox(height: 4),
                        if (metric.trend != null)
                          Row(
                            children: [
                              Icon(isUp ? Icons.arrow_upward : Icons.arrow_downward,
                                  color: trendColor, size: 14),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  metric.trend!,
                                  style: TextStyle(
                                    color: trendColor,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          )
                        else if (metric.status != null || metric.subtitle != null)
                          Row(
                            children: [
                              if (metric.status != null) ...[
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: const BoxDecoration(
                                    color: TenantAdminColors.success,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                              ],
                              Expanded(
                                child: Text(
                                  (metric.status ?? metric.subtitle)!,
                                  style: const TextStyle(
                                    color: TenantAdminColors.success,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          SizedBox(height: compact ? 8 : 10),
          Text(
            'View ${metric.title.replaceAll("TODAY'S ", "")} >',
            style: const TextStyle(
              color: TenantAdminColors.posHomeAccentOrange,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  (IconData, Color) _getMetricConfig(String key) {
    switch (key) {
      case 'sales':
      case 'todays_sales':
        return (
          Icons.shopping_bag_outlined,
          TenantAdminColors.posHomeAccentOrange
        );
      case 'orders':
        return (Icons.shopping_cart_outlined, const Color(0xFF3B82F6));
      case 'outlets':
      case 'active_outlets':
        return (Icons.storefront_outlined, const Color(0xFF10B981));
      case 'tills':
      case 'active_tills':
      case 'stock':
        return (Icons.point_of_sale, const Color(0xFF8B5CF6));
      default:
        return (Icons.insert_chart, const Color(0xFF64748B));
    }
  }
}

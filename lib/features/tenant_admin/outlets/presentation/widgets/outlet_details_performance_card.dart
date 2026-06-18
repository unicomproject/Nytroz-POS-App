import 'package:flutter/material.dart';

import '../../domain/entities/outlet_details.dart';
import '../../../presentation/theme/tenant_admin_theme.dart';
import '../../../presentation/widgets/tenant_admin_states.dart';
import 'outlet_details_section_card.dart';

class OutletDetailsPerformanceCard extends StatelessWidget {
  const OutletDetailsPerformanceCard({
    super.key,
    required this.outlet,
  });

  final OutletDetails outlet;

  @override
  Widget build(BuildContext context) {
    return OutletDetailsSectionCard(
      title: 'Performance',
      trailing: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: TenantAdminSpacing.md,
          vertical: TenantAdminSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: TenantAdminColors.secondary,
          borderRadius: BorderRadius.circular(TenantAdminRadius.md),
          border: Border.all(color: TenantAdminColors.border),
        ),
        child: const Text(
          'This week',
          style: TextStyle(
            color: TenantAdminColors.bodyText,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
      child: outlet.performancePoints.isEmpty
          ? const TenantAdminEmptyState(
              title: 'No sales data',
              message:
                  'Performance chart will appear when sales data is available.',
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (outlet.weekSalesDisplay != null)
                  Text(
                    outlet.weekSalesDisplay!,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: TenantAdminColors.bodyText,
                        ),
                  )
                else if (outlet.todaySalesDisplay != null)
                  Text(
                    outlet.todaySalesDisplay!,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: TenantAdminColors.bodyText,
                        ),
                  ),
                const SizedBox(height: TenantAdminSpacing.lg),
                _PerformanceChart(points: outlet.performancePoints),
              ],
            ),
    );
  }
}

class _PerformanceChart extends StatelessWidget {
  const _PerformanceChart({
    required this.points,
  });

  final List<OutletPerformancePoint> points;

  @override
  Widget build(BuildContext context) {
    var maxValue = 0.0;

    for (final point in points) {
      if (point.value > maxValue) {
        maxValue = point.value;
      }
    }

    return SizedBox(
      height: 180,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (final point in points)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: FractionallySizedBox(
                          heightFactor:
                              maxValue <= 0 ? 0.04 : point.value / maxValue,
                          child: Container(
                            decoration: BoxDecoration(
                              color: TenantAdminColors.primary,
                              borderRadius: BorderRadius.circular(
                                TenantAdminRadius.sm,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: TenantAdminSpacing.sm),
                    Text(
                      point.label,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: TenantAdminColors.mutedText,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

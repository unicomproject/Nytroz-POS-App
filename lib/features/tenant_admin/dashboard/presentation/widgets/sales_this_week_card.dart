import 'package:flutter/material.dart';

import '../../domain/entities/tenant_dashboard.dart';
import '../../../presentation/theme/tenant_admin_theme.dart';
import '../../../presentation/widgets/tenant_admin_states.dart';

class SalesThisWeekCard extends StatelessWidget {
  const SalesThisWeekCard({
    super.key,
    required this.salesSummary,
  });

  final TenantDashboardSalesSummary? salesSummary;

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
          Text(
            salesSummary?.title ?? 'Sales this week',
            style: TenantAdminTextStyles.sectionTitle(context),
          ),
          const SizedBox(height: TenantAdminSpacing.xs),
          Text(
            salesSummary?.subtitle ?? 'Weekly sales performance',
            style: TenantAdminTextStyles.muted(context),
          ),
          const SizedBox(height: TenantAdminSpacing.lg),
          if (salesSummary == null || salesSummary!.points.isEmpty)
            const TenantAdminEmptyState(
              title: 'No sales data',
              message: 'Sales data will appear here when available.',
            )
          else ...[
            Text(
              salesSummary!.total,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: TenantAdminColors.bodyText,
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: TenantAdminSpacing.lg),
            _SimpleBarChart(points: salesSummary!.points),
          ],
        ],
      ),
    );
  }
}

class _SimpleBarChart extends StatelessWidget {
  const _SimpleBarChart({
    required this.points,
  });

  final List<TenantDashboardChartPoint> points;

  @override
  Widget build(BuildContext context) {
    var maxValue = 0.0;

    for (final point in points) {
      if (point.value > maxValue) {
        maxValue = point.value;
      }
    }

    return SizedBox(
      height: 160,
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
                              maxValue <= 0 ? 0.02 : point.value / maxValue,
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

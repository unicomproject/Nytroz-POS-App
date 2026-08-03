import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../domain/services/tenant_admin_access_checker.dart';
import '../../../presentation/theme/tenant_admin_theme.dart';
import '../../../presentation/widgets/tenant_admin_states.dart';
import '../../domain/entities/product_dashboard.dart';
import 'product_dashboard_navigation.dart';
import 'widgets/simple_donut_chart.dart';

class ProductStockMovementCard extends StatelessWidget {
  const ProductStockMovementCard({
    super.key,
    required this.stockMovement,
    required this.dateLabel,
    this.access,
  });

  final ProductDashboardStockMovement stockMovement;
  final String dateLabel;
  final TenantAdminAccessChecker? access;

  static const _segmentColors = [
    Color(0xFF2563EB),
    Color(0xFF7C3AED),
    Color(0xFF059669),
    Color(0xFFF59E0B),
  ];

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
          Text(
            'Stock Movement',
            style: TenantAdminTextStyles.sectionTitle(context),
          ),
          const SizedBox(height: 6),
          Text(
            '$dateLabel · ${stockMovement.totalCount} total movements',
            style: TenantAdminTextStyles.muted(context).copyWith(fontSize: 12),
          ),
          const SizedBox(height: 16),
          if (stockMovement.items.isEmpty || stockMovement.totalCount == 0)
            const TenantAdminEmptyState(
              title: 'No stock movements',
              message: 'No stock movements were recorded for this period.',
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final isNarrow = constraints.maxWidth < 560;

                final chart = Center(
                  child: SimpleDonutChart(
                    segments: [
                      for (var index = 0;
                          index < stockMovement.items.length;
                          index++)
                        SimpleDonutSegment(
                          value: stockMovement.items[index].percentage,
                          color: _segmentColors[index % _segmentColors.length],
                          label: stockMovement.items[index].label,
                        ),
                    ],
                  ),
                );

                final legend = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (var index = 0;
                        index < stockMovement.items.length;
                        index++)
                      _MovementLegendRow(
                        color: _segmentColors[index % _segmentColors.length],
                        item: stockMovement.items[index],
                        canNavigate: access != null &&
                            ProductDashboardNavigation.canNavigateMovement(
                              access!,
                              stockMovement.items[index].type,
                            ),
                        onTap: () {
                          final route =
                              ProductDashboardNavigation.movementRouteFor(
                            stockMovement.items[index].type,
                          );
                          if (route != null) {
                            context.go(route);
                          }
                        },
                      ),
                  ],
                );

                if (isNarrow) {
                  return Column(
                    children: [
                      chart,
                      const SizedBox(height: TenantAdminSpacing.lg),
                      legend,
                    ],
                  );
                }

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    chart,
                    const SizedBox(width: TenantAdminSpacing.xl),
                    Expanded(child: legend),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }
}

class _MovementLegendRow extends StatelessWidget {
  const _MovementLegendRow({
    required this.color,
    required this.item,
    required this.canNavigate,
    required this.onTap,
  });

  final Color color;
  final ProductDashboardMovementItem item;
  final bool canNavigate;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final content = Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: TenantAdminSpacing.sm),
        Expanded(
          child: Text(
            item.label,
            style: const TextStyle(
              color: TenantAdminColors.bodyText,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Text(
          '${item.count}',
          style: TenantAdminTextStyles.muted(context).copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(width: TenantAdminSpacing.sm),
        SizedBox(
          width: 44,
          child: Text(
            '${item.percentage.toStringAsFixed(1)}%',
            textAlign: TextAlign.right,
            style: const TextStyle(
              color: TenantAdminColors.bodyText,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        if (canNavigate) ...[
          const SizedBox(width: 4),
          const Icon(
            Icons.chevron_right,
            size: 16,
            color: TenantAdminColors.mutedText,
          ),
        ],
      ],
    );

    if (!canNavigate) {
      return Padding(
        padding: const EdgeInsets.only(bottom: TenantAdminSpacing.sm),
        child: content,
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: TenantAdminSpacing.sm),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: content,
          ),
        ),
      ),
    );
  }
}

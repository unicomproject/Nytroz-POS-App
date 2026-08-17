import 'package:flutter/material.dart';
import '../../../domain/entities/current_stock_entities.dart';
import '../../../../presentation/theme/tenant_admin_theme.dart';
import '../../../../presentation/widgets/tenant_admin_metric_card.dart';
import '../../../../presentation/widgets/tenant_admin_status_badge.dart';

class CurrentStockSummaryCards extends StatelessWidget {
  const CurrentStockSummaryCards({
    super.key,
    required this.summary,
  });

  final CurrentStockSummary summary;

  @override
  Widget build(BuildContext context) {
    final cards = [
      TenantAdminMetricCard(
        title: 'On Hand',
        value: summary.totalUnits.toString(),
        icon: Icons.inventory_2_outlined,
        status: TenantAdminStatusType.online,
        subtitle: 'Total stock in hand',
      ),
      TenantAdminMetricCard(
        title: 'Available',
        value: summary.totalItemsInStock.toString(),
        icon: Icons.check_circle_outline,
        status: TenantAdminStatusType.success,
        subtitle: 'Ready to sell',
      ),
      TenantAdminMetricCard(
        title: 'Low Stock',
        value: summary.lowStockCount.toString(),
        icon: Icons.error_outline,
        status: TenantAdminStatusType.warning,
        subtitle: 'Reorder soon',
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        if (width < 600) {
          return Column(
            children: cards
                .map((c) => Padding(
                      padding:
                          const EdgeInsets.only(bottom: TenantAdminSpacing.md),
                      child: c,
                    ))
                .toList(),
          );
        }

        return Row(
          children: [
            for (var i = 0; i < cards.length; i++) ...[
              if (i > 0) const SizedBox(width: TenantAdminSpacing.lg),
              Expanded(child: cards[i]),
            ],
          ],
        );
      },
    );
  }
}

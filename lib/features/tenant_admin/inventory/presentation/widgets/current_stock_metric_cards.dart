import 'package:flutter/material.dart';

import '../../domain/entities/inventory.dart';
import '../../../presentation/theme/tenant_admin_theme.dart';
import '../../../presentation/widgets/tenant_admin_metric_card.dart';
import '../../../presentation/widgets/tenant_admin_status_badge.dart';
import '../utils/inventory_api_errors.dart';

class CurrentStockMetricCards extends StatelessWidget {
  const CurrentStockMetricCards({
    super.key,
    required this.summary,
    required this.compact,
    required this.showLowStockCount,
  });

  final InventoryBalanceSummary summary;
  final bool compact;
  final bool showLowStockCount;

  @override
  Widget build(BuildContext context) {
    final cards = <Widget>[
      TenantAdminMetricCard(
        title: 'On Hand',
        value: formatInventoryQuantity(summary.onHand),
        icon: Icons.inventory_2_outlined,
        dense: true,
      ),
      TenantAdminMetricCard(
        title: 'Reserved',
        value: formatInventoryQuantity(summary.reserved),
        icon: Icons.lock_clock_outlined,
        dense: true,
      ),
      TenantAdminMetricCard(
        title: 'Available',
        value: formatInventoryQuantity(
          summary.available ??
              ((summary.onHand ?? 0) - (summary.reserved ?? 0)),
        ),
        icon: Icons.check_circle_outline,
        dense: true,
      ),
      if (showLowStockCount)
        TenantAdminMetricCard(
          title: 'Low Stock Items',
          value: summary.lowStockItems?.toString() ?? '—',
          icon: Icons.warning_amber_outlined,
          status: TenantAdminStatusType.warning,
          dense: true,
        ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = compact
            ? cards.length <= 2
                ? cards.length
                : 2
            : cards.length <= 4
                ? cards.length
                : 4;

        final availableWidth = constraints.maxWidth;
        final cardWidth = (availableWidth -
                (crossAxisCount - 1) * TenantAdminSpacing.lg) /
            crossAxisCount;
        final cardHeight = compact ? 156.0 : 148.0;
        final aspectRatio = cardWidth / cardHeight;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: TenantAdminSpacing.lg,
            mainAxisSpacing: TenantAdminSpacing.lg,
            childAspectRatio: aspectRatio.clamp(1.0, 3.5),
          ),
          itemCount: cards.length,
          itemBuilder: (context, index) => cards[index],
        );
      },
    );
  }
}

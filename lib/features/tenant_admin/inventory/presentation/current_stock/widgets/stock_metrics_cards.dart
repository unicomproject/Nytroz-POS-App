import 'package:flutter/material.dart';

import '../../../../presentation/theme/tenant_admin_theme.dart';
import '../../../../presentation/widgets/tenant_admin_metric_card.dart';
import '../../../../presentation/widgets/tenant_admin_status_badge.dart';
import '../../../domain/entities/current_stock_entities.dart';

/// A horizontal row of 4 metric cards: On Hand, Reserved, Available, Reorder Level.
class StockMetricsCards extends StatelessWidget {
  const StockMetricsCards({
    super.key,
    required this.detail,
    this.outletLabel = 'Across all outlets',
  });

  final ProductStockDetail detail;

  /// Sub-label shown under each metric value.
  final String outletLabel;

  @override
  Widget build(BuildContext context) {
    final cards = [
      TenantAdminMetricCard(
        title: 'On Hand',
        value: detail.totalOnHand.toStringAsFixed(0),
        icon: Icons.view_in_ar_outlined,
        status: TenantAdminStatusType.online,
        subtitle: outletLabel,
      ),
      TenantAdminMetricCard(
        title: 'Reserved',
        value: detail.totalReserved.toStringAsFixed(0),
        icon: Icons.bookmark_outline,
        status: TenantAdminStatusType.warning,
        subtitle: outletLabel,
      ),
      TenantAdminMetricCard(
        title: 'Available',
        value: detail.totalAvailable.toStringAsFixed(0),
        icon: Icons.check_circle_outline,
        status: TenantAdminStatusType.success,
        subtitle: outletLabel,
      ),
      TenantAdminMetricCard(
        title: 'Reorder Level',
        value: detail.totalReorderLevel.toStringAsFixed(0),
        icon: Icons.notifications_outlined,
        subtitle: 'Set threshold',
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

        if (width < 1100) {
          return Column(
            children: [
              Row(
                children: [
                  Expanded(child: cards[0]),
                  const SizedBox(width: TenantAdminSpacing.md),
                  Expanded(child: cards[1]),
                ],
              ),
              const SizedBox(height: TenantAdminSpacing.md),
              Row(
                children: [
                  Expanded(child: cards[2]),
                  const SizedBox(width: TenantAdminSpacing.md),
                  Expanded(child: cards[3]),
                ],
              ),
            ],
          );
        }

        return Row(
          children: [
            Expanded(child: cards[0]),
            const SizedBox(width: TenantAdminSpacing.md),
            Expanded(child: cards[1]),
            const SizedBox(width: TenantAdminSpacing.md),
            Expanded(child: cards[2]),
            const SizedBox(width: TenantAdminSpacing.md),
            Expanded(child: cards[3]),
          ],
        );
      },
    );
  }
}

import 'package:flutter/material.dart';

import '../../../../presentation/theme/tenant_admin_theme.dart';
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
      _MetricCard(
        icon: Icons.view_in_ar_outlined,
        iconColor: const Color(0xFF3B82F6), // Blue
        iconBg: const Color(0xFFEFF6FF), // Light Blue
        label: 'On Hand',
        value: detail.totalOnHand.toStringAsFixed(0),
        subLabel: outletLabel,
      ),
      _MetricCard(
        icon: Icons.bookmark_outline,
        iconColor: const Color(0xFFF97316), // Orange
        iconBg: const Color(0xFFFFF7ED), // Light Orange
        label: 'Reserved',
        value: detail.totalReserved.toStringAsFixed(0),
        subLabel: outletLabel,
      ),
      _MetricCard(
        icon: Icons.check_circle_outline,
        iconColor: const Color(0xFF22C55E), // Green
        iconBg: const Color(0xFFDCFCE7), // Light Green
        label: 'Available',
        value: detail.totalAvailable.toStringAsFixed(0),
        subLabel: outletLabel,
      ),
      _MetricCard(
        icon: Icons.notifications_outlined,
        iconColor: const Color(0xFFA855F7), // Purple
        iconBg: const Color(0xFFF3E8FF), // Light Purple
        label: 'Reorder Level',
        value: detail.totalReorderLevel.toStringAsFixed(0),
        subLabel: 'Set threshold',
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        if (width < 600) {
          return Column(
            children: cards.map((c) => Padding(
              padding: const EdgeInsets.only(bottom: TenantAdminSpacing.md),
              child: c,
            )).toList(),
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

/// A single stock metric card with an icon, a large number, and a sub-label.
class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.label,
    required this.value,
    required this.subLabel,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String label;
  final String value;
  final String subLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: TenantAdminColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF334155))), // Slate 700
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      height: 1.1,
                      color: Color(0xFF0F172A)), // Slate 900
                ),
                const SizedBox(height: 4),
                Text(subLabel,
                    style: const TextStyle(
                        fontSize: 12, color: Color(0xFF64748B))), // Slate 500
              ],
            ),
          ),
        ],
      ),
    );
  }
}

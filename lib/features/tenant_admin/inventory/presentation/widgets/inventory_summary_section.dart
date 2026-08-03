import 'package:flutter/material.dart';

import '../../domain/entities/inventory_entities.dart';
import '../../../presentation/theme/tenant_admin_theme.dart';

class InventorySummarySection extends StatelessWidget {
  const InventorySummarySection({
    super.key,
    required this.summary,
    required this.compact,
    required this.loading,
  });

  final CurrentStockSummary? summary;
  final bool compact;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return _SummarySkeleton(compact: compact);
    }

    if (summary == null) {
      return const SizedBox.shrink();
    }

    final cards = [
      _SummaryCardData(
        title: 'Total products',
        value: '${summary!.totalProducts}',
        icon: Icons.inventory_2_outlined,
        color: TenantAdminColors.info,
      ),
      _SummaryCardData(
        title: 'Total variants',
        value: '${summary!.totalVariants}',
        icon: Icons.style_outlined,
        color: TenantAdminColors.primary,
      ),
      _SummaryCardData(
        title: 'Total units',
        value: summary!.totalUnits.toStringAsFixed(
          summary!.totalUnits == summary!.totalUnits.roundToDouble() ? 0 : 2,
        ),
        icon: Icons.layers_outlined,
        color: TenantAdminColors.success,
      ),
      _SummaryCardData(
        title: 'Low stock',
        value: '${summary!.lowStockCount}',
        icon: Icons.warning_amber_outlined,
        color: TenantAdminColors.warning,
      ),
      _SummaryCardData(
        title: 'Out of stock',
        value: '${summary!.outOfStockCount}',
        icon: Icons.remove_circle_outline,
        color: TenantAdminColors.danger,
      ),
      _SummaryCardData(
        title: 'Expiring soon',
        value: '${summary!.expiringSoonCount}',
        icon: Icons.schedule_outlined,
        color: TenantAdminColors.pending,
      ),
    ];

    final crossAxisCount = compact
        ? 2
        : cards.length <= 3
            ? cards.length
            : 3;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: TenantAdminSpacing.lg,
        mainAxisSpacing: TenantAdminSpacing.lg,
        mainAxisExtent: compact ? 118 : 112,
      ),
      itemCount: cards.length,
      itemBuilder: (context, index) => _SummaryCard(data: cards[index]),
    );
  }
}

class _SummaryCardData {
  const _SummaryCardData({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.data});

  final _SummaryCardData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(TenantAdminSpacing.md),
      decoration: BoxDecoration(
        color: TenantAdminColors.surface,
        borderRadius: BorderRadius.circular(TenantAdminRadius.lg),
        border: Border.all(color: TenantAdminColors.border),
        boxShadow: TenantAdminShadows.card,
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: data.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(TenantAdminRadius.md),
            ),
            child: Icon(data.icon, color: data.color, size: 22),
          ),
          const SizedBox(width: TenantAdminSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  data.value,
                  style: const TextStyle(
                    color: TenantAdminColors.bodyText,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  data.title,
                  style: const TextStyle(
                    color: TenantAdminColors.mutedText,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SummarySkeleton extends StatelessWidget {
  const _SummarySkeleton({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final count = compact ? 4 : 6;
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: compact ? 2 : 3,
        crossAxisSpacing: TenantAdminSpacing.lg,
        mainAxisSpacing: TenantAdminSpacing.lg,
        mainAxisExtent: compact ? 118 : 112,
      ),
      itemCount: count,
      itemBuilder: (context, index) {
        return Container(
          decoration: BoxDecoration(
            color: TenantAdminColors.surface,
            borderRadius: BorderRadius.circular(TenantAdminRadius.lg),
            border: Border.all(color: TenantAdminColors.border),
          ),
          child: const Center(
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        );
      },
    );
  }
}

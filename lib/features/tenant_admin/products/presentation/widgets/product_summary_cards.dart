import 'package:flutter/material.dart';

import '../../domain/entities/tenant_product.dart';
import '../../../presentation/theme/tenant_admin_theme.dart';
import '../../../presentation/widgets/tenant_admin_metric_card.dart';
import '../../../presentation/widgets/tenant_admin_status_badge.dart';

class ProductSummaryCards extends StatelessWidget {
  const ProductSummaryCards({
    super.key,
    required this.summary,
    required this.compact,
  });

  final TenantProductSummary summary;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final cards = [
      _ProductSummaryCardData(
        title: 'Total Products',
        value: '${summary.totalProducts}',
        subtitle: 'Products in catalogue',
        icon: Icons.inventory_2_outlined,
        status: TenantAdminStatusType.active,
      ),
      _ProductSummaryCardData(
        title: 'Active Products',
        value: '${summary.activeProducts}',
        subtitle: 'Available for sale',
        icon: Icons.check_circle_outline,
        status: TenantAdminStatusType.success,
      ),
      _ProductSummaryCardData(
        title: 'Inactive Products',
        value: '${summary.inactiveProducts}',
        subtitle: 'Hidden from tills',
        icon: Icons.pause_circle_outline,
        status: TenantAdminStatusType.inactive,
      ),
      _ProductSummaryCardData(
        title: 'Categories',
        value: '${summary.categoryCount}',
        subtitle: 'Categories in use',
        icon: Icons.category_outlined,
        status: TenantAdminStatusType.warning,
      ),
    ];

    final crossAxisCount = compact
        ? cards.length == 1
            ? 1
            : 2
        : cards.length <= 4
            ? cards.length
            : 4;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: TenantAdminSpacing.lg,
        mainAxisSpacing: TenantAdminSpacing.lg,
        mainAxisExtent: compact ? 172 : 168,
      ),
      itemCount: cards.length,
      itemBuilder: (context, index) {
        final card = cards[index];
        return TenantAdminMetricCard(
          title: card.title,
          value: card.value,
          subtitle: card.subtitle,
          icon: card.icon,
          status: card.status,
          dense: true,
        );
      },
    );
  }
}

class ProductSummaryCardsSkeleton extends StatelessWidget {
  const ProductSummaryCardsSkeleton({super.key, required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final crossAxisCount = compact ? 2 : 4;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: TenantAdminSpacing.lg,
        mainAxisSpacing: TenantAdminSpacing.lg,
        mainAxisExtent: compact ? 172 : 168,
      ),
      itemCount: 4,
      itemBuilder: (context, index) => Container(
        decoration: BoxDecoration(
          color: TenantAdminColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: TenantAdminColors.border),
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: TenantAdminColors.background,
                borderRadius: BorderRadius.circular(11),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              width: 88,
              height: 10,
              decoration: BoxDecoration(
                color: TenantAdminColors.background,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: 48,
              height: 18,
              decoration: BoxDecoration(
                color: TenantAdminColors.background,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: 120,
              height: 10,
              decoration: BoxDecoration(
                color: TenantAdminColors.background,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductSummaryCardData {
  const _ProductSummaryCardData({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.status,
  });

  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final TenantAdminStatusType status;
}

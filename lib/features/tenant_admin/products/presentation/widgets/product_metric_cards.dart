import 'package:flutter/material.dart';

import '../../domain/entities/product.dart';
import '../../../presentation/theme/tenant_admin_theme.dart';
import '../../../presentation/widgets/tenant_admin_metric_card.dart';
import '../config/product_row_action_configs.dart';

class ProductMetricCards extends StatelessWidget {
  const ProductMetricCards({
    super.key,
    required this.summary,
    required this.compact,
    required this.cards,
  });

  final ProductListSummary summary;
  final bool compact;
  final List<ProductSummaryCardConfig> cards;

  @override
  Widget build(BuildContext context) {
    if (cards.isEmpty) {
      return const SizedBox.shrink();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = compact
            ? cards.length == 1
                ? 1
                : 2
            : cards.length <= 4
                ? cards.length
                : 4;

        // Calculate dynamic aspect ratio based on available width
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
          itemBuilder: (context, index) {
            final card = cards[index];
            return TenantAdminMetricCard(
              title: card.title,
              value: card.valueBuilder(summary),
              subtitle: card.subtitleBuilder(summary),
              icon: card.icon,
              dense: true,
            );
          },
        );
      },
    );
  }
}

import 'package:flutter/material.dart';

import '../../domain/entities/outlet.dart';
import '../../../presentation/theme/tenant_admin_theme.dart';
import '../../../presentation/widgets/tenant_admin_metric_card.dart';
import '../config/outlet_summary_card_configs.dart';

class OutletMetricCards extends StatelessWidget {
  const OutletMetricCards({
    super.key,
    required this.summary,
    required this.compact,
    required this.cards,
  });

  final OutletListSummary summary;
  final bool compact;
  final List<OutletSummaryCardConfig> cards;

  @override
  Widget build(BuildContext context) {
    if (cards.isEmpty) {
      return const SizedBox.shrink();
    }

    final crossAxisCount = compact
        ? cards.length == 1
            ? 1
            : 2
        : cards.length <= 2
            ? cards.length
            : cards.length == 3
                ? 3
                : 4;
    final cardHeight = compact ? 156.0 : 168.0;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: TenantAdminSpacing.lg,
        mainAxisSpacing: TenantAdminSpacing.lg,
        mainAxisExtent: cardHeight,
      ),
      itemCount: cards.length,
      itemBuilder: (context, index) {
        final card = cards[index];
        return TenantAdminMetricCard(
          title: card.title,
          value: card.valueBuilder(summary),
          subtitle: card.subtitleBuilder(summary),
          icon: card.icon,
          status: card.status,
          dense: true,
        );
      },
    );
  }
}

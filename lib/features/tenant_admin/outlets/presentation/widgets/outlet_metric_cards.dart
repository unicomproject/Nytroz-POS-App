import 'package:flutter/material.dart';

import '../../domain/entities/outlet.dart';
import '../../../presentation/widgets/tenant_admin_metric_card.dart';
import '../../../presentation/widgets/tenant_admin_status_badge.dart';
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

    return GridView.count(
      crossAxisCount: crossAxisCount,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: compact ? 1.3 : 1.55,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        for (final card in cards)
          TenantAdminMetricCard(
            title: card.title,
            value: card.valueBuilder(summary),
            subtitle: card.subtitleBuilder(summary),
            icon: card.icon,
            status: card.status,
          ),
      ],
    );
  }
}

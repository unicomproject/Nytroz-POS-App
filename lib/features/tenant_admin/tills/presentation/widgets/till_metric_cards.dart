import 'package:flutter/material.dart';

import '../../domain/entities/till.dart';
import '../../../presentation/theme/tenant_admin_theme.dart';
import '../../../presentation/widgets/tenant_admin_metric_card.dart';
import '../config/till_row_action_configs.dart';

class TillMetricCards extends StatelessWidget {
  const TillMetricCards({
    super.key,
    required this.summary,
    required this.compact,
    required this.cards,
  });

  final TillListSummary summary;
  final bool compact;
  final List<TillSummaryCardConfig> cards;

  @override
  Widget build(BuildContext context) {
    if (cards.isEmpty) {
      return const SizedBox.shrink();
    }

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

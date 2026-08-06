import 'package:flutter/material.dart';

import '../../domain/entities/outlet.dart';
import '../../../presentation/theme/tenant_admin_theme.dart';
import '../../../presentation/widgets/tenant_admin_status_badge.dart';
import '../config/outlet_summary_card_configs.dart';

class OutletMetricCards extends StatelessWidget {
  const OutletMetricCards({
    super.key,
    required this.summary,
    required this.compact,
    required this.cards,
  });

  final OutletSummaryDashboard summary;
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
    final cardHeight = compact ? 118.0 : 112.0;

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
        return _OutletSummaryCard(
          title: card.title,
          value: card.valueBuilder(summary),
          subtitle: card.subtitleBuilder(summary),
          icon: card.icon,
          status: card.status,
        );
      },
    );
  }
}

class _OutletSummaryCard extends StatelessWidget {
  const _OutletSummaryCard({
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
  final TenantAdminStatusType? status;

  @override
  Widget build(BuildContext context) {
    final accent = _accentColor(status);

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
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(TenantAdminRadius.md),
            ),
            child: Icon(icon, color: accent, size: 22),
          ),
          const SizedBox(width: TenantAdminSpacing.md),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TenantAdminTextStyles.muted(context).copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: TenantAdminSpacing.xs),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: TenantAdminColors.bodyText,
                        fontWeight: FontWeight.w800,
                        height: 1,
                      ),
                ),
                const SizedBox(height: TenantAdminSpacing.xs),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TenantAdminTextStyles.muted(context).copyWith(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
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

Color _accentColor(TenantAdminStatusType? status) {
  switch (status) {
    case TenantAdminStatusType.active:
    case TenantAdminStatusType.success:
    case TenantAdminStatusType.online:
      return TenantAdminColors.success;
    case TenantAdminStatusType.inactive:
    case TenantAdminStatusType.offline:
      return TenantAdminColors.danger;
    case TenantAdminStatusType.warning:
    case TenantAdminStatusType.pending:
      return TenantAdminColors.warning;
    case TenantAdminStatusType.danger:
      return TenantAdminColors.danger;
    case null:
      return TenantAdminColors.primary;
  }
}

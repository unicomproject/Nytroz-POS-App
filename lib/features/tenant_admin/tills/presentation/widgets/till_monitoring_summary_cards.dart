import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nytroz_pos/features/tenant_admin/presentation/theme/tenant_admin_theme.dart';
import '../providers/till_providers.dart';

class TillMonitoringSummaryCards extends ConsumerWidget {
  const TillMonitoringSummaryCards({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryState = ref.watch(tillSummaryFutureProvider);

    return summaryState.when(
      data: (summary) {
        if (summary == null) return const SizedBox.shrink();

        return LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth < 600;
            final isTablet = constraints.maxWidth < 900;
            final cards = [
              _buildCard(
                title: 'TOTAL TILLS',
                count: summary.totalTills,
                subtitle: 'All registered tills',
                icon: Icons.point_of_sale_rounded,
                iconBgColor: TenantAdminColors.posHomeAccentOrange
                    .withValues(alpha: 0.1),
                iconColor: TenantAdminColors.posHomeAccentOrange,
                subtitleColor: TenantAdminColors.mutedText,
              ),
              _buildCard(
                title: 'ONLINE',
                count: summary.onlineCount,
                subtitle:
                    '${summary.totalTills == 0 ? 0 : (summary.onlineCount / summary.totalTills * 100).round()}% of tills online',
                icon: Icons.wifi_rounded,
                iconBgColor: TenantAdminColors.success.withValues(alpha: 0.12),
                iconColor: TenantAdminColors.success,
                subtitleColor: TenantAdminColors.success,
              ),
              _buildCard(
                title: 'OFFLINE',
                count: summary.offlineCount,
                subtitle:
                    '${summary.totalTills == 0 ? 0 : (summary.offlineCount / summary.totalTills * 100).round()}% of tills offline',
                icon: Icons.wifi_off_rounded,
                iconBgColor: TenantAdminColors.danger.withValues(alpha: 0.10),
                iconColor: TenantAdminColors.danger,
                subtitleColor: TenantAdminColors.danger,
              ),
            ];

            if (isMobile) {
              return Column(
                children: cards
                    .map(
                      (card) => Padding(
                        padding: const EdgeInsets.only(
                          bottom: TenantAdminSpacing.md,
                        ),
                        child: card,
                      ),
                    )
                    .toList(growable: false),
              );
            }

            if (isTablet) {
              return Wrap(
                spacing: TenantAdminSpacing.md,
                runSpacing: TenantAdminSpacing.md,
                children: [
                  for (final card in cards)
                    SizedBox(
                      width: (constraints.maxWidth - TenantAdminSpacing.md) / 2,
                      child: card,
                    ),
                ],
              );
            }

            return Row(
              children: [
                Expanded(child: cards[0]),
                const SizedBox(width: TenantAdminSpacing.lg),
                Expanded(child: cards[1]),
                const SizedBox(width: TenantAdminSpacing.lg),
                Expanded(child: cards[2]),
              ],
            );
          },
        );
      },
      loading: () => const SizedBox(
          height: 100, child: Center(child: CircularProgressIndicator())),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildCard({
    required String title,
    required int count,
    required String subtitle,
    required IconData icon,
    required Color iconBgColor,
    required Color iconColor,
    required Color subtitleColor,
  }) {
    return Container(
      constraints: const BoxConstraints(minHeight: 104),
      padding: const EdgeInsets.symmetric(
        horizontal: TenantAdminSpacing.lg,
        vertical: TenantAdminSpacing.md,
      ),
      decoration: BoxDecoration(
        color: TenantAdminColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: TenantAdminColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: iconBgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: TenantAdminSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    color: TenantAdminColors.mutedText,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  count.toString(),
                  style: const TextStyle(
                    fontSize: 25,
                    color: TenantAdminColors.bodyText,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: subtitleColor,
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

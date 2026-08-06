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

            if (isMobile) {
              return Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                          child: _buildCard(
                        title: 'TOTAL TILLS',
                        count: summary.totalTills,
                        subtitle: 'All registered tills',
                        icon: Icons.point_of_sale,
                        iconBgColor: Colors.purple.shade50,
                        iconColor: Colors.purple,
                        subtitleColor: TenantAdminColors.mutedText,
                      )),
                    ],
                  ),
                  const SizedBox(height: TenantAdminSpacing.md),
                  Row(
                    children: [
                      Expanded(
                          child: _buildCard(
                        title: 'ONLINE',
                        count: summary.onlineCount,
                        subtitle:
                            '${summary.totalTills == 0 ? 0 : (summary.onlineCount / summary.totalTills * 100).round()}% online',
                        icon: Icons.wifi,
                        iconBgColor: Colors.green.shade50,
                        iconColor: Colors.green,
                        subtitleColor: Colors.green,
                      )),
                      const SizedBox(width: TenantAdminSpacing.md),
                      Expanded(
                          child: _buildCard(
                        title: 'OFFLINE',
                        count: summary.offlineCount,
                        subtitle:
                            '${summary.totalTills == 0 ? 0 : (summary.offlineCount / summary.totalTills * 100).round()}% offline',
                        icon: Icons.wifi_off,
                        iconBgColor: Colors.red.shade50,
                        iconColor: Colors.red,
                        subtitleColor: Colors.red,
                      )),
                    ],
                  ),
                ],
              );
            }

            return Row(
              children: [
                Expanded(
                    child: _buildCard(
                  title: 'TOTAL TILLS',
                  count: summary.totalTills,
                  subtitle: 'All registered tills',
                  icon: Icons.point_of_sale,
                  iconBgColor: Colors.purple.shade50,
                  iconColor: Colors.purple,
                  subtitleColor: TenantAdminColors.mutedText,
                )),
                const SizedBox(width: TenantAdminSpacing.lg),
                Expanded(
                    child: _buildCard(
                  title: 'ONLINE',
                  count: summary.onlineCount,
                  subtitle:
                      '${summary.totalTills == 0 ? 0 : (summary.onlineCount / summary.totalTills * 100).round()}% of tills online',
                  icon: Icons.wifi,
                  iconBgColor: Colors.green.shade50,
                  iconColor: Colors.green,
                  subtitleColor: Colors.green,
                )),
                const SizedBox(width: TenantAdminSpacing.lg),
                Expanded(
                    child: _buildCard(
                  title: 'OFFLINE',
                  count: summary.offlineCount,
                  subtitle:
                      '${summary.totalTills == 0 ? 0 : (summary.offlineCount / summary.totalTills * 100).round()}% of tills offline',
                  icon: Icons.wifi_off,
                  iconBgColor: Colors.red.shade50,
                  iconColor: Colors.red,
                  subtitleColor: Colors.red,
                )),
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
      padding: const EdgeInsets.all(TenantAdminSpacing.lg),
      decoration: BoxDecoration(
        color: TenantAdminColors.surface,
        borderRadius: BorderRadius.circular(TenantAdminRadius.lg),
        border: Border.all(color: TenantAdminColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 48,
            height: 48,
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
                    fontSize: 24,
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

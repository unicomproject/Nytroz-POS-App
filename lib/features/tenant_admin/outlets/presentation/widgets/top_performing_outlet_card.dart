import 'package:flutter/material.dart';

import '../../../presentation/theme/tenant_admin_theme.dart';

class TopPerformingOutletCard extends StatelessWidget {
  const TopPerformingOutletCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: TenantAdminColors.surface,
        borderRadius: BorderRadius.circular(TenantAdminRadius.lg),
        border: Border.all(color: TenantAdminColors.border),
        boxShadow: TenantAdminShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              TenantAdminSpacing.lg,
              TenantAdminSpacing.lg,
              TenantAdminSpacing.lg,
              TenantAdminSpacing.sm,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Top Performing Outlet',
                    style: TenantAdminTextStyles.sectionTitle(context),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: TenantAdminSpacing.sm),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: TenantAdminSpacing.md,
                    vertical: TenantAdminSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: TenantAdminColors.border),
                    borderRadius: BorderRadius.circular(TenantAdminRadius.md),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'This Month',
                        style: TenantAdminTextStyles.muted(context).copyWith(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.keyboard_arrow_down,
                        size: 16,
                        color: TenantAdminColors.mutedText,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              TenantAdminSpacing.lg,
              0,
              TenantAdminSpacing.lg,
              TenantAdminSpacing.lg,
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: TenantAdminColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.emoji_events_outlined,
                      color: TenantAdminColors.primary,
                      size: 24,
                    ),
                  ),
                ),
                const SizedBox(width: TenantAdminSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Development Main Store',
                        style: TextStyle(
                          color: TenantAdminColors.bodyText,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Colombo',
                        style: TenantAdminTextStyles.muted(context).copyWith(
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: TenantAdminSpacing.lg),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Sales',
                        style: TenantAdminTextStyles.muted(context).copyWith(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Rs. 2,450,000.00',
                        style: TextStyle(
                          color: TenantAdminColors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Transactions',
                        style: TenantAdminTextStyles.muted(context).copyWith(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        '1,258',
                        style: TextStyle(
                          color: TenantAdminColors.bodyText,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: TenantAdminSpacing.lg),
          const Divider(height: 1, color: TenantAdminColors.border),
          Padding(
            padding: const EdgeInsets.all(TenantAdminSpacing.lg),
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: TenantAdminSpacing.md,
              runSpacing: TenantAdminSpacing.md,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.arrow_upward,
                      color: TenantAdminColors.success,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      '12.5%',
                      style: TextStyle(
                        color: TenantAdminColors.success,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'vs last month',
                      style: TenantAdminTextStyles.muted(context).copyWith(
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                InkWell(
                  onTap: () {},
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.bar_chart,
                        color: TenantAdminColors.primary,
                        size: 16,
                      ),
                      SizedBox(width: 6),
                      Text(
                        'View full report →',
                        style: TextStyle(
                          color: TenantAdminColors.primary,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ],
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

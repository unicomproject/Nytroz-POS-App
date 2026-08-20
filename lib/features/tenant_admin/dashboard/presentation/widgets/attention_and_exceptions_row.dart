import 'package:flutter/material.dart';

import '../../../presentation/theme/tenant_admin_theme.dart';

class AttentionAndExceptionsRow extends StatelessWidget {
  const AttentionAndExceptionsRow({
    super.key,
    this.stretch = false,
    this.compact = false,
    this.scrollableWhenConstrained = false,
  });

  final bool stretch;
  final bool compact;
  final bool scrollableWhenConstrained;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 800;

        final needsAttention = _NeedsAttentionSection(
          compact: compact,
          scrollableWhenConstrained: scrollableWhenConstrained,
        );
        final storeExceptions = _StoreExceptionsSection(
          compact: compact,
          scrollableWhenConstrained: scrollableWhenConstrained,
        );

        if (isMobile) {
          return Column(
            children: [
              needsAttention,
              const SizedBox(height: 24),
              storeExceptions,
            ],
          );
        }

        return Row(
          crossAxisAlignment:
              stretch ? CrossAxisAlignment.stretch : CrossAxisAlignment.start,
          children: [
            Expanded(child: needsAttention),
            const SizedBox(width: 24),
            Expanded(child: storeExceptions),
          ],
        );
      },
    );
  }
}

double _responsiveCardWidth(double maxWidth) {
  if (maxWidth >= 560) {
    return (maxWidth - 32) / 3;
  }

  if (maxWidth >= 440) {
    return (maxWidth - 16) / 2;
  }

  return maxWidth;
}

class _NeedsAttentionSection extends StatelessWidget {
  const _NeedsAttentionSection({
    required this.compact,
    required this.scrollableWhenConstrained,
  });

  final bool compact;
  final bool scrollableWhenConstrained;

  @override
  Widget build(BuildContext context) {
    final padding = compact ? 12.0 : 22.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final cards = LayoutBuilder(
          builder: (context, constraints) {
            final cardWidth = _responsiveCardWidth(constraints.maxWidth);

            return Wrap(
              spacing: compact ? 8 : 16,
              runSpacing: compact ? 8 : 16,
              children: [
                SizedBox(
                  width: cardWidth,
                  child: _buildCard(
                    icon: Icons.receipt_long,
                    iconColor: TenantAdminColors.danger,
                    iconBg: const Color(0xFFFEE2E2),
                    title: '3 failed payments',
                    subtitle: 'Total LKR 6,750.00',
                    actionText: 'View Transactions',
                    actionColor: TenantAdminColors.danger,
                  ),
                ),
                SizedBox(
                  width: cardWidth,
                  child: _buildCard(
                    icon: Icons.local_shipping_outlined,
                    iconColor: TenantAdminColors.posHomeAccentOrange,
                    iconBg: const Color(0xFFFFF7ED),
                    title: '1 delayed supplier delivery',
                    subtitle: 'Expected today',
                    actionText: 'Track Delivery',
                    actionColor: TenantAdminColors.posHomeAccentOrange,
                  ),
                ),
                SizedBox(
                  width: cardWidth,
                  child: _buildCard(
                    icon: Icons.description_outlined,
                    iconColor: TenantAdminColors.info,
                    iconBg: const Color(0xFFEFF6FF),
                    title: 'VAT summary pending',
                    subtitle: 'May 2025',
                    actionText: 'Complete Now',
                    actionColor: TenantAdminColors.info,
                  ),
                ),
              ],
            );
          },
        );

        final canScrollInternally =
            scrollableWhenConstrained && constraints.hasBoundedHeight;

        return Container(
          padding: EdgeInsets.all(padding),
          decoration: BoxDecoration(
            color: TenantAdminColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: TenantAdminColors.border),
            boxShadow: TenantAdminShadows.card,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Needs Attention Today',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: compact ? 15 : 16,
                        fontWeight: FontWeight.w700,
                        color: TenantAdminColors.navy,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF7ED),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      '3',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: TenantAdminColors.posHomeAccentOrange,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () {},
                    style: TextButton.styleFrom(
                      foregroundColor: TenantAdminColors.posHomeAccentOrange,
                      textStyle: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                    child: const Text('View All'),
                  ),
                ],
              ),
              SizedBox(height: compact ? 6 : 14),
              if (canScrollInternally)
                Expanded(child: SingleChildScrollView(child: cards))
              else
                cards,
            ],
          ),
        );
      },
    );
  }

  Widget _buildCard({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String title,
    required String subtitle,
    required String actionText,
    required Color actionColor,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(compact ? 12 : 16),
      decoration: BoxDecoration(
        color: TenantAdminColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: TenantAdminColors.border),
      ),
      child: compact
          ? Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: iconColor, size: 16),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: TenantAdminColors.navy,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: TenantAdminColors.mutedText,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: () {},
                  child: Text(
                    actionText,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: actionColor,
                    ),
                  ),
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: iconBg,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(icon, color: iconColor, size: 16),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: TenantAdminColors.navy,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: TenantAdminColors.mutedText,
                  ),
                ),
                const SizedBox(height: 10),
                InkWell(
                  onTap: () {},
                  child: Text(
                    actionText,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: actionColor,
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class _StoreExceptionsSection extends StatelessWidget {
  const _StoreExceptionsSection({
    required this.compact,
    required this.scrollableWhenConstrained,
  });

  final bool compact;
  final bool scrollableWhenConstrained;

  @override
  Widget build(BuildContext context) {
    final padding = compact ? 18.0 : 22.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final cards = LayoutBuilder(
          builder: (context, constraints) {
            final cardWidth = _responsiveCardWidth(constraints.maxWidth);

            return Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                SizedBox(
                  width: cardWidth,
                  child: _buildCard(
                    icon: Icons.trending_down,
                    iconColor: TenantAdminColors.danger,
                    iconBg: const Color(0xFFFEE2E2),
                    title: 'Outlet Lake Road',
                    subtitle: 'Sales down 22%',
                    statText: 'vs Yesterday',
                    statColor: TenantAdminColors.danger,
                    actionText: 'Investigate',
                    actionColor: TenantAdminColors.danger,
                  ),
                ),
                SizedBox(
                  width: cardWidth,
                  child: _buildCard(
                    icon: Icons.schedule,
                    iconColor: TenantAdminColors.posHomeAccentOrange,
                    iconBg: const Color(0xFFFFF7ED),
                    title: 'Outlet City Center',
                    subtitle: 'High voids 8.7%',
                    statText: 'vs Target 3%',
                    statColor: TenantAdminColors.posHomeAccentOrange,
                    actionText: 'Review Now',
                    actionColor: TenantAdminColors.posHomeAccentOrange,
                  ),
                ),
                SizedBox(
                  width: cardWidth,
                  child: _buildCard(
                    icon: Icons.shopping_cart_outlined,
                    iconColor: TenantAdminColors.info,
                    iconBg: const Color(0xFFEFF6FF),
                    title: 'Outlet Negombo',
                    subtitle: 'Low sales items',
                    statText: '18 items',
                    statColor: TenantAdminColors.navy,
                    actionText: 'View Items',
                    actionColor: TenantAdminColors.info,
                  ),
                ),
              ],
            );
          },
        );

        final canScrollInternally =
            scrollableWhenConstrained && constraints.hasBoundedHeight;

        return Container(
          padding: EdgeInsets.all(padding),
          decoration: BoxDecoration(
            color: TenantAdminColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: TenantAdminColors.border),
            boxShadow: TenantAdminShadows.card,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Store Exceptions',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: compact ? 15 : 16,
                        fontWeight: FontWeight.w700,
                        color: TenantAdminColors.navy,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () {},
                    style: TextButton.styleFrom(
                      foregroundColor: TenantAdminColors.posHomeAccentOrange,
                      textStyle: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                    child: const Text('View All'),
                  ),
                ],
              ),
              SizedBox(height: compact ? 10 : 14),
              if (canScrollInternally)
                Expanded(child: SingleChildScrollView(child: cards))
              else
                cards,
            ],
          ),
        );
      },
    );
  }

  Widget _buildCard({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String title,
    required String subtitle,
    required String statText,
    required Color statColor,
    required String actionText,
    required Color actionColor,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(compact ? 12 : 16),
      decoration: BoxDecoration(
        color: TenantAdminColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: TenantAdminColors.border),
      ),
      child: compact
          ? Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: iconColor, size: 16),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: TenantAdminColors.navy,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              subtitle,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: TenantAdminColors.navy,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            statText,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: statColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: () {},
                  child: Text(
                    actionText,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: actionColor,
                    ),
                  ),
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: iconBg,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(icon, color: iconColor, size: 16),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: TenantAdminColors.mutedText,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: TenantAdminColors.navy,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  statText,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: statColor,
                  ),
                ),
                const SizedBox(height: 10),
                InkWell(
                  onTap: () {},
                  child: Text(
                    actionText,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: actionColor,
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

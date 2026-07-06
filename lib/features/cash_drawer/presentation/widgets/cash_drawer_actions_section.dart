import 'package:flutter/material.dart';

import 'cash_drawer_section_card.dart';
import '../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';

class CashDrawerActionsSection extends StatelessWidget {
  const CashDrawerActionsSection({
    super.key,
    required this.canCashIn,
    required this.canCashOut,
    required this.canCloseTill,
    required this.actionsEnabled,
    required this.onCashIn,
    required this.onCashOut,
    required this.onCloseTill,
  });

  final bool canCashIn;
  final bool canCashOut;
  final bool canCloseTill;
  final bool actionsEnabled;
  final VoidCallback onCashIn;
  final VoidCallback onCashOut;
  final VoidCallback onCloseTill;

  @override
  Widget build(BuildContext context) {
    return CashDrawerSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Drawer Actions',
            style: TenantAdminTextStyles.sectionTitle(context),
          ),
          const SizedBox(height: TenantAdminSpacing.lg),
          LayoutBuilder(
            builder: (context, constraints) {
              final useRow = constraints.maxWidth >= TenantAdminBreakpoints.tablet;

              final cards = [
                _DrawerActionCard(
                  icon: Icons.add_circle_outline_rounded,
                  title: 'Cash In',
                  description: 'Add cash to the drawer.',
                  enabled: actionsEnabled && canCashIn,
                  onTap: onCashIn,
                ),
                _DrawerActionCard(
                  icon: Icons.remove_circle_outline_rounded,
                  title: 'Cash Out / Drop',
                  description: 'Remove cash from the drawer or record a drop.',
                  enabled: actionsEnabled && canCashOut,
                  onTap: onCashOut,
                ),
                _DrawerActionCard(
                  icon: Icons.lock_outline_rounded,
                  title: 'Close Till',
                  description: 'Close the till and finalize cash count.',
                  enabled: actionsEnabled && canCloseTill,
                  onTap: onCloseTill,
                ),
              ];

              if (useRow) {
                return Row(
                  children: [
                    for (var index = 0; index < cards.length; index += 1) ...[
                      if (index > 0) const SizedBox(width: TenantAdminSpacing.md),
                      Expanded(child: cards[index]),
                    ],
                  ],
                );
              }

              return Column(
                children: [
                  for (var index = 0; index < cards.length; index += 1) ...[
                    if (index > 0) const SizedBox(height: TenantAdminSpacing.md),
                    cards[index],
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _DrawerActionCard extends StatelessWidget {
  const _DrawerActionCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String description;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: TenantAdminColors.background,
      borderRadius: BorderRadius.circular(TenantAdminRadius.lg),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(TenantAdminRadius.lg),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(TenantAdminRadius.lg),
            border: Border.all(
              color: enabled
                  ? TenantAdminColors.border
                  : TenantAdminColors.border.withValues(alpha: .6),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(TenantAdminSpacing.lg),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: enabled
                        ? TenantAdminColors.secondary
                        : TenantAdminColors.surface,
                    borderRadius: BorderRadius.circular(TenantAdminRadius.md),
                  ),
                  child: Icon(
                    icon,
                    color: enabled
                        ? TenantAdminColors.info
                        : TenantAdminColors.mutedText,
                    size: 30,
                  ),
                ),
                const SizedBox(width: TenantAdminSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: enabled
                                  ? TenantAdminColors.bodyText
                                  : TenantAdminColors.mutedText,
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                      const SizedBox(height: TenantAdminSpacing.xs),
                      Text(
                        description,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: TenantAdminColors.mutedText,
                              height: 1.35,
                            ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: enabled
                      ? TenantAdminColors.mutedText
                      : TenantAdminColors.offline,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

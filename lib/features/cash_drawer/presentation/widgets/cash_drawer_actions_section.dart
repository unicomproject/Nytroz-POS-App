import 'package:flutter/material.dart';

import '../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';

class CashDrawerActionsSection extends StatelessWidget {
  const CashDrawerActionsSection({
    super.key,
    required this.canOpenDrawer,
    required this.canCashIn,
    required this.canCashOut,
    required this.canCloseTill,
    required this.actionsEnabled,
    required this.openDrawerBusy,
    required this.onOpenDrawer,
    required this.onCashIn,
    required this.onCashOut,
    required this.onCloseTill,
  });

  final bool canOpenDrawer;
  final bool canCashIn;
  final bool canCashOut;
  final bool canCloseTill;
  final bool actionsEnabled;
  final bool openDrawerBusy;
  final VoidCallback onOpenDrawer;
  final VoidCallback onCashIn;
  final VoidCallback onCashOut;
  final VoidCallback onCloseTill;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'DRAWER ACTIONS',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: TenantAdminColors.mutedText,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6,
              ),
        ),
        const SizedBox(height: TenantAdminSpacing.lg),
        LayoutBuilder(
          builder: (context, constraints) {
            final useGrid =
                constraints.maxWidth >= TenantAdminBreakpoints.tablet;
            final cards = [
              _DrawerActionCard(
                icon: Icons.inbox_outlined,
                iconColor: TenantAdminColors.success,
                title: 'Open Drawer',
                description: 'Open the cash drawer.',
                enabled: actionsEnabled && canOpenDrawer && !openDrawerBusy,
                busy: openDrawerBusy,
                onTap: onOpenDrawer,
              ),
              _DrawerActionCard(
                icon: Icons.arrow_downward_rounded,
                iconColor: TenantAdminColors.success,
                title: 'Cash In',
                description: 'Add cash to the drawer.',
                enabled: actionsEnabled && canCashIn,
                onTap: onCashIn,
              ),
              _DrawerActionCard(
                icon: Icons.arrow_upward_rounded,
                iconColor: TenantAdminColors.danger,
                title: 'Cash Out / Drop',
                description: 'Remove cash from the drawer.',
                enabled: actionsEnabled && canCashOut,
                onTap: onCashOut,
              ),
              _DrawerActionCard(
                icon: Icons.lock_outline_rounded,
                iconColor: TenantAdminColors.posHomeAccentOrange,
                title: 'Close Till',
                description: 'Close the till and finalize cash count.',
                enabled: actionsEnabled && canCloseTill,
                onTap: onCloseTill,
              ),
            ];

            if (!useGrid) {
              return Column(
                children: [
                  for (var i = 0; i < cards.length; i++) ...[
                    if (i > 0) const SizedBox(height: TenantAdminSpacing.md),
                    cards[i],
                  ],
                ],
              );
            }

            return GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: TenantAdminSpacing.md,
              crossAxisSpacing: TenantAdminSpacing.md,
              childAspectRatio:
                  constraints.maxWidth >= TenantAdminBreakpoints.tablet
                      ? 2.4
                      : 1.7,
              children: cards,
            );
          },
        ),
      ],
    );
  }
}

class _DrawerActionCard extends StatelessWidget {
  const _DrawerActionCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.description,
    required this.enabled,
    required this.onTap,
    this.busy = false,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String description;
  final bool enabled;
  final bool busy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: enabled,
      label: title,
      child: Material(
        color: TenantAdminColors.surface,
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
                          ? iconColor.withValues(alpha: 0.12)
                          : TenantAdminColors.surface,
                      borderRadius: BorderRadius.circular(TenantAdminRadius.md),
                    ),
                    child: busy
                        ? const Padding(
                            padding: EdgeInsets.all(TenantAdminSpacing.md),
                            child: CircularProgressIndicator(strokeWidth: 2.5),
                          )
                        : Icon(
                            icon,
                            color: enabled
                                ? iconColor
                                : TenantAdminColors.mutedText,
                            size: 28,
                          ),
                  ),
                  const SizedBox(width: TenantAdminSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: enabled
                                        ? TenantAdminColors.bodyText
                                        : TenantAdminColors.mutedText,
                                    fontWeight: FontWeight.w900,
                                  ),
                        ),
                        const SizedBox(height: TenantAdminSpacing.xs),
                        Text(
                          description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: TenantAdminColors.mutedText,
                                    height: 1.35,
                                  ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

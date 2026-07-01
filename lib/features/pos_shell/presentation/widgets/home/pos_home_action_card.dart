import 'package:flutter/material.dart';

import '../../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';
import '../../../domain/entities/pos_home_action.dart';
import 'pos_dashboard_card_container.dart';

/// A POS Home quick-action card. The entire card is the button — there is no
/// nested action button. Shows an icon in a soft circular background, the
/// action title and a short description.
class PosHomeActionCard extends StatelessWidget {
  const PosHomeActionCard({
    super.key,
    required this.action,
    required this.icon,
    required this.description,
    this.onTap,
  });

  final PosHomeAction action;
  final IconData icon;
  final String description;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final canInvoke = action.routeExists && action.isEnabled && onTap != null;

    return Opacity(
      opacity: canInvoke ? 1 : 0.6,
      child: PosDashboardCardContainer(
        padding: const EdgeInsets.all(TenantAdminSpacing.lg),
        onTap: canInvoke ? onTap : null,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isTight =
                constraints.hasBoundedHeight && constraints.maxHeight < 180;
            final iconSize = isTight ? 44.0 : 56.0;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: iconSize,
                  height: iconSize,
                  decoration: const BoxDecoration(
                    color: TenantAdminColors.secondary,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    color: TenantAdminColors.info,
                    size: isTight ? 22 : 28,
                  ),
                ),
                SizedBox(
                  height:
                      isTight ? TenantAdminSpacing.sm : TenantAdminSpacing.md,
                ),
                Text(
                  action.label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TenantAdminTextStyles.sectionTitle(context),
                ),
                const SizedBox(height: TenantAdminSpacing.xs),
                Flexible(
                  child: Text(
                    description,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TenantAdminTextStyles.muted(context),
                  ),
                ),
                if (!canInvoke) ...[
                  const SizedBox(height: TenantAdminSpacing.sm),
                  Text(
                    'Not available yet.',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: TenantAdminColors.mutedText,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';
import '../../../domain/entities/pos_home_action.dart';
import 'pos_dashboard_card_container.dart';

class PosHomeActionCard extends StatelessWidget {
  const PosHomeActionCard({
    super.key,
    required this.action,
    required this.icon,
    required this.description,
    required this.iconColor,
    required this.iconBackgroundColor,
    this.onTap,
  });

  final PosHomeAction action;
  final IconData icon;
  final String description;
  final Color iconColor;
  final Color iconBackgroundColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final canInvoke = action.routeExists && action.isEnabled && onTap != null;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxHeight < 150;
        final isTiny = constraints.maxWidth < 100;
        final iconSize = isTiny ? 36.0 : (isCompact ? 44.0 : 52.0);
        final iconGlyphSize = isTiny ? 20.0 : (isCompact ? 24.0 : 28.0);

        return PosDashboardCardContainer(
          padding: EdgeInsets.zero,
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(TenantAdminRadius.lg),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: canInvoke ? onTap : null,
              borderRadius: BorderRadius.circular(TenantAdminRadius.lg),
              mouseCursor: canInvoke
                  ? SystemMouseCursors.click
                  : SystemMouseCursors.basic,
              child: Semantics(
                button: canInvoke,
                enabled: canInvoke,
                child: Stack(
                  children: [
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        isTiny
                            ? TenantAdminSpacing.sm
                            : isCompact
                                ? TenantAdminSpacing.md
                                : TenantAdminSpacing.lg,
                        isTiny
                            ? TenantAdminSpacing.sm
                            : isCompact
                                ? TenantAdminSpacing.md
                                : TenantAdminSpacing.lg,
                        48,
                        isTiny
                            ? TenantAdminSpacing.sm
                            : isCompact
                                ? TenantAdminSpacing.md
                                : TenantAdminSpacing.lg,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: iconSize,
                            height: iconSize,
                            decoration: BoxDecoration(
                              color: iconBackgroundColor,
                              borderRadius:
                                  BorderRadius.circular(TenantAdminRadius.md),
                            ),
                            child: Icon(
                              icon,
                              color: iconColor,
                              size: iconGlyphSize,
                            ),
                          ),
                          SizedBox(
                            height: isTiny
                                ? TenantAdminSpacing.xs
                                : isCompact
                                    ? TenantAdminSpacing.sm
                                    : TenantAdminSpacing.md,
                          ),
                          Text(
                            action.label,
                            maxLines: isTiny ? 1 : 2,
                            overflow: TextOverflow.ellipsis,
                            style:
                                Theme.of(context).textTheme.titleSmall?.copyWith(
                                      color: TenantAdminColors.bodyText,
                                      fontWeight: FontWeight.w800,
                                      fontSize: isTiny ? 11 : null,
                                      height: 1.2,
                                    ),
                          ),
                          if (!isTiny) ...[
                            const SizedBox(height: TenantAdminSpacing.xs),
                            Expanded(
                              child: Text(
                                description,
                                maxLines: isCompact ? 2 : 3,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: TenantAdminColors.mutedText,
                                      height: 1.35,
                                      fontSize: isCompact ? 11 : null,
                                    ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Positioned(
                      right: 12,
                      top: 0,
                      bottom: 0,
                      child: Center(
                        child: Icon(
                          Icons.chevron_right_rounded,
                          color: canInvoke
                              ? TenantAdminColors.mutedText
                              : TenantAdminColors.mutedText
                                  .withValues(alpha: 0.45),
                          size: isCompact ? 22 : 24,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

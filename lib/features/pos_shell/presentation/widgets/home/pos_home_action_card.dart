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
    this.onTap,
  });

  final PosHomeAction action;
  final IconData icon;
  final String description;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final canInvoke = action.routeExists && action.isEnabled && onTap != null;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isTight =
            (constraints.hasBoundedHeight && constraints.maxHeight < 250) ||
                (constraints.hasBoundedWidth && constraints.maxWidth < 310);
        final iconContainerSize = isTight ? 48.0 : 68.0;
        final iconSize = isTight ? 26.0 : 36.0;
        final titleStyle = isTight
            ? Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: TenantAdminColors.bodyText,
                  fontWeight: FontWeight.w800,
                )
            : TenantAdminTextStyles.sectionTitle(context);
        final descriptionStyle = isTight
            ? Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: TenantAdminColors.mutedText,
                  height: 1.35,
                )
            : TenantAdminTextStyles.muted(context).copyWith(height: 1.4);

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
                child: Padding(
                  padding: EdgeInsets.all(
                    isTight ? TenantAdminSpacing.md : TenantAdminSpacing.xl,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 260),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            width: iconContainerSize,
                            height: iconContainerSize,
                            decoration: const BoxDecoration(
                              color: TenantAdminColors.secondary,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              icon,
                              color: TenantAdminColors.info,
                              size: iconSize,
                            ),
                          ),
                          SizedBox(
                            height: isTight
                                ? TenantAdminSpacing.sm
                                : TenantAdminSpacing.lg,
                          ),
                          Text(
                            action.label,
                            maxLines: isTight ? 1 : 2,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: titleStyle,
                          ),
                          const SizedBox(height: TenantAdminSpacing.sm),
                          Text(
                            description,
                            maxLines: isTight ? 2 : 3,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: descriptionStyle,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

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
    required this.metrics,
    this.buttonLabel,
    this.onTap,
  });

  final PosHomeAction action;
  final IconData icon;
  final String description;
  final List<Widget> metrics;
  final String? buttonLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final canInvoke = action.routeExists && action.isEnabled && onTap != null;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isTight =
            constraints.hasBoundedHeight && constraints.maxHeight < 250;
        final iconSize = isTight ? 34.0 : 48.0;
        final buttonHeight = isTight ? 36.0 : 46.0;
        final titleStyle = isTight
            ? Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: TenantAdminColors.bodyText,
                  fontWeight: FontWeight.w800,
                )
            : TenantAdminTextStyles.sectionTitle(context);
        final descriptionStyle = isTight
            ? Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: TenantAdminColors.mutedText,
                )
            : TenantAdminTextStyles.muted(context);

        return PosDashboardCardContainer(
          padding: EdgeInsets.all(
            isTight ? TenantAdminSpacing.sm : TenantAdminSpacing.md,
          ),
          child: Column(
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
                  size: isTight ? 20 : 25,
                ),
              ),
              SizedBox(
                  height:
                      isTight ? TenantAdminSpacing.xs : TenantAdminSpacing.md),
              Text(
                action.label,
                maxLines: isTight ? 1 : 2,
                style: titleStyle,
              ),
              const SizedBox(height: TenantAdminSpacing.xs),
              Text(
                description,
                maxLines: isTight ? 1 : 2,
                style: descriptionStyle,
              ),
              SizedBox(
                  height:
                      isTight ? TenantAdminSpacing.xs : TenantAdminSpacing.md),
              Flexible(
                child: Align(
                  alignment: Alignment.topLeft,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.topLeft,
                    child: SizedBox(
                      width: constraints.maxWidth -
                          (isTight
                              ? TenantAdminSpacing.sm * 2
                              : TenantAdminSpacing.md * 2),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: metrics,
                      ),
                    ),
                  ),
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: buttonHeight,
                child: OutlinedButton(
                  onPressed: canInvoke ? onTap : null,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: TenantAdminColors.border),
                    padding: EdgeInsets.symmetric(
                      horizontal: isTight
                          ? TenantAdminSpacing.sm
                          : TenantAdminSpacing.md,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(TenantAdminRadius.md),
                    ),
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(buttonLabel ?? action.buttonLabel),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class PosActionMetricLine extends StatelessWidget {
  const PosActionMetricLine({
    super.key,
    required this.value,
    required this.label,
    this.color = TenantAdminColors.bodyText,
  });

  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: TenantAdminSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Flexible(
            flex: 3,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                maxLines: 1,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ),
          ),
          const SizedBox(width: TenantAdminSpacing.xs),
          Expanded(
            flex: 3,
            child: Text(
              label,
              maxLines: 2,
              softWrap: true,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: TenantAdminColors.mutedText,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../theme/tenant_admin_motion.dart';
import '../theme/tenant_admin_theme.dart';
import 'tenant_admin_row_action.dart';

class TenantAdminManagementCardMetric {
  const TenantAdminManagementCardMetric({
    required this.label,
    required this.value,
    this.icon,
  });

  final String label;
  final Widget value;
  final IconData? icon;
}

class TenantAdminManagementCardAction {
  const TenantAdminManagementCardAction({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.color,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final Color? color;
}

/// Shared responsive list card for Tenant Admin management modules.
class TenantAdminManagementCard extends StatelessWidget {
  const TenantAdminManagementCard({
    super.key,
    required this.title,
    required this.leading,
    this.badge,
    this.metrics = const [],
    this.status,
    this.actions = const [],
    this.onTap,
    this.selected = false,
  });

  final String title;
  final Widget leading;
  final Widget? badge;
  final List<TenantAdminManagementCardMetric> metrics;
  final Widget? status;
  final List<TenantAdminManagementCardAction> actions;
  final VoidCallback? onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= TenantAdminBreakpoints.tablet;
          final metricWidgets = metrics
              .map((metric) => _Metric(metric: metric))
              .toList(growable: false);
          final overflowMenu = actions.isEmpty
              ? null
              : TenantAdminOverflowMenu(
                  actions: [
                    for (final action in actions)
                      TenantAdminOverflowAction(
                        id: action.label,
                        icon: action.icon,
                        label: action.label,
                        onSelected: action.onPressed,
                        destructive: action.color == TenantAdminColors.danger,
                        success: action.color == TenantAdminColors.success,
                      ),
                  ],
                );

          final compactHeader = Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              leading,
              const SizedBox(width: TenantAdminSpacing.lg),
              Expanded(
                child: Wrap(
                  spacing: TenantAdminSpacing.sm,
                  runSpacing: TenantAdminSpacing.xs,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(title,
                        style: TenantAdminTextStyles.sectionTitle(context)),
                    if (badge != null) badge!,
                  ],
                ),
              ),
              if (status != null) status!,
              if (overflowMenu != null) overflowMenu,
            ],
          );

          final content = wide
              ? Row(
                  children: [
                    SizedBox(width: 76, child: leading),
                    const SizedBox(width: TenantAdminSpacing.lg),
                    Expanded(
                        flex: 3,
                        child: Wrap(
                          spacing: TenantAdminSpacing.sm,
                          runSpacing: TenantAdminSpacing.xs,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(title,
                                style: TenantAdminTextStyles.sectionTitle(
                                    context)),
                            if (badge != null) badge!,
                          ],
                        )),
                    for (final metric in metricWidgets) ...[
                      const VerticalDivider(
                          width: 32, color: TenantAdminColors.border),
                      Expanded(flex: 2, child: metric),
                    ],
                    if (status != null) ...[
                      const SizedBox(width: TenantAdminSpacing.lg),
                      status!,
                    ],
                    if (overflowMenu != null) ...[
                      const SizedBox(width: TenantAdminSpacing.sm),
                      overflowMenu,
                    ],
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    compactHeader,
                    if (metricWidgets.isNotEmpty) ...[
                      const SizedBox(height: TenantAdminSpacing.lg),
                      Wrap(
                        spacing: TenantAdminSpacing.xl,
                        runSpacing: TenantAdminSpacing.md,
                        children: metricWidgets,
                      ),
                    ],
                  ],
                );

          return TenantAdminPressScale(
            enabled: onTap != null,
            child: Material(
              color: selected
                  ? TenantAdminColors.primary.withValues(alpha: 0.06)
                  : TenantAdminColors.surface,
              borderRadius: BorderRadius.circular(TenantAdminRadius.lg),
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(TenantAdminRadius.lg),
                child: AnimatedContainer(
                  duration: TenantAdminMotion.fast,
                  curve: TenantAdminMotion.standard,
                  padding: const EdgeInsets.all(TenantAdminSpacing.lg),
                  constraints: const BoxConstraints(minHeight: 124),
                  decoration: BoxDecoration(
                    color: selected
                        ? TenantAdminColors.primary.withValues(alpha: 0.06)
                        : null,
                    border: Border.all(
                      color: selected
                          ? TenantAdminColors.primary
                          : TenantAdminColors.border,
                    ),
                    borderRadius: BorderRadius.circular(TenantAdminRadius.lg),
                  ),
                  child: content,
                ),
              ),
            ),
          );
        },
      );
}

class _Metric extends StatelessWidget {
  const _Metric({required this.metric});
  final TenantAdminManagementCardMetric metric;

  @override
  Widget build(BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(metric.label.toUpperCase(),
              style: const TextStyle(
                  fontSize: 10,
                  letterSpacing: 0.7,
                  color: TenantAdminColors.mutedText,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: TenantAdminSpacing.xs),
          Row(mainAxisSize: MainAxisSize.min, children: [
            if (metric.icon != null) ...[
              Icon(metric.icon, size: 16, color: TenantAdminColors.mutedText),
              const SizedBox(width: TenantAdminSpacing.xs)
            ],
            Flexible(child: metric.value),
          ]),
        ],
      );
}

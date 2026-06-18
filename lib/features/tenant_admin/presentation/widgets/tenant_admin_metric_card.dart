import 'package:flutter/material.dart';

import '../theme/tenant_admin_theme.dart';
import 'tenant_admin_status_badge.dart';

class TenantAdminMetricCard extends StatelessWidget {
  const TenantAdminMetricCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    this.subtitle,
    this.trend,
    this.status,
  });

  final String title;
  final String value;
  final String? subtitle;
  final IconData icon;
  final String? trend;
  final TenantAdminStatusType? status;

  static const _compactHeightThreshold = 140.0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxHeight.isFinite &&
            constraints.maxHeight < _compactHeightThreshold;
        final padding = isCompact
            ? TenantAdminSpacing.md
            : TenantAdminSpacing.lg;
        final iconBoxSize = isCompact ? 36.0 : 44.0;
        final iconSize = isCompact ? 20.0 : 24.0;
        final headerGap = isCompact
            ? TenantAdminSpacing.sm
            : TenantAdminSpacing.lg;
        final footerGap = isCompact
            ? TenantAdminSpacing.xs
            : TenantAdminSpacing.sm;
        final valueStyle = (isCompact
                ? Theme.of(context).textTheme.titleLarge
                : Theme.of(context).textTheme.headlineSmall)
            ?.copyWith(
          fontWeight: FontWeight.w800,
          color: TenantAdminColors.bodyText,
        );

        return Container(
          padding: EdgeInsets.all(padding),
          decoration: BoxDecoration(
            color: TenantAdminColors.surface,
            borderRadius: BorderRadius.circular(TenantAdminRadius.lg),
            border: Border.all(color: TenantAdminColors.border),
            boxShadow: TenantAdminShadows.card,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    width: iconBoxSize,
                    height: iconBoxSize,
                    decoration: BoxDecoration(
                      color: TenantAdminColors.secondary,
                      borderRadius:
                          BorderRadius.circular(TenantAdminRadius.md),
                    ),
                    child: Icon(
                      icon,
                      size: iconSize,
                      color: TenantAdminColors.primary,
                    ),
                  ),
                  const Spacer(),
                  if (status != null)
                    Flexible(
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: TenantAdminStatusBadge(
                          label: status!.label,
                          status: status!,
                        ),
                      ),
                    ),
                ],
              ),
              SizedBox(height: headerGap),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TenantAdminTextStyles.muted(context),
              ),
              const SizedBox(height: TenantAdminSpacing.xs),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: valueStyle,
              ),
              if (subtitle != null || trend != null) ...[
                SizedBox(height: footerGap),
                Row(
                  children: [
                    if (trend != null)
                      Flexible(
                        child: Text(
                          trend!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: TenantAdminColors.success,
                            fontWeight: FontWeight.w700,
                            fontSize: isCompact ? 12 : null,
                          ),
                        ),
                      ),
                    if (trend != null && subtitle != null)
                      const SizedBox(width: TenantAdminSpacing.sm),
                    if (subtitle != null)
                      Expanded(
                        child: Text(
                          subtitle!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TenantAdminTextStyles.muted(context),
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

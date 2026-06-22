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
    this.dense = false,
  });

  final String title;
  final String value;
  final String? subtitle;
  final IconData icon;
  final String? trend;
  final TenantAdminStatusType? status;
  final bool dense;

  static const _compactHeightThreshold = 150.0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = dense ||
            (constraints.maxHeight.isFinite &&
                constraints.maxHeight < _compactHeightThreshold);
        final padding =
            isCompact ? TenantAdminSpacing.md : TenantAdminSpacing.lg;
        final iconBoxSize = isCompact ? 36.0 : 44.0;
        final iconSize = isCompact ? 20.0 : 24.0;
        final headerGap =
            isCompact ? TenantAdminSpacing.sm : TenantAdminSpacing.md;
        final valueStyle = (isCompact
                ? Theme.of(context).textTheme.titleMedium
                : Theme.of(context).textTheme.headlineSmall)
            ?.copyWith(
          fontWeight: FontWeight.w800,
          color: TenantAdminColors.bodyText,
        );

        return Container(
          height: constraints.maxHeight.isFinite ? constraints.maxHeight : null,
          padding: EdgeInsets.all(padding),
          decoration: BoxDecoration(
            color: TenantAdminColors.surface,
            borderRadius: BorderRadius.circular(TenantAdminRadius.lg),
            border: Border.all(color: TenantAdminColors.border),
            boxShadow: TenantAdminShadows.card,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: iconBoxSize,
                    height: iconBoxSize,
                    decoration: BoxDecoration(
                      color: TenantAdminColors.secondary,
                      borderRadius: BorderRadius.circular(TenantAdminRadius.md),
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
                style: TenantAdminTextStyles.muted(context).copyWith(
                  fontSize: isCompact ? 12 : null,
                ),
              ),
              const SizedBox(height: TenantAdminSpacing.xs),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: valueStyle,
              ),
              const Spacer(),
              if (subtitle != null || trend != null)
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
                            fontSize: isCompact ? 11 : 12,
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
                          style: TenantAdminTextStyles.muted(context).copyWith(
                            fontSize: isCompact ? 11 : 12,
                          ),
                        ),
                      ),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }
}

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

  static const _compactHeightThreshold = 132.0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = dense ||
            (constraints.maxHeight.isFinite &&
                constraints.maxHeight < _compactHeightThreshold);
        final padding = isCompact ? 10.0 : 14.0;
        final iconBoxSize = isCompact ? 30.0 : 36.0;
        final iconSize = isCompact ? 16.0 : 20.0;
        final headerGap = isCompact ? 6.0 : 12.0;
        final valueStyle = (isCompact
                ? Theme.of(context).textTheme.titleMedium
                : Theme.of(context).textTheme.headlineMedium)
            ?.copyWith(
          fontWeight: FontWeight.w900,
          color: TenantAdminColors.bodyText,
          letterSpacing: -1.0,
        );
        final accentColor = _accentColor(status);

        return Container(
          height: constraints.maxHeight.isFinite ? constraints.maxHeight : null,
          padding: EdgeInsets.all(padding),
          decoration: BoxDecoration(
            color: TenantAdminColors.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: TenantAdminColors.border),
            boxShadow: TenantAdminShadows.card,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: iconBoxSize + 6,
                    height: iconBoxSize + 6,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          accentColor.withValues(alpha: 0.2),
                          accentColor.withValues(alpha: 0.05),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: accentColor.withValues(alpha: 0.1),
                        width: 1,
                      ),
                    ),
                    child: Icon(
                      icon,
                      size: iconSize + 2,
                      color: accentColor,
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
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: isCompact ? 2 : TenantAdminSpacing.xs),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: valueStyle,
              ),
              if (subtitle != null || trend != null) ...[
                SizedBox(height: isCompact ? 4 : 8),
                Row(
                  children: [
                    if (trend != null)
                      Flexible(
                        child: Text(
                          trend!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: status == TenantAdminStatusType.danger ||
                                    status == TenantAdminStatusType.warning
                                ? TenantAdminColors.warning
                                : TenantAdminColors.success,
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
            ],
          ),
        );
      },
    );
  }
}

Color _accentColor(TenantAdminStatusType? status) {
  switch (status) {
    case TenantAdminStatusType.danger:
      return TenantAdminColors.danger;
    case TenantAdminStatusType.warning:
      return TenantAdminColors.warning;
    case TenantAdminStatusType.online:
    case TenantAdminStatusType.success:
    case TenantAdminStatusType.active:
      return TenantAdminColors.success;
    case TenantAdminStatusType.pending:
      return TenantAdminColors.pending;
    case TenantAdminStatusType.offline:
    case TenantAdminStatusType.inactive:
      return TenantAdminColors.offline;
    case null:
      return TenantAdminColors.primary;
  }
}

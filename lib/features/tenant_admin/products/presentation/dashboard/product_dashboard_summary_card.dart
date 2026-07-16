import 'package:flutter/material.dart';

import '../../../presentation/theme/tenant_admin_theme.dart';
import '../../../presentation/widgets/tenant_admin_status_badge.dart';

class ProductDashboardSummaryCard extends StatelessWidget {
  const ProductDashboardSummaryCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.trend,
    this.status,
    this.onTap,
    this.dense = false,
  });

  final String title;
  final String value;
  final IconData icon;
  final ProductDashboardSummaryCardTrend trend;
  final TenantAdminStatusType? status;
  final VoidCallback? onTap;
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
                : Theme.of(context).textTheme.headlineSmall)
            ?.copyWith(
          fontWeight: FontWeight.w800,
          color: TenantAdminColors.bodyText,
        );
        final accentColor = _accentColor(status);
        final isClickable = onTap != null;

        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(18),
            child: Container(
              height:
                  constraints.maxHeight.isFinite ? constraints.maxHeight : null,
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
                        width: iconBoxSize,
                        height: iconBoxSize,
                        decoration: BoxDecoration(
                          color: accentColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(11),
                        ),
                        child: Icon(
                          icon,
                          size: iconSize,
                          color: accentColor,
                        ),
                      ),
                      const Spacer(),
                      if (isClickable)
                        const Icon(
                          Icons.chevron_right,
                          size: 18,
                          color: TenantAdminColors.mutedText,
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
                  if (trend.label.isNotEmpty) ...[
                    SizedBox(height: isCompact ? 4 : 8),
                    Row(
                      children: [
                        if (trend.icon != null) ...[
                          Icon(
                            trend.icon,
                            size: isCompact ? 14 : 16,
                            color: trend.color,
                          ),
                          const SizedBox(width: 4),
                        ],
                        Expanded(
                          child: Text(
                            trend.label,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: trend.color,
                              fontWeight: FontWeight.w700,
                              fontSize: isCompact ? 11 : 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class ProductDashboardSummaryCardTrend {
  const ProductDashboardSummaryCardTrend({
    required this.label,
    this.icon,
    this.color = TenantAdminColors.mutedText,
  });

  final String label;
  final IconData? icon;
  final Color color;
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

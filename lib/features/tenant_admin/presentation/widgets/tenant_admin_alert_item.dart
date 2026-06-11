import 'package:flutter/material.dart';

import '../theme/tenant_admin_theme.dart';
import 'tenant_admin_status_badge.dart';

class TenantAdminAlertItem extends StatelessWidget {
  const TenantAdminAlertItem({
    super.key,
    required this.title,
    required this.message,
    required this.status,
    this.action,
  });

  final String title;
  final String message;
  final TenantAdminStatusType status;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final color = _colorFor(status);

    return Container(
      padding: const EdgeInsets.all(TenantAdminSpacing.lg),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(TenantAdminRadius.lg),
        border: Border.all(color: color.withValues(alpha: 0.24)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(_iconFor(status), color: color),
          const SizedBox(width: TenantAdminSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TenantAdminTextStyles.sectionTitle(context)),
                const SizedBox(height: TenantAdminSpacing.xs),
                Text(message, style: TenantAdminTextStyles.muted(context)),
              ],
            ),
          ),
          if (action != null) ...[
            const SizedBox(width: TenantAdminSpacing.md),
            action!,
          ],
        ],
      ),
    );
  }
}

Color _colorFor(TenantAdminStatusType status) {
  switch (status) {
    case TenantAdminStatusType.active:
      return TenantAdminColors.success;
    case TenantAdminStatusType.inactive:
      return TenantAdminColors.offline;
    case TenantAdminStatusType.online:
      return TenantAdminColors.info;
    case TenantAdminStatusType.offline:
      return TenantAdminColors.offline;
    case TenantAdminStatusType.pending:
      return TenantAdminColors.pending;
    case TenantAdminStatusType.warning:
      return TenantAdminColors.warning;
    case TenantAdminStatusType.danger:
      return TenantAdminColors.danger;
    case TenantAdminStatusType.success:
      return TenantAdminColors.success;
  }
}

IconData _iconFor(TenantAdminStatusType status) {
  switch (status) {
    case TenantAdminStatusType.danger:
      return Icons.error_outline;
    case TenantAdminStatusType.warning:
      return Icons.warning;
    case TenantAdminStatusType.pending:
      return Icons.schedule;
    case TenantAdminStatusType.offline:
      return Icons.cloud_off;
    case TenantAdminStatusType.active:
    case TenantAdminStatusType.inactive:
    case TenantAdminStatusType.online:
    case TenantAdminStatusType.success:
      return Icons.info_outline;
  }
}

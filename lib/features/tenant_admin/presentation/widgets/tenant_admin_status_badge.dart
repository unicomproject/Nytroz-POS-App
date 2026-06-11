import 'package:flutter/material.dart';

import '../theme/tenant_admin_theme.dart';

enum TenantAdminStatusType {
  active,
  inactive,
  online,
  offline,
  pending,
  warning,
  danger,
  success,
}

extension TenantAdminStatusTypeLabel on TenantAdminStatusType {
  String get label {
    switch (this) {
      case TenantAdminStatusType.active:
        return 'Active';
      case TenantAdminStatusType.inactive:
        return 'Inactive';
      case TenantAdminStatusType.online:
        return 'Online';
      case TenantAdminStatusType.offline:
        return 'Offline';
      case TenantAdminStatusType.pending:
        return 'Pending';
      case TenantAdminStatusType.warning:
        return 'Warning';
      case TenantAdminStatusType.danger:
        return 'Danger';
      case TenantAdminStatusType.success:
        return 'Success';
    }
  }
}

class TenantAdminStatusBadge extends StatelessWidget {
  const TenantAdminStatusBadge({
    super.key,
    required this.label,
    required this.status,
  });

  final String label;
  final TenantAdminStatusType status;

  @override
  Widget build(BuildContext context) {
    final color = _colorFor(status);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: TenantAdminSpacing.md,
          vertical: TenantAdminSpacing.xs,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
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

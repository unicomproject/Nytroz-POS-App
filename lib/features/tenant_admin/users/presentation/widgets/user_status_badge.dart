import 'package:flutter/material.dart';

import '../../../presentation/theme/tenant_admin_theme.dart';
import '../../../presentation/widgets/tenant_admin_status_badge.dart';

class UserStatusBadge extends StatelessWidget {
  const UserStatusBadge({super.key, required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final normalized = status.trim().toUpperCase();
    final type = switch (normalized) {
      'ACTIVE' => TenantAdminStatusType.active,
      'INVITED' => TenantAdminStatusType.pending,
      _ => TenantAdminStatusType.inactive,
    };

    return TenantAdminStatusBadge(
      label: _label(normalized),
      status: type,
    );
  }

  String _label(String normalized) {
    switch (normalized) {
      case 'ACTIVE':
        return 'Active';
      case 'INVITED':
        return 'Invited';
      case 'INACTIVE':
        return 'Inactive';
      default:
        return normalized.isEmpty ? '—' : normalized;
    }
  }
}

Color userStatusColor(String status) {
  switch (status.trim().toUpperCase()) {
    case 'ACTIVE':
      return TenantAdminColors.success;
    case 'INVITED':
      return TenantAdminColors.pending;
    default:
      return TenantAdminColors.offline;
  }
}

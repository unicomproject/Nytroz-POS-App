import 'package:flutter/material.dart';

import '../../../presentation/widgets/tenant_admin_status_badge.dart';
import '../utils/inventory_api_errors.dart';

class StockStatusBadge extends StatelessWidget {
  const StockStatusBadge({super.key, required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    return TenantAdminStatusBadge(
      label: stockStatusLabel(status),
      status: _statusType(status),
    );
  }

  TenantAdminStatusType _statusType(String status) {
    switch (status.toUpperCase()) {
      case 'IN_STOCK':
        return TenantAdminStatusType.success;
      case 'LOW_STOCK':
        return TenantAdminStatusType.warning;
      case 'OUT_OF_STOCK':
        return TenantAdminStatusType.danger;
      default:
        return TenantAdminStatusType.inactive;
    }
  }
}

class ExpiryStatusBadge extends StatelessWidget {
  const ExpiryStatusBadge({super.key, required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    return TenantAdminStatusBadge(
      label: expiryStatusLabel(status),
      status: _statusType(status),
    );
  }

  TenantAdminStatusType _statusType(String status) {
    switch (status.toUpperCase()) {
      case 'VALID':
      case 'NOT_APPLICABLE':
        return TenantAdminStatusType.success;
      case 'EXPIRING_SOON':
        return TenantAdminStatusType.warning;
      case 'EXPIRED':
        return TenantAdminStatusType.danger;
      default:
        return TenantAdminStatusType.inactive;
    }
  }
}

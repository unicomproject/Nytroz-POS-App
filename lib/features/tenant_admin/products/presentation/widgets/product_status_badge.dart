import 'package:flutter/material.dart';

import '../../../presentation/theme/tenant_admin_theme.dart';

class ProductStatusBadge extends StatelessWidget {
  const ProductStatusBadge({super.key, required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final normalized = status.trim().toUpperCase();
    final (color, background) = switch (normalized) {
      'ACTIVE' => (
          TenantAdminColors.success,
          TenantAdminColors.success.withValues(alpha: 0.12),
        ),
      'INACTIVE' => (
          TenantAdminColors.offline,
          TenantAdminColors.offline.withValues(alpha: 0.12),
        ),
      'DRAFT' => (
          TenantAdminColors.warning,
          TenantAdminColors.warning.withValues(alpha: 0.12),
        ),
      'DELETED' => (
          TenantAdminColors.danger,
          TenantAdminColors.danger.withValues(alpha: 0.12),
        ),
      _ => (
          TenantAdminColors.mutedText,
          TenantAdminColors.background,
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: TenantAdminSpacing.sm,
        vertical: TenantAdminSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        _label(normalized),
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  String _label(String normalized) {
    if (normalized.isEmpty) {
      return '-';
    }

    return normalized[0] + normalized.substring(1).toLowerCase();
  }
}

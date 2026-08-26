import 'package:flutter/material.dart';

import '../../../presentation/theme/tenant_admin_theme.dart';

class ProductStatusBadge extends StatelessWidget {
  const ProductStatusBadge({super.key, required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final normalized = status.trim().toUpperCase();
    final (color, background) = switch (normalized) {
      'ACTIVE' => (TenantAdminColors.success, TenantAdminColors.successSurface),
      'INACTIVE' => (
          TenantAdminColors.offline,
          TenantAdminColors.offline.withValues(alpha: 0.12),
        ),
      'DRAFT' => (TenantAdminColors.warning, TenantAdminColors.warningSurface),
      'DELETED' => (TenantAdminColors.danger, TenantAdminColors.dangerSurface),
      _ => (
          TenantAdminColors.mutedText,
          TenantAdminColors.subtleBackground,
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        _label(normalized),
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
          height: 1.2,
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

class StockStatusBadge extends StatelessWidget {
  const StockStatusBadge({super.key, required this.status});

  final String? status;

  @override
  Widget build(BuildContext context) {
    if (status == null || status!.trim().isEmpty) {
      return const Text(
        '—',
        style: TextStyle(
          color: TenantAdminColors.mutedText,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      );
    }

    final normalized = status!.trim().toUpperCase();
    final (label, color, background) = switch (normalized) {
      'IN_STOCK' => (
          'In Stock',
          TenantAdminColors.success,
          TenantAdminColors.successSurface,
        ),
      'LOW_STOCK' => (
          'Low Stock',
          TenantAdminColors.warning,
          TenantAdminColors.warningSurface,
        ),
      'OUT_OF_STOCK' => (
          'Out of Stock',
          TenantAdminColors.danger,
          TenantAdminColors.dangerSurface,
        ),
      'NOT_TRACKED' => (
          'Not Tracked',
          TenantAdminColors.offline,
          TenantAdminColors.offline.withValues(alpha: 0.12),
        ),
      _ => (
          normalized,
          TenantAdminColors.mutedText,
          TenantAdminColors.subtleBackground,
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
          height: 1.2,
        ),
      ),
    );
  }
}

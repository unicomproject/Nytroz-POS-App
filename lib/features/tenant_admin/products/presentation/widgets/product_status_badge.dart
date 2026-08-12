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
        horizontal: TenantAdminSpacing.md,
        vertical: TenantAdminSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            _label(normalized),
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
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
          TenantAdminColors.success.withValues(alpha: 0.12),
        ),
      'LOW_STOCK' => (
          'Low Stock',
          TenantAdminColors.warning,
          TenantAdminColors.warning.withValues(alpha: 0.12),
        ),
      'OUT_OF_STOCK' => (
          'Out of Stock',
          TenantAdminColors.danger,
          TenantAdminColors.danger.withValues(alpha: 0.12),
        ),
      'NOT_TRACKED' => (
          'Not Tracked',
          TenantAdminColors.offline,
          TenantAdminColors.offline.withValues(alpha: 0.12),
        ),
      _ => (
          normalized,
          TenantAdminColors.mutedText,
          TenantAdminColors.background,
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: TenantAdminSpacing.md,
        vertical: TenantAdminSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

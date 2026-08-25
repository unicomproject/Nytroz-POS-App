import 'package:flutter/material.dart';

import '../theme/tenant_admin_theme.dart';

/// Compact icon-and-label action used by Tenant Admin list rows and cards.
class TenantAdminRowAction extends StatelessWidget {
  const TenantAdminRowAction({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.destructive = false,
    this.success = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final bool destructive;
  final bool success;

  @override
  Widget build(BuildContext context) {
    final color = destructive
        ? TenantAdminColors.danger
        : success
            ? TenantAdminColors.success
            : TenantAdminColors.info;

    return Tooltip(
      message: label,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class TenantAdminRowActionMenuItem extends StatelessWidget {
  const TenantAdminRowActionMenuItem({
    super.key,
    required this.icon,
    required this.label,
    this.destructive = false,
    this.success = false,
  });

  final IconData icon;
  final String label;
  final bool destructive;
  final bool success;

  @override
  Widget build(BuildContext context) {
    final color = destructive
        ? TenantAdminColors.danger
        : success
            ? TenantAdminColors.success
            : TenantAdminColors.info;

    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: TenantAdminSpacing.md),
        Flexible(
          child: Text(
            label,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: color, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}

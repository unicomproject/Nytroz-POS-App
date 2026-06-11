import 'package:flutter/material.dart';

import '../theme/tenant_admin_theme.dart';

class TenantAdminFilterChip extends StatelessWidget {
  const TenantAdminFilterChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.count,
  });

  final String label;
  final bool selected;
  final int? count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(
          horizontal: TenantAdminSpacing.md,
          vertical: TenantAdminSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: selected ? TenantAdminColors.primary : TenantAdminColors.surface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? TenantAdminColors.primary : TenantAdminColors.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : TenantAdminColors.bodyText,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (count != null) ...[
              const SizedBox(width: TenantAdminSpacing.sm),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: selected
                      ? Colors.white.withValues(alpha: 0.18)
                      : TenantAdminColors.background,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: TenantAdminSpacing.sm,
                    vertical: 2,
                  ),
                  child: Text(
                    '$count',
                    style: TextStyle(
                      color: selected ? Colors.white : TenantAdminColors.mutedText,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

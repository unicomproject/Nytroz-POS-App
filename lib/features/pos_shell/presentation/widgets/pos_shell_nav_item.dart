import 'package:flutter/material.dart';

import '../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';

class PosShellNavItem extends StatelessWidget {
  const PosShellNavItem({
    super.key,
    required this.icon,
    required this.label,
    this.selected = false,
    this.isEnabled = true,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final bool isEnabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final foregroundColor = selected
        ? Colors.white
        : isEnabled
            ? Colors.white.withValues(alpha: 0.88)
            : Colors.white.withValues(alpha: 0.38);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Material(
        color: selected ? const Color(0xFF075DFF) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: Tooltip(
          message: isEnabled ? label : '$label is not available yet',
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 48),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: TenantAdminSpacing.md,
                  vertical: TenantAdminSpacing.sm,
                ),
                child: Row(
                  children: [
                    Icon(icon, color: foregroundColor, size: 22),
                    const SizedBox(width: TenantAdminSpacing.md),
                    Expanded(
                      child: Text(
                        label,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              color: foregroundColor,
                              fontSize: 13,
                              fontWeight:
                                  selected ? FontWeight.w800 : FontWeight.w600,
                              height: 1.15,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

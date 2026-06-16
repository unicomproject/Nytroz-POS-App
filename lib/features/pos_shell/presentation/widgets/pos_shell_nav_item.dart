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
            ? Colors.white70
            : Colors.white38;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Material(
        color: selected ? TenantAdminColors.info : Colors.transparent,
        borderRadius: BorderRadius.circular(TenantAdminRadius.lg),
        child: Tooltip(
          message: isEnabled ? label : '$label is not available yet',
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(TenantAdminRadius.lg),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 64),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: TenantAdminSpacing.xs,
                  vertical: TenantAdminSpacing.sm,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, color: foregroundColor, size: 24),
                    const SizedBox(height: TenantAdminSpacing.xs),
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: foregroundColor,
                            fontSize: 10,
                            fontWeight:
                                selected ? FontWeight.w700 : FontWeight.w600,
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

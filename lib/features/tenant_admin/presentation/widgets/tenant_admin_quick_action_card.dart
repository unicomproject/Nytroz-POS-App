import 'package:flutter/material.dart';

import '../theme/tenant_admin_theme.dart';

class TenantAdminQuickActionCard extends StatelessWidget {
  const TenantAdminQuickActionCard({
    super.key,
    required this.title,
    required this.icon,
    required this.onTap,
    this.subtitle,
    this.enabled = true,
  });

  final String title;
  final String? subtitle;
  final IconData icon;
  final VoidCallback? onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 160),
          opacity: enabled ? 1 : 0.5,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: TenantAdminColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: TenantAdminColors.border),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: TenantAdminColors.secondary,
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(icon, color: TenantAdminColors.primary, size: 19),
                ),
                const SizedBox(width: TenantAdminSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TenantAdminTextStyles.sectionTitle(context)
                            .copyWith(fontSize: 13),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: TenantAdminSpacing.xs),
                        Text(
                          subtitle!,
                          style: TenantAdminTextStyles.muted(context)
                              .copyWith(fontSize: 11),
                        ),
                      ],
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right,
                  color: TenantAdminColors.mutedText,
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

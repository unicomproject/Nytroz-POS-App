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
        hoverColor: TenantAdminColors.primary.withValues(alpha: 0.04),
        splashColor: TenantAdminColors.primary.withValues(alpha: 0.08),
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 160),
          opacity: enabled ? 1 : 0.5,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: TenantAdminColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: TenantAdminColors.border),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x06000000),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        TenantAdminColors.primary.withValues(alpha: 0.15),
                        TenantAdminColors.primary.withValues(alpha: 0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: TenantAdminColors.primary.withValues(alpha: 0.1),
                      width: 1,
                    ),
                  ),
                  child: Icon(icon, color: TenantAdminColors.primary, size: 20),
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

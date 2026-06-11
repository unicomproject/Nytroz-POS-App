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
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(TenantAdminRadius.lg),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 160),
        opacity: enabled ? 1 : 0.5,
        child: Container(
          padding: const EdgeInsets.all(TenantAdminSpacing.lg),
          decoration: BoxDecoration(
            color: TenantAdminColors.surface,
            borderRadius: BorderRadius.circular(TenantAdminRadius.lg),
            border: Border.all(color: TenantAdminColors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: TenantAdminColors.secondary,
                  borderRadius: BorderRadius.circular(TenantAdminRadius.md),
                ),
                child: Icon(icon, color: TenantAdminColors.primary),
              ),
              const SizedBox(width: TenantAdminSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: TenantAdminTextStyles.sectionTitle(context)),
                    if (subtitle != null) ...[
                      const SizedBox(height: TenantAdminSpacing.xs),
                      Text(subtitle!, style: TenantAdminTextStyles.muted(context)),
                    ],
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: TenantAdminColors.mutedText),
            ],
          ),
        ),
      ),
    );
  }
}

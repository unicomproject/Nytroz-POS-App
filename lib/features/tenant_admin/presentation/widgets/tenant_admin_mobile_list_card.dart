import 'package:flutter/material.dart';

import '../theme/tenant_admin_theme.dart';

class TenantAdminMobileListCard extends StatelessWidget {
  const TenantAdminMobileListCard({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.footer,
    this.onTap,
  });

  final String title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final Widget? footer;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(TenantAdminRadius.lg),
      child: Container(
        padding: const EdgeInsets.all(TenantAdminSpacing.lg),
        decoration: BoxDecoration(
          color: TenantAdminColors.surface,
          borderRadius: BorderRadius.circular(TenantAdminRadius.lg),
          border: Border.all(color: TenantAdminColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (leading != null) ...[
                  leading!,
                  const SizedBox(width: TenantAdminSpacing.md),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TenantAdminTextStyles.sectionTitle(context),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: TenantAdminSpacing.xs),
                        Text(
                          subtitle!,
                          style: TenantAdminTextStyles.muted(context),
                        ),
                      ],
                    ],
                  ),
                ),
                if (trailing != null) ...[
                  const SizedBox(width: TenantAdminSpacing.md),
                  trailing!,
                ],
              ],
            ),
            if (footer != null) ...[
              const SizedBox(height: TenantAdminSpacing.lg),
              footer!,
            ],
          ],
        ),
      ),
    );
  }
}

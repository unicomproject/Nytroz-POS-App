import 'package:flutter/material.dart';

import '../theme/tenant_admin_theme.dart';

class TenantAdminActivityItem extends StatelessWidget {
  const TenantAdminActivityItem({
    super.key,
    required this.title,
    required this.timeLabel,
    this.subtitle,
    this.icon = Icons.history,
  });

  final String title;
  final String? subtitle;
  final String timeLabel;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: TenantAdminColors.secondary,
          child: Icon(icon, size: 18, color: TenantAdminColors.primary),
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
        const SizedBox(width: TenantAdminSpacing.md),
        Text(timeLabel, style: TenantAdminTextStyles.muted(context)),
      ],
    );
  }
}

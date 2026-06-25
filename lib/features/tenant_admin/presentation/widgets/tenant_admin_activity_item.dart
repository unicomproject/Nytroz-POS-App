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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: TenantAdminColors.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: TenantAdminColors.secondary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 19, color: TenantAdminColors.primary),
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
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TenantAdminTextStyles.muted(context)
                        .copyWith(fontSize: 11),
                  ),
                ],
                const SizedBox(height: TenantAdminSpacing.sm),
                Text(
                  timeLabel,
                  style: TenantAdminTextStyles.muted(context).copyWith(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: TenantAdminSpacing.sm),
          const Icon(
            Icons.more_vert,
            color: TenantAdminColors.mutedText,
            size: 20,
          ),
        ],
      ),
    );
  }
}

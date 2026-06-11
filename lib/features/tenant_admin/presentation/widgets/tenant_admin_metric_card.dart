import 'package:flutter/material.dart';

import '../theme/tenant_admin_theme.dart';
import 'tenant_admin_status_badge.dart';

class TenantAdminMetricCard extends StatelessWidget {
  const TenantAdminMetricCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    this.subtitle,
    this.trend,
    this.status,
  });

  final String title;
  final String value;
  final String? subtitle;
  final IconData icon;
  final String? trend;
  final TenantAdminStatusType? status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(TenantAdminSpacing.lg),
      decoration: BoxDecoration(
        color: TenantAdminColors.surface,
        borderRadius: BorderRadius.circular(TenantAdminRadius.lg),
        border: Border.all(color: TenantAdminColors.border),
        boxShadow: TenantAdminShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
              const Spacer(),
              if (status != null)
                TenantAdminStatusBadge(label: status!.label, status: status!),
            ],
          ),
          const SizedBox(height: TenantAdminSpacing.lg),
          Text(
            title,
            style: TenantAdminTextStyles.muted(context),
          ),
          const SizedBox(height: TenantAdminSpacing.xs),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: TenantAdminColors.bodyText,
                ),
          ),
          if (subtitle != null || trend != null) ...[
            const SizedBox(height: TenantAdminSpacing.sm),
            Row(
              children: [
                if (trend != null)
                  Text(
                    trend!,
                    style: const TextStyle(
                      color: TenantAdminColors.success,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                if (trend != null && subtitle != null)
                  const SizedBox(width: TenantAdminSpacing.sm),
                if (subtitle != null)
                  Expanded(
                    child: Text(
                      subtitle!,
                      style: TenantAdminTextStyles.muted(context),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

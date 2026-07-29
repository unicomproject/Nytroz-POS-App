import 'package:flutter/material.dart';

import '../../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';
import '../../../application/state/pos_home_dashboard_state.dart';

class PosSessionStatusChip extends StatelessWidget {
  const PosSessionStatusChip({super.key, required this.dashboard});

  final PosHomeDashboardState dashboard;

  @override
  Widget build(BuildContext context) => Container(
        constraints: const BoxConstraints(minHeight: 58),
        padding: const EdgeInsets.symmetric(
          horizontal: TenantAdminSpacing.lg,
          vertical: TenantAdminSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: TenantAdminColors.posHomeDarkSurface,
          border: Border.all(color: TenantAdminColors.posHomeDarkBorder),
          borderRadius: BorderRadius.circular(TenantAdminRadius.md),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              dashboard.isTillOpen ? Icons.circle : Icons.cancel,
              color: dashboard.isTillOpen
                  ? TenantAdminColors.success
                  : TenantAdminColors.danger,
              size: 16,
            ),
            const SizedBox(width: TenantAdminSpacing.sm),
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dashboard.tillStatusLabel.toUpperCase(),
                  style: const TextStyle(
                    color: TenantAdminColors.surface,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  dashboard.isTillOpen ? 'Till Session' : 'Session Closed',
                  style: TextStyle(
                    color: TenantAdminColors.surface.withValues(alpha: 0.72),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
}

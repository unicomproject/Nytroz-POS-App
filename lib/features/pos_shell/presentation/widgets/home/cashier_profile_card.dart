import 'package:flutter/material.dart';

import '../../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';
import '../../../application/state/pos_home_dashboard_state.dart';
import 'cashier_profile_status.dart';

class CashierProfileCard extends StatelessWidget {
  const CashierProfileCard({super.key, required this.dashboard});

  final PosHomeDashboardState dashboard;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: TenantAdminSpacing.xl,
        vertical: TenantAdminSpacing.lg,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            TenantAdminColors.posHomeProfileBlueStart,
            TenantAdminColors.posHomeProfileBlueEnd,
          ],
        ),
        borderRadius: BorderRadius.circular(TenantAdminRadius.lg),
        border: Border.all(color: const Color(0x335CB8FF)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final avatarRadius = (constraints.maxHeight * 0.15).clamp(42.0, 64.0);
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: TenantAdminColors.surface.withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: TenantAdminColors.surface.withValues(alpha: 0.55),
                  ),
                ),
                child: CircleAvatar(
                  radius: avatarRadius,
                  backgroundColor: TenantAdminColors.surface,
                  child: Text(
                    _initials(dashboard.fallbackUserDisplayName),
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: TenantAdminColors.navy,
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                ),
              ),
              const SizedBox(height: TenantAdminSpacing.lg),
              Text(
                dashboard.fallbackUserDisplayName,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: TenantAdminColors.surface,
                      fontWeight: FontWeight.w900,
                    ),
              ),
              if (dashboard.cashierRoleLabel.isNotEmpty) ...[
                const SizedBox(height: TenantAdminSpacing.xs),
                Text(
                  dashboard.cashierRoleLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color:
                            TenantAdminColors.surface.withValues(alpha: 0.82),
                      ),
                ),
              ],
              const SizedBox(height: TenantAdminSpacing.xl),
              Container(
                constraints: const BoxConstraints(minHeight: 56),
                padding: const EdgeInsets.symmetric(
                  horizontal: TenantAdminSpacing.md,
                  vertical: TenantAdminSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: TenantAdminColors.navy.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(TenantAdminRadius.md),
                  border: Border.all(
                    color: TenantAdminColors.surface.withValues(alpha: 0.35),
                  ),
                ),
                child: CashierProfileStatus(
                  label: dashboard.deviceName.isEmpty
                      ? 'Terminal'
                      : dashboard.deviceName,
                  value: dashboard.deviceStatus.isEmpty
                      ? 'Connected'
                      : dashboard.deviceStatus,
                  online: dashboard.isTrustedDevice == true,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    return parts
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part[0])
        .join();
  }
}

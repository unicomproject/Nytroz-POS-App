import 'package:flutter/material.dart';

import '../../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';
import '../../../application/state/pos_home_dashboard_state.dart';

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
          final profileImageUrl = dashboard.cashierProfileImageUrl?.trim();
          final roleLabel = dashboard.cashierRoleLabel.trim().isEmpty
              ? 'Cashier'
              : dashboard.cashierRoleLabel.trim();
          final showRoleLabel = roleLabel.toLowerCase() !=
              dashboard.fallbackUserDisplayName.trim().toLowerCase();
          final hasProfileImage =
              profileImageUrl != null && profileImageUrl.isNotEmpty;
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
                child: SizedBox(
                  key: const Key('cashier-profile-avatar'),
                  width: avatarRadius * 2,
                  height: avatarRadius * 2,
                  child: ClipOval(
                    child: ColoredBox(
                      color: TenantAdminColors.surface,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Center(
                            child: Text(
                              _initials(dashboard.fallbackUserDisplayName),
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineMedium
                                  ?.copyWith(
                                    color: TenantAdminColors.navy,
                                    fontWeight: FontWeight.w900,
                                  ),
                            ),
                          ),
                          if (hasProfileImage)
                            Image.network(
                              profileImageUrl,
                              key: const Key('cashier-profile-image'),
                              fit: BoxFit.cover,
                              webHtmlElementStrategy:
                                  WebHtmlElementStrategy.fallback,
                              errorBuilder: (_, __, ___) =>
                                  const SizedBox.shrink(),
                            ),
                        ],
                      ),
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
              if (showRoleLabel) ...[
                const SizedBox(height: TenantAdminSpacing.xs),
                Text(
                  roleLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color:
                            TenantAdminColors.surface.withValues(alpha: 0.82),
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ],
              const SizedBox(height: TenantAdminSpacing.lg),
              SizedBox(
                width: 72,
                child: Divider(
                  height: 1,
                  thickness: 1,
                  color: TenantAdminColors.surface.withValues(alpha: 0.32),
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

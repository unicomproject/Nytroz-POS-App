import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';
import '../../../application/state/pos_home_dashboard_state.dart';
import 'cashier_profile_status.dart';

class CashierProfileCard extends StatefulWidget {
  const CashierProfileCard({super.key, required this.dashboard});

  final PosHomeDashboardState dashboard;

  @override
  State<CashierProfileCard> createState() => _CashierProfileCardState();
}

class _CashierProfileCardState extends State<CashierProfileCard> {
  String? _failedImageUrl;

  @override
  void didUpdateWidget(CashierProfileCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.dashboard.cashierProfileImageUrl !=
        widget.dashboard.cashierProfileImageUrl) {
      _failedImageUrl = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final dashboard = widget.dashboard;
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
          final hasProfileImage = profileImageUrl != null &&
              profileImageUrl.isNotEmpty &&
              _failedImageUrl != profileImageUrl;
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
                  key: const Key('cashier-profile-avatar'),
                  radius: avatarRadius,
                  backgroundColor: TenantAdminColors.surface,
                  foregroundImage:
                      hasProfileImage ? NetworkImage(profileImageUrl) : null,
                  onForegroundImageError: hasProfileImage
                      ? (exception, stackTrace) {
                          if (kDebugMode) {
                            developer.log(
                              'Cashier profile image load failed. '
                              'url=$profileImageUrl error=$exception',
                              name: 'pos.home.profile-image',
                              error: exception,
                              stackTrace: stackTrace,
                            );
                          }
                          if (mounted && _failedImageUrl != profileImageUrl) {
                            setState(() => _failedImageUrl = profileImageUrl);
                          }
                        }
                      : null,
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

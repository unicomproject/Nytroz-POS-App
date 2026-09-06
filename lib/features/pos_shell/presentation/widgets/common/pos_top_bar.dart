import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nytroz_pos/core/access/permission_gate.dart';
import 'package:nytroz_pos/core/access/pos_access_codes.dart';
import 'package:nytroz_pos/features/tenant_admin/presentation/theme/tenant_admin_theme.dart';
import '../../../application/state/pos_home_dashboard_state.dart';
import '../home/pos_branding.dart';
import 'pos_top_bar_notification_button.dart';

class PosTopBar extends ConsumerWidget {
  const PosTopBar({
    super.key,
    required this.content,
    this.dashboard,
    this.brandName,
    this.brandLogoUrl,
    this.trailing = const PosTopBarNotificationButton(dark: true),
  });

  final Widget content;
  final PosHomeDashboardState? dashboard;
  final String? brandName;
  final String? brandLogoUrl;
  final Widget? trailing;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      height: 96,
      decoration: const BoxDecoration(
        color: TenantAdminColors.posHomeDarkBackground,
        border: Border(
          bottom: BorderSide(
            color: TenantAdminColors.posHomeDarkBorder,
          ),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 1040;
          final veryCompact = constraints.maxWidth < 760;

          return Padding(
            padding: EdgeInsets.symmetric(
              horizontal:
                  veryCompact ? TenantAdminSpacing.md : TenantAdminSpacing.xl,
            ),
            child: Row(
              children: [
                PermissionGate(
                  permission: PosPermissionCodes.shellTopbarBrand,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minWidth: veryCompact ? 116 : 156,
                      maxWidth: compact ? 180 : 240,
                    ),
                    child: PosBranding(
                      dashboard: dashboard,
                      brandName: brandName,
                      logoUrl: brandLogoUrl,
                    ),
                  ),
                ),
                PermissionGate(
                  permission: PosPermissionCodes.shellTopbarBrand,
                  child: SizedBox(
                    width: veryCompact
                        ? TenantAdminSpacing.sm
                        : TenantAdminSpacing.lg,
                  ),
                ),
                Expanded(
                  child: content,
                ),
                if (trailing != null) trailing!,
              ],
            ),
          );
        },
      ),
    );
  }
}

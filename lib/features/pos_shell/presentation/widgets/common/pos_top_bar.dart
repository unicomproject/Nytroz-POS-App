import 'package:flutter/material.dart';

import 'package:nytroz_pos/features/tenant_admin/presentation/theme/tenant_admin_theme.dart';
import '../home/pos_branding.dart';
import 'pos_top_bar_notification_button.dart';

class PosTopBar extends StatelessWidget {
  const PosTopBar({
    super.key,
    required this.content,
    this.trailing = const PosTopBarNotificationButton(dark: true),
  });

  final Widget content;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
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
                ConstrainedBox(
                  constraints: BoxConstraints(
                    minWidth: veryCompact ? 116 : 156,
                    maxWidth: compact ? 180 : 240,
                  ),
                  child: const PosBranding(),
                ),
                SizedBox(
                  width: veryCompact
                      ? TenantAdminSpacing.sm
                      : TenantAdminSpacing.lg,
                ),
                Expanded(
                  child: content,
                ),
                if (trailing != null) ...[
                  SizedBox(
                    width: veryCompact
                        ? TenantAdminSpacing.sm
                        : TenantAdminSpacing.lg,
                  ),
                  trailing!,
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

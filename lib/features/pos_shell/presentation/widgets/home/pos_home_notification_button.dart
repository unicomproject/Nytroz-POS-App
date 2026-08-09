import 'package:flutter/material.dart';

import '../../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';

class PosHomeNotificationButton extends StatelessWidget {
  const PosHomeNotificationButton({
    super.key,
    required this.onPressed,
    required this.notificationCount,
  });

  final VoidCallback onPressed;
  final int notificationCount;

  static const _buttonSize = 48.0;
  static const _notificationIconSize = 25.0;
  static const _badgeSize = 18.0;
  static const _maxVisibleNotificationCount = 99;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: TenantAdminColors.surface,
      shape: const CircleBorder(
        side: BorderSide(color: TenantAdminColors.border),
      ),
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: _buttonSize,
          height: _buttonSize,
          child: Stack(
            alignment: Alignment.center,
            children: [
              const Icon(
                Icons.notifications_none_rounded,
                color: TenantAdminColors.bodyText,
                size: _notificationIconSize,
              ),
              if (notificationCount > 0)
                Positioned(
                  top: TenantAdminSpacing.sm,
                  right: TenantAdminSpacing.sm,
                  child: DecoratedBox(
                    decoration: const BoxDecoration(
                      color: TenantAdminColors.danger,
                      shape: BoxShape.circle,
                    ),
                    child: SizedBox(
                      width: _badgeSize,
                      height: _badgeSize,
                      child: Center(
                        child: Text(
                          notificationCount > _maxVisibleNotificationCount
                              ? '$_maxVisibleNotificationCount+'
                              : notificationCount.toString(),
                          style:
                              Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: TenantAdminColors.surface,
                                    fontWeight: FontWeight.w800,
                                    height: 1,
                                  ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

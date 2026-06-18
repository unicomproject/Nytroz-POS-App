import 'package:flutter/material.dart';

import '../../../domain/entities/tenant_admin_context.dart';
import '../../../domain/services/tenant_admin_access_checker.dart';
import '../../../presentation/theme/tenant_admin_theme.dart';

class TenantAdminDashboardHeaderActions extends StatelessWidget {
  const TenantAdminDashboardHeaderActions({
    super.key,
    required this.visibility,
    required this.onLogout,
    this.context,
    this.showLogoutOnly = false,
  });

  final TenantDashboardVisibility visibility;
  final TenantAdminContext? context;
  final VoidCallback onLogout;
  final bool showLogoutOnly;

  @override
  Widget build(BuildContext buildContext) {
    final actions = <Widget>[];

    if (visibility.showDateFilter) {
      actions.add(
        const _FilterChipButton(
          label: 'Today',
          icon: Icons.calendar_today,
        ),
      );
    }

    if (visibility.showOutletFilter) {
      actions.add(
        const _FilterChipButton(
          label: 'All outlets',
          icon: Icons.store,
        ),
      );
    }

    if (visibility.showNotifications) {
      actions.add(
        _NotificationBell(
          count: visibility.notificationCount,
          canRead: visibility.showNotificationReadAction,
        ),
      );
    }

    if (visibility.showProfile && context != null) {
      actions.add(
        _ProfileMenu(
          displayName: context!.userDisplayName,
          roleNames: context!.roleNames,
          onLogout: onLogout,
        ),
      );
    } else {
      actions.add(
        IconButton(
          onPressed: onLogout,
          tooltip: 'Logout',
          icon: const Icon(Icons.logout),
          color: TenantAdminColors.bodyText,
        ),
      );
    }

    if (actions.isEmpty) {
      return const SizedBox.shrink();
    }

    return Wrap(
      spacing: TenantAdminSpacing.sm,
      runSpacing: TenantAdminSpacing.sm,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: actions,
    );
  }
}

class _FilterChipButton extends StatelessWidget {
  const _FilterChipButton({
    required this.label,
    required this.icon,
  });

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () {},
      icon: Icon(icon, size: 16),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: TenantAdminColors.bodyText,
        side: const BorderSide(color: TenantAdminColors.border),
        padding: const EdgeInsets.symmetric(
          horizontal: TenantAdminSpacing.md,
          vertical: TenantAdminSpacing.sm,
        ),
      ),
    );
  }
}

class _NotificationBell extends StatelessWidget {
  const _NotificationBell({
    required this.count,
    required this.canRead,
  });

  final int? count;
  final bool canRead;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          onPressed: canRead ? () {} : null,
          icon: const Icon(Icons.notifications_none),
          color: TenantAdminColors.bodyText,
        ),
        if (count != null && count! > 0)
          Positioned(
            right: 6,
            top: 6,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
              child: Text(
                count! > 99 ? '99+' : '$count',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _ProfileMenu extends StatelessWidget {
  const _ProfileMenu({
    required this.displayName,
    required this.roleNames,
    required this.onLogout,
  });

  final String displayName;
  final List<String> roleNames;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final initials = displayName
        .split(' ')
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part[0].toUpperCase())
        .join();

    return PopupMenuButton<String>(
      offset: const Offset(0, 48),
      itemBuilder: (context) => [
        const PopupMenuItem(
          enabled: false,
          child: Text('Account'),
        ),
        PopupMenuItem(
          value: 'logout',
          onTap: onLogout,
          child: const Text('Logout'),
        ),
      ],
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: TenantAdminColors.primary,
            child: Text(
              initials,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: TenantAdminSpacing.sm),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                displayName,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: TenantAdminColors.bodyText,
                ),
              ),
              if (roleNames.isNotEmpty)
                Text(
                  roleNames.first,
                  style: TenantAdminTextStyles.muted(context),
                ),
            ],
          ),
          const Icon(Icons.keyboard_arrow_down),
        ],
      ),
    );
  }
}

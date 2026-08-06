import 'package:flutter/material.dart';

import '../../../domain/services/tenant_admin_access_checker.dart';
import '../../../presentation/theme/tenant_admin_theme.dart';
import '../../domain/entities/tenant_user.dart';
import '../config/user_row_action_configs.dart';
import '../utils/user_api_errors.dart';
import 'user_status_badge.dart';

class UserTable extends StatelessWidget {
  const UserTable({
    super.key,
    required this.users,
    required this.visibility,
    required this.onView,
    required this.onEdit,
    required this.onDelete,
  });

  final List<TenantUser> users;
  final UserListVisibility visibility;
  final ValueChanged<TenantUser> onView;
  final ValueChanged<TenantUser> onEdit;
  final ValueChanged<TenantUser> onDelete;

  @override
  Widget build(BuildContext context) {
    final canView = visibility.visibleRowActions.any(
      (action) => action.actionId == UserRowActionId.viewDetails,
    );
    final canEdit = visibility.visibleRowActions.any(
      (action) => action.actionId == UserRowActionId.edit,
    );
    final canDelete = visibility.visibleRowActions.any(
      (action) => action.actionId == UserRowActionId.delete,
    );

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowHeight: 48,
        dataRowMinHeight: 60,
        dataRowMaxHeight: 66,
        columnSpacing: TenantAdminSpacing.xl,
        horizontalMargin: TenantAdminSpacing.lg,
        headingTextStyle: const TextStyle(
          color: TenantAdminColors.bodyText,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
        dataTextStyle: const TextStyle(
          color: TenantAdminColors.bodyText,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        columns: const [
          DataColumn(label: Text('User')),
          DataColumn(label: Text('Role')),
          DataColumn(label: Text('Outlet')),
          DataColumn(label: Text('Status')),
          DataColumn(label: Text('Last Active')),
          DataColumn(
            label: Align(
              alignment: Alignment.centerRight,
              child: Text('Actions'),
            ),
          ),
        ],
        rows: [
          for (final user in users)
            DataRow(
              cells: [
                DataCell(
                  _UserIdentityCell(user: user, canView: canView),
                  onTap: canView ? () => onView(user) : null,
                ),
                DataCell(_PlainCell(_emptyDash(user.roleName))),
                DataCell(_PlainCell(_emptyDash(user.outletName))),
                DataCell(UserStatusBadge(status: user.status)),
                DataCell(_PlainCell(formatUserLastActive(user.lastActiveAt))),
                DataCell(
                  Align(
                    alignment: Alignment.centerRight,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (canView)
                          _ActionIconButton(
                            icon: Icons.visibility_outlined,
                            tooltip: 'View details',
                            onPressed: () => onView(user),
                          ),
                        if (canEdit) ...[
                          const SizedBox(width: TenantAdminSpacing.sm),
                          _ActionIconButton(
                            icon: Icons.edit_outlined,
                            tooltip: 'Edit user',
                            onPressed: () => onEdit(user),
                          ),
                        ],
                        if (canDelete) ...[
                          const SizedBox(width: TenantAdminSpacing.sm),
                          _ActionIconButton(
                            icon: Icons.delete_outline,
                            tooltip: 'Delete user',
                            destructive: true,
                            onPressed: () => onDelete(user),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _UserIdentityCell extends StatelessWidget {
  const _UserIdentityCell({required this.user, required this.canView});

  final TenantUser user;
  final bool canView;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(
          radius: 16,
          backgroundColor: TenantAdminColors.secondary,
          child: Text(
            _initials(user.fullName),
            style: const TextStyle(
              color: TenantAdminColors.primary,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
        ),
        const SizedBox(width: TenantAdminSpacing.sm),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 220),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                user.fullName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: canView
                      ? TenantAdminColors.primary
                      : TenantAdminColors.bodyText,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                user.email,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TenantAdminTextStyles.muted(context),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PlainCell extends StatelessWidget {
  const _PlainCell(this.value);

  final String value;

  @override
  Widget build(BuildContext context) {
    return Text(value, maxLines: 1, overflow: TextOverflow.ellipsis);
  }
}

class _ActionIconButton extends StatelessWidget {
  const _ActionIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.destructive = false,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      style: IconButton.styleFrom(
        backgroundColor: TenantAdminColors.surface,
        foregroundColor:
            destructive ? TenantAdminColors.danger : TenantAdminColors.primary,
        side: BorderSide(
          color: destructive
              ? TenantAdminColors.danger.withValues(alpha: 0.25)
              : TenantAdminColors.border,
        ),
        minimumSize: const Size(32, 32),
        padding: EdgeInsets.zero,
      ),
      icon: Icon(icon, size: 16),
    );
  }
}

String _emptyDash(String value) {
  final trimmed = value.trim();
  return trimmed.isEmpty ? '—' : trimmed;
}

String _initials(String fullName) {
  final parts =
      fullName.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
  if (parts.isEmpty) {
    return '?';
  }

  if (parts.length == 1) {
    return parts.first.substring(0, 1).toUpperCase();
  }

  return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
      .toUpperCase();
}

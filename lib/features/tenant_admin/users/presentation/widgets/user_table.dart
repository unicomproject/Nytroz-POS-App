import 'package:flutter/material.dart';

import '../../../domain/services/tenant_admin_access_checker.dart';
import '../../../presentation/theme/tenant_admin_theme.dart';
import '../../../presentation/widgets/tenant_admin_data_table.dart';
import '../../../presentation/widgets/tenant_admin_row_action.dart';
import '../../domain/entities/tenant_user.dart';
import '../config/user_row_action_configs.dart';
import '../utils/user_api_errors.dart';
import 'tenant_user_avatar.dart';
import 'user_status_badge.dart';

class UserTable extends StatelessWidget {
  const UserTable({
    super.key,
    required this.users,
    required this.visibility,
    required this.selectedUserId,
    required this.onView,
    required this.onEdit,
    required this.onDelete,
  });

  final List<TenantUser> users;
  final UserListVisibility visibility;
  final String? selectedUserId;
  final ValueChanged<TenantUser> onView;
  final ValueChanged<TenantUser> onEdit;
  final ValueChanged<TenantUser> onDelete;

  @override
  Widget build(BuildContext context) {
    final canView = visibility.visibleRowActions
        .any((action) => action.actionId == UserRowActionId.viewDetails);
    final canEdit = visibility.visibleRowActions
        .any((action) => action.actionId == UserRowActionId.edit);
    final canDeactivate = visibility.visibleRowActions
        .any((action) => action.actionId == UserRowActionId.delete);

    return TenantAdminDataTable(
      showCheckboxColumn: false,
      emptyTitle: 'No users found',
      emptyMessage: 'Add a new user or adjust your search.',
      minWidth: 1000,
      columns: const [
        DataColumn(label: Text('USER')),
        DataColumn(label: Text('ROLE')),
        DataColumn(label: Text('OUTLET ACCESS')),
        DataColumn(label: Text('LAST ACTIVE')),
        DataColumn(label: Text('STATUS')),
        DataColumn(label: Text('ACTIONS')),
      ],
      rows: users.map((user) {
        return DataRow(
          selected: user.id == selectedUserId,
          onSelectChanged: canView ? (_) => onView(user) : null,
          cells: [
            DataCell(_Identity(user: user)),
            DataCell(_Role(user: user)),
            DataCell(_OutletAccess(user: user)),
            DataCell(_LastActive(user: user)),
            DataCell(UserStatusBadge(status: user.status)),
            DataCell(
              Align(
                alignment: Alignment.centerRight,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (canView)
                      TenantAdminRowAction(
                        icon: Icons.visibility_outlined,
                        label: 'View',
                        onPressed: () => onView(user),
                      ),
                    if (canEdit) const SizedBox(width: TenantAdminSpacing.sm),
                    if (canEdit)
                      TenantAdminRowAction(
                        icon: Icons.edit_outlined,
                        label: 'Edit',
                        onPressed: () => onEdit(user),
                      ),
                    if (canEdit && canDeactivate)
                      const SizedBox(width: TenantAdminSpacing.sm),
                    if (canDeactivate)
                      TenantAdminRowAction(
                        icon: Icons.block_outlined,
                        label: 'Disable',
                        destructive: true,
                        onPressed: () => onDelete(user),
                      ),
                  ],
                ),
              ),
            ),
          ],
        );
      }).toList(),
    );
  }
}

class _Identity extends StatelessWidget {
  const _Identity({required this.user});

  final TenantUser user;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          TenantUserAvatar(
            fullName: user.fullName,
            imageUrl: user.profileImageUrl,
            radius: 19,
          ),
          const SizedBox(width: TenantAdminSpacing.md),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.fullName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: TenantAdminColors.bodyText,
                  ),
                ),
                Text(
                  user.email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TenantAdminTextStyles.muted(context)
                      .copyWith(fontSize: 12),
                ),
                if ((user.phone ?? '').trim().isNotEmpty)
                  Text(
                    user.phone!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TenantAdminTextStyles.muted(context)
                        .copyWith(fontSize: 12),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Role extends StatelessWidget {
  const _Role({required this.user});

  final TenantUser user;

  @override
  Widget build(BuildContext context) => _TwoLineCell(
        primary: _dash(user.roleName),
        secondary: _nonEmpty(user.roleDescription),
      );
}

class _OutletAccess extends StatelessWidget {
  const _OutletAccess({required this.user});

  final TenantUser user;

  @override
  Widget build(BuildContext context) {
    final names = user.outlets
        .map((outlet) => outlet.name)
        .where((name) => name.trim().isNotEmpty)
        .toList();
    final count = user.outletCount ?? names.length;
    return _TwoLineCell(
      primary:
          names.isNotEmpty ? names.take(2).join(', ') : _dash(user.outletName),
      secondary:
          count > 0 ? '$count ${count == 1 ? 'Outlet' : 'Outlets'}' : null,
    );
  }
}

class _LastActive extends StatelessWidget {
  const _LastActive({required this.user});

  final TenantUser user;

  @override
  Widget build(BuildContext context) => _TwoLineCell(
        primary: formatUserLastActive(user.lastActiveAt),
        secondary: user.lastActiveAt == null
            ? null
            : formatUserDate(user.lastActiveAt),
      );
}

class _TwoLineCell extends StatelessWidget {
  const _TwoLineCell({required this.primary, this.secondary});

  final String primary;
  final String? secondary;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              primary,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: TenantAdminColors.bodyText,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
            if (secondary != null)
              Text(
                secondary!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TenantAdminTextStyles.muted(context)
                    .copyWith(fontSize: 12),
              ),
          ],
        ),
      );
}

String? _nonEmpty(String? value) =>
    value?.trim().isNotEmpty == true ? value!.trim() : null;
String _dash(String value) => value.trim().isEmpty ? '—' : value.trim();

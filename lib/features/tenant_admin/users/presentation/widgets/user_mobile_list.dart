import 'package:flutter/material.dart';

import '../../../domain/services/tenant_admin_access_checker.dart';
import '../../../presentation/theme/tenant_admin_theme.dart';
import '../../../presentation/widgets/tenant_admin_management_card.dart';
import '../../domain/entities/tenant_user.dart';
import '../config/user_row_action_configs.dart';
import '../utils/user_api_errors.dart';
import 'tenant_user_avatar.dart';
import 'user_status_badge.dart';

class UserMobileList extends StatelessWidget {
  const UserMobileList(
      {super.key,
      required this.users,
      required this.visibility,
      required this.onView,
      required this.onEdit,
      required this.onDelete,
      this.selectedUserId});
  final List<TenantUser> users;
  final UserListVisibility visibility;
  final ValueChanged<TenantUser> onView;
  final ValueChanged<TenantUser> onEdit;
  final ValueChanged<TenantUser> onDelete;
  final String? selectedUserId;

  @override
  Widget build(BuildContext context) => Column(
        children: [
          for (final user in users) ...[
            _UserMobileListItem(
              user: user,
              visibility: visibility,
              onView: onView,
              onEdit: onEdit,
              onDelete: onDelete,
              selected: user.id == selectedUserId),
          const SizedBox(height: TenantAdminSpacing.md),
        ],
      );
}

class _UserMobileListItem extends StatelessWidget {
  const _UserMobileListItem(
      {required this.user,
      required this.visibility,
      required this.onView,
      required this.onEdit,
      required this.onDelete,
      required this.selected});
  final TenantUser user;
  final UserListVisibility visibility;
  final ValueChanged<TenantUser> onView;
  final ValueChanged<TenantUser> onEdit;
  final ValueChanged<TenantUser> onDelete;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final canView = visibility.visibleRowActions
        .any((action) => action.actionId == UserRowActionId.viewDetails);
    final canEdit = visibility.visibleRowActions
        .any((action) => action.actionId == UserRowActionId.edit);
    final canDelete = visibility.visibleRowActions
        .any((action) => action.actionId == UserRowActionId.delete);
    return TenantAdminManagementCard(
      title: user.fullName,
      badge: Text(_emptyDash(user.staffCode ?? user.email),
          style: TenantAdminTextStyles.muted(context).copyWith(fontSize: 12)),
      leading: TenantUserAvatar(
        fullName: user.fullName,
        imageUrl: user.profileImageUrl,
        radius: 28,
      ),
      metrics: [
        TenantAdminManagementCardMetric(
          label: 'Role',
          icon: Icons.admin_panel_settings_outlined,
          value: Text(_emptyDash(user.roleName)),
        ),
        TenantAdminManagementCardMetric(
          label: 'Outlet',
          icon: Icons.storefront_outlined,
          value: Text(_emptyDash(user.outletName)),
        ),
        TenantAdminManagementCardMetric(
          label: 'Last active',
          icon: Icons.schedule_outlined,
          value: Text(formatUserLastActive(user.lastActiveAt)),
        ),
      ],
      status: UserStatusBadge(status: user.status),
      actions: [
        if (canView)
          TenantAdminManagementCardAction(
            label: 'View',
            icon: Icons.visibility_outlined,
            onPressed: () => onView(user),
          ),
        if (canEdit)
          TenantAdminManagementCardAction(
            label: 'Edit',
            icon: Icons.edit_outlined,
            onPressed: () => onEdit(user),
          ),
        if (canDelete)
          TenantAdminManagementCardAction(
            label: 'Disable',
            icon: Icons.block_outlined,
            color: TenantAdminColors.danger,
            onPressed: () => onDelete(user),
          ),
      ],
      onTap: canView ? () => onView(user) : null,
      selected: selected,
    );
  }
}

String _emptyDash(String value) {
  final trimmed = value.trim();
  return trimmed.isEmpty ? '-' : trimmed;
}

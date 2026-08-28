import 'package:flutter/material.dart';

import '../../../domain/services/tenant_admin_access_checker.dart';
import '../../../presentation/theme/tenant_admin_theme.dart';
import '../../../presentation/widgets/tenant_admin_buttons.dart';
import '../../../presentation/widgets/tenant_admin_mobile_list_card.dart';
import '../../domain/entities/tenant_user.dart';
import '../config/user_row_action_configs.dart';
import '../utils/user_api_errors.dart';
import 'user_avatar.dart';
import 'user_status_badge.dart';

class UserMobileList extends StatelessWidget {
  const UserMobileList({
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
    return Column(
      children: [
        for (final user in users) ...[
          _UserMobileListItem(
            user: user,
            visibility: visibility,
            onView: onView,
            onEdit: onEdit,
            onDelete: onDelete,
          ),
          const SizedBox(height: TenantAdminSpacing.md),
        ],
      ],
    );
  }
}

class _UserMobileListItem extends StatelessWidget {
  const _UserMobileListItem({
    required this.user,
    required this.visibility,
    required this.onView,
    required this.onEdit,
    required this.onDelete,
  });

  final TenantUser user;
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

    return TenantAdminMobileListCard(
      title: user.fullName,
      subtitle: user.email,
      onTap: canView ? () => onView(user) : null,
      leading: UserAvatar(
        user: user,
        radius: 20,
        fallbackIcon: Icons.person_outline,
      ),
      trailing: UserStatusBadge(status: user.status),
      footer: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${_emptyDash(user.roleName)} • ${_emptyDash(user.outletName)}',
            style: TenantAdminTextStyles.muted(context),
          ),
          const SizedBox(height: TenantAdminSpacing.sm),
          Text(
            'Last active: ${formatUserLastActive(user.lastActiveAt)}',
            style: TenantAdminTextStyles.muted(context),
          ),
          if (canView || canEdit || canDelete) ...[
            const SizedBox(height: TenantAdminSpacing.md),
            Wrap(
              spacing: TenantAdminSpacing.sm,
              runSpacing: TenantAdminSpacing.sm,
              children: [
                if (canView)
                  TenantAdminSecondaryButton(
                    label: 'View',
                    icon: Icons.visibility_outlined,
                    onPressed: () => onView(user),
                  ),
                if (canEdit)
                  TenantAdminSecondaryButton(
                    label: 'Edit',
                    icon: Icons.edit_outlined,
                    onPressed: () => onEdit(user),
                  ),
                if (canDelete)
                  TenantAdminSecondaryButton(
                    label: 'Delete',
                    icon: Icons.delete_outline,
                    onPressed: () => onDelete(user),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

String _emptyDash(String value) {
  final trimmed = value.trim();
  return trimmed.isEmpty ? '—' : trimmed;
}

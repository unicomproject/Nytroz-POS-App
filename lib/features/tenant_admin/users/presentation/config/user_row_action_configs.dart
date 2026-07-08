import 'package:flutter/material.dart';

import '../../../../../core/access/tenant_admin_access_codes.dart';
import 'user_permission_config.dart';

enum UserRowActionId {
  viewDetails,
  edit,
  delete,
}

class UserRowActionConfig extends UserWidgetPermissionConfig {
  const UserRowActionConfig({
    required super.id,
    required this.actionId,
    required this.label,
    required this.icon,
    super.permission,
    super.permissionsAny = const [],
  });

  final UserRowActionId actionId;
  final String label;
  final IconData icon;
}

const userRowActionConfigs = <UserRowActionConfig>[
  UserRowActionConfig(
    id: 'view_details',
    actionId: UserRowActionId.viewDetails,
    label: 'View details',
    icon: Icons.visibility_outlined,
    permissionsAny: [
      TenantAdminPermissionCodes.tenantUsersDetailsView,
      TenantAdminPermissionCodes.userView,
      TenantAdminPermissionCodes.tenantUsersView,
    ],
  ),
  UserRowActionConfig(
    id: 'edit',
    actionId: UserRowActionId.edit,
    label: 'Edit',
    icon: Icons.edit_outlined,
    // Intentionally excludes tenant.user.manage: its alias expansion
    // includes granular view permissions, which would let view-only
    // users see the edit action. See canUpdateUser() for details.
    permission: TenantAdminPermissionCodes.tenantUsersUpdate,
  ),
  UserRowActionConfig(
    id: 'delete',
    actionId: UserRowActionId.delete,
    label: 'Delete',
    icon: Icons.delete_outline,
    permission: TenantAdminPermissionCodes.tenantUsersDelete,
  ),
];

List<UserRowActionConfig> visibleUserRowActions(
  bool Function(String permissionCode) can,
  bool Function(Iterable<String> permissionCodes) canAny,
) {
  return filterUserConfigs(userRowActionConfigs, can, canAny);
}

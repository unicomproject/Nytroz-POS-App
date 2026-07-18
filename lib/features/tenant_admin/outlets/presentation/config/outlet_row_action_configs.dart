import 'package:flutter/material.dart';

import '../../../../../core/access/tenant_admin_access_codes.dart';
import 'outlet_permission_config.dart';

enum OutletRowActionId {
  viewDetails,
  edit,
  toggleStatus,
  delete,
  manageTills,
  manageStaff,
}

class OutletRowActionConfig extends OutletWidgetPermissionConfig {
  const OutletRowActionConfig({
    required super.id,
    required this.actionId,
    required this.label,
    required this.icon,
    super.permission,
    super.permissionsAny = const [],
  });

  final OutletRowActionId actionId;
  final String label;
  final IconData icon;
}

const outletRowActionConfigs = <OutletRowActionConfig>[
  OutletRowActionConfig(
    id: 'view_details',
    actionId: OutletRowActionId.viewDetails,
    label: 'View details',
    icon: Icons.visibility,
    permission: TenantAdminPermissionCodes.outletDetailView,
  ),
  OutletRowActionConfig(
    id: 'edit',
    actionId: OutletRowActionId.edit,
    label: 'Edit outlet',
    icon: Icons.edit,
    permission: TenantAdminPermissionCodes.outletUpdate,
  ),
  OutletRowActionConfig(
    id: 'delete',
    actionId: OutletRowActionId.delete,
    label: 'Delete outlet',
    icon: Icons.delete_outline,
    permission: TenantAdminPermissionCodes.outletDelete,
  ),
  OutletRowActionConfig(
    id: 'manage_tills',
    actionId: OutletRowActionId.manageTills,
    label: 'Manage tills',
    icon: Icons.payment,
    permission: TenantAdminPermissionCodes.tillView,
  ),
  OutletRowActionConfig(
    id: 'manage_staff',
    actionId: OutletRowActionId.manageStaff,
    label: 'Manage staff',
    icon: Icons.people,
    permission: TenantAdminPermissionCodes.userView,
  ),
];

List<OutletRowActionConfig> visibleOutletRowActions(
  bool Function(String permissionCode) can,
  bool Function(Iterable<String> permissionCodes) canAny,
) {
  return filterOutletConfigs(outletRowActionConfigs, can, canAny);
}

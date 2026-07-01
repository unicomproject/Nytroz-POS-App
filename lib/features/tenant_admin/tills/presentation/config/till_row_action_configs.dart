import 'package:flutter/material.dart';

import '../../../../../core/access/tenant_admin_access_codes.dart';
import 'till_permission_config.dart';

enum TillRowActionId {
  viewDetails,
  edit,
  delete,
  generateActivationCode,
}

class TillRowActionConfig extends TillWidgetPermissionConfig {
  const TillRowActionConfig({
    required super.id,
    required this.actionId,
    required this.label,
    required this.icon,
    super.permission,
    super.permissionsAny = const [],
    this.showInMoreMenu = false,
  });

  final TillRowActionId actionId;
  final String label;
  final IconData icon;
  final bool showInMoreMenu;
}

const tillRowActionConfigs = <TillRowActionConfig>[
  TillRowActionConfig(
    id: 'view_details',
    actionId: TillRowActionId.viewDetails,
    label: 'View details',
    icon: Icons.visibility_outlined,
    permission: TenantAdminPermissionCodes.tillView,
  ),
  TillRowActionConfig(
    id: 'edit',
    actionId: TillRowActionId.edit,
    label: 'Edit',
    icon: Icons.edit_outlined,
    permission: TenantAdminPermissionCodes.tillUpdate,
  ),
  TillRowActionConfig(
    id: 'delete',
    actionId: TillRowActionId.delete,
    label: 'Delete',
    icon: Icons.delete_outline,
    permission: TenantAdminPermissionCodes.tillDelete,
    showInMoreMenu: true,
  ),
  TillRowActionConfig(
    id: 'generate_activation_code',
    actionId: TillRowActionId.generateActivationCode,
    label: 'Generate activation code',
    icon: Icons.qr_code_2_outlined,
    permission: TenantAdminPermissionCodes.tillActivationCodeGenerate,
    showInMoreMenu: true,
  ),
];

List<TillRowActionConfig> visibleTillRowActions(
  bool Function(String permissionCode) can,
  bool Function(Iterable<String> permissionCodes) canAny,
) {
  return filterTillConfigs(tillRowActionConfigs, can, canAny);
}

List<TillRowActionConfig> visibleTillInlineActions(
  bool Function(String permissionCode) can,
  bool Function(Iterable<String> permissionCodes) canAny,
) {
  return visibleTillRowActions(can, canAny)
      .where((action) => !action.showInMoreMenu)
      .toList(growable: false);
}

List<TillRowActionConfig> visibleTillMoreMenuActions(
  bool Function(String permissionCode) can,
  bool Function(Iterable<String> permissionCodes) canAny,
) {
  return visibleTillRowActions(can, canAny)
      .where((action) => action.showInMoreMenu)
      .toList(growable: false);
}

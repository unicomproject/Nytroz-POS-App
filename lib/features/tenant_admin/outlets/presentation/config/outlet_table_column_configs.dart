import '../../../../../core/access/tenant_admin_access_codes.dart';
import 'outlet_permission_config.dart';

enum OutletTableColumnId {
  name,
  code,
  city,
  location,
  status,
  tills,
  staff,
  sales,
  actions,
}

class OutletTableColumnConfig extends OutletWidgetPermissionConfig {
  const OutletTableColumnConfig({
    required super.id,
    required this.columnId,
    required this.label,
    super.permission,
    super.permissionsAny = const [],
    this.sortKey,
  });

  final OutletTableColumnId columnId;
  final String label;
  final String? sortKey;
}

const outletTableColumnConfigs = <OutletTableColumnConfig>[
  OutletTableColumnConfig(
    id: 'name',
    columnId: OutletTableColumnId.name,
    label: 'Outlet Name',
    permission: TenantAdminPermissionCodes.outletView,
    sortKey: 'name',
  ),
  OutletTableColumnConfig(
    id: 'code',
    columnId: OutletTableColumnId.code,
    label: 'Outlet Code',
    permission: TenantAdminPermissionCodes.outletView,
    sortKey: 'code',
  ),
  OutletTableColumnConfig(
    id: 'city',
    columnId: OutletTableColumnId.city,
    label: 'City',
    permission: TenantAdminPermissionCodes.outletLocationView,
  ),
  OutletTableColumnConfig(
    id: 'status',
    columnId: OutletTableColumnId.status,
    label: 'Status',
    permission: TenantAdminPermissionCodes.outletStatusView,
    sortKey: 'status',
  ),
];

List<OutletTableColumnConfig> visibleOutletTableColumns(
  bool Function(String permissionCode) can,
  bool Function(Iterable<String> permissionCodes) canAny, {
  required bool showActionsColumn,
}) {
  final columns = filterOutletConfigs(outletTableColumnConfigs, can, canAny);

  if (showActionsColumn) {
    return [
      ...columns,
      const OutletTableColumnConfig(
        id: 'actions',
        columnId: OutletTableColumnId.actions,
        label: 'Actions',
      ),
    ];
  }

  return columns;
}

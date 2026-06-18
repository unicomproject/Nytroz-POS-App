import '../../../../../core/access/tenant_admin_access_codes.dart';
import 'outlet_permission_config.dart';

enum OutletTableColumnId {
  name,
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
  });

  final OutletTableColumnId columnId;
  final String label;
}

const outletTableColumnConfigs = <OutletTableColumnConfig>[
  OutletTableColumnConfig(
    id: 'name',
    columnId: OutletTableColumnId.name,
    label: 'Outlet Name',
    permission: TenantAdminPermissionCodes.outletView,
  ),
  OutletTableColumnConfig(
    id: 'location',
    columnId: OutletTableColumnId.location,
    label: 'Location',
    permission: TenantAdminPermissionCodes.outletLocationView,
  ),
  OutletTableColumnConfig(
    id: 'status',
    columnId: OutletTableColumnId.status,
    label: 'Status',
    permission: TenantAdminPermissionCodes.outletStatusView,
  ),
  OutletTableColumnConfig(
    id: 'tills',
    columnId: OutletTableColumnId.tills,
    label: 'Tills',
    permissionsAny: [
      TenantAdminPermissionCodes.tillView,
      TenantAdminPermissionCodes.outletTillSummaryView,
    ],
  ),
  OutletTableColumnConfig(
    id: 'staff',
    columnId: OutletTableColumnId.staff,
    label: 'Staff',
    permissionsAny: [
      TenantAdminPermissionCodes.userView,
      TenantAdminPermissionCodes.outletStaffSummaryView,
    ],
  ),
  OutletTableColumnConfig(
    id: 'sales',
    columnId: OutletTableColumnId.sales,
    label: "Today's Sales",
    permission: TenantAdminPermissionCodes.outletSalesSummaryView,
  ),
];

List<OutletTableColumnConfig> visibleOutletTableColumns(
  bool Function(String permissionCode) can,
  bool Function(Iterable<String> permissionCodes) canAny, {
  required bool showActionsColumn,
}) {
  final columns =
      filterOutletConfigs(outletTableColumnConfigs, can, canAny);

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

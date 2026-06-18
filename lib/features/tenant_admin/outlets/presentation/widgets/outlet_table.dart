import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../domain/entities/outlet.dart';
import '../../../presentation/widgets/tenant_admin_data_table.dart';
import '../../../presentation/widgets/tenant_admin_status_badge.dart';
import '../config/outlet_row_action_configs.dart';
import '../config/outlet_table_column_configs.dart';

class OutletTable extends StatelessWidget {
  const OutletTable({
    super.key,
    required this.outlets,
    required this.columns,
    required this.rowActions,
  });

  final List<Outlet> outlets;
  final List<OutletTableColumnConfig> columns;
  final List<OutletRowActionConfig> rowActions;

  @override
  Widget build(BuildContext context) {
    return TenantAdminDataTable(
      emptyTitle: 'No outlets found',
      emptyMessage: 'Create an outlet or adjust your search/filter.',
      columns: [
        for (final column in columns)
          DataColumn(label: Text(column.label)),
      ],
      rows: [
        for (final outlet in outlets)
          DataRow(
            cells: [
              for (final column in columns)
                _buildCell(context, column, outlet),
            ],
          ),
      ],
    );
  }

  DataCell _buildCell(
    BuildContext context,
    OutletTableColumnConfig column,
    Outlet outlet,
  ) {
    switch (column.columnId) {
      case OutletTableColumnId.name:
        return DataCell(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(outlet.name),
              Text(outlet.code),
            ],
          ),
          onTap: () => context.go('/tenant-admin/outlets/${outlet.id}'),
        );
      case OutletTableColumnId.location:
        return DataCell(Text(outlet.location));
      case OutletTableColumnId.status:
        return DataCell(
          TenantAdminStatusBadge(
            label: outlet.status,
            status: _statusType(outlet.status),
          ),
        );
      case OutletTableColumnId.tills:
        return DataCell(Text('${outlet.tillCount}'));
      case OutletTableColumnId.staff:
        return DataCell(Text('${outlet.staffCount}'));
      case OutletTableColumnId.sales:
        return DataCell(Text(outlet.todaysSales));
      case OutletTableColumnId.actions:
        return DataCell(
          PopupMenuButton<OutletRowActionId>(
            icon: const Icon(Icons.more_vert),
            tooltip: 'Actions',
            itemBuilder: (context) {
              return [
                for (final action in rowActions)
                  PopupMenuItem<OutletRowActionId>(
                    value: action.actionId,
                    child: ListTile(
                      leading: Icon(action.icon),
                      title: Text(action.label),
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                    ),
                  ),
              ];
            },
            onSelected: (actionId) =>
                _handleAction(context, actionId, outlet),
          ),
        );
    }
  }

  void _handleAction(
    BuildContext context,
    OutletRowActionId actionId,
    Outlet outlet,
  ) {
    switch (actionId) {
      case OutletRowActionId.viewDetails:
        context.go('/tenant-admin/outlets/${outlet.id}');
      case OutletRowActionId.edit:
        context.go('/tenant-admin/outlets/${outlet.id}/edit');
      case OutletRowActionId.manageTills:
        context.go('/tenant-admin/tills');
      case OutletRowActionId.manageStaff:
        context.go('/tenant-admin/staff');
      case OutletRowActionId.toggleStatus:
      case OutletRowActionId.delete:
        break;
    }
  }
}

TenantAdminStatusType _statusType(String status) {
  switch (status.toLowerCase()) {
    case 'active':
      return TenantAdminStatusType.active;
    case 'inactive':
      return TenantAdminStatusType.inactive;
    case 'pending':
      return TenantAdminStatusType.pending;
    default:
      return TenantAdminStatusType.warning;
  }
}

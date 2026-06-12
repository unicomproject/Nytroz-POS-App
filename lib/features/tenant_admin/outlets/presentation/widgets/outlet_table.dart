import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../domain/entities/outlet.dart';
import '../../../presentation/widgets/tenant_admin_buttons.dart';
import '../../../presentation/widgets/tenant_admin_data_table.dart';
import '../../../presentation/widgets/tenant_admin_status_badge.dart';

class OutletTable extends StatelessWidget {
  const OutletTable({
    super.key,
    required this.outlets,
    required this.canUpdate,
  });

  final List<Outlet> outlets;
  final bool canUpdate;

  @override
  Widget build(BuildContext context) {
    return TenantAdminDataTable(
      emptyTitle: 'No outlets found',
      emptyMessage: 'Create an outlet or adjust your search/filter.',
      columns: const [
        DataColumn(label: Text('Outlet Name')),
        DataColumn(label: Text('Location')),
        DataColumn(label: Text('Status')),
        DataColumn(label: Text('Tills')),
        DataColumn(label: Text('Staff')),
        DataColumn(label: Text("Today's Sales")),
        DataColumn(label: Text('Actions')),
      ],
      rows: [
        for (final outlet in outlets)
          DataRow(
            cells: [
              DataCell(
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(outlet.name),
                    Text(outlet.code),
                  ],
                ),
                onTap: () => context.go('/tenant-admin/outlets/${outlet.id}'),
              ),
              DataCell(Text(outlet.location)),
              DataCell(
                TenantAdminStatusBadge(
                  label: outlet.status,
                  status: _statusType(outlet.status),
                ),
              ),
              DataCell(Text('${outlet.tillCount}')),
              DataCell(Text('${outlet.staffCount}')),
              DataCell(Text(outlet.todaysSales)),
              DataCell(
                Row(
                  children: [
                    TenantAdminIconButton(
                      icon: Icons.visibility,
                      tooltip: 'View',
                      onPressed: () =>
                          context.go('/tenant-admin/outlets/${outlet.id}'),
                    ),
                    if (canUpdate) ...[
                      const SizedBox(width: 8),
                      TenantAdminIconButton(
                        icon: Icons.edit,
                        tooltip: 'Edit',
                        onPressed: () => context.go(
                          '/tenant-admin/outlets/${outlet.id}/edit',
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
      ],
    );
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

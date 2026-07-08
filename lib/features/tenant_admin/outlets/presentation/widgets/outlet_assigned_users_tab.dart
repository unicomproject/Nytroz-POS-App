import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../presentation/theme/tenant_admin_theme.dart';
import '../../../presentation/widgets/tenant_admin_data_table.dart';
import '../../../presentation/widgets/tenant_admin_states.dart';
import '../../../presentation/widgets/tenant_admin_status_badge.dart';
import '../providers/outlet_detail_providers.dart';
import 'outlet_detail_kpi_row.dart';

class OutletAssignedUsersTab extends ConsumerWidget {
  const OutletAssignedUsersTab({super.key, required this.outletId});

  final String outletId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(outletAssignedUsersProvider(outletId));

    return state.when(
      loading: () => const TenantAdminLoadingSkeleton(rowCount: 8),
      error: (error, stackTrace) => TenantAdminErrorState(
        title: 'Unable to load users',
        message: 'Please try again.',
        onRetry: () => ref.invalidate(outletAssignedUsersProvider(outletId)),
      ),
      data: (result) {
        final summary = result.summary;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            OutletDetailKpiRow(
              cards: [
                OutletDetailKpiCardData(
                  title: 'Total Assigned Users',
                  value: summary.totalAssignedUsers.toString(),
                  icon: Icons.groups_outlined,
                ),
                OutletDetailKpiCardData(
                  title: 'Active Users',
                  value: summary.activeUsers.toString(),
                  subtitle: summary.totalAssignedUsers == 0
                      ? null
                      : '${((summary.activeUsers / summary.totalAssignedUsers) * 100).toStringAsFixed(1)}% of total',
                  icon: Icons.verified_user_outlined,
                ),
                OutletDetailKpiCardData(
                  title: 'Pending Invites',
                  value: summary.pendingInvites.toString(),
                  subtitle: summary.totalAssignedUsers == 0
                      ? null
                      : '${((summary.pendingInvites / (summary.totalAssignedUsers + summary.pendingInvites)) * 100).toStringAsFixed(1)}% of total',
                  icon: Icons.mail_outline,
                ),
                OutletDetailKpiCardData(
                  title: 'Managers',
                  value: summary.managers.toString(),
                  subtitle: summary.totalAssignedUsers == 0
                      ? null
                      : '${((summary.managers / summary.totalAssignedUsers) * 100).toStringAsFixed(1)}% of total',
                  icon: Icons.shield_outlined,
                ),
              ],
            ),
            const SizedBox(height: TenantAdminSpacing.lg),
            TenantAdminDataTable(
              columns: const [
                DataColumn(label: Text('User')),
                DataColumn(label: Text('Role')),
                DataColumn(label: Text('Assigned Till / Department')),
                DataColumn(label: Text('Contact')),
                DataColumn(label: Text('Outlet Access')),
                DataColumn(label: Text('Status')),
                DataColumn(label: Text('Last Activity')),
                DataColumn(label: Text('Actions')),
              ],
              rows: [
                for (final user in result.items)
                  DataRow(
                    cells: [
                      DataCell(Text(user.displayName)),
                      DataCell(Text(user.roleName)),
                      DataCell(Text(user.assignedTillOrDepartment ?? '—')),
                      DataCell(
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (user.phoneNumber != null)
                              Text(user.phoneNumber!),
                            if (user.email != null) Text(user.email!),
                          ],
                        ),
                      ),
                      DataCell(Text(user.outletAccess ?? '—')),
                      DataCell(
                        TenantAdminStatusBadge(
                          label: user.status,
                          status: _statusType(user.status),
                        ),
                      ),
                      DataCell(Text(user.lastActivity ?? '—')),
                      const DataCell(Icon(Icons.more_vert)),
                    ],
                  ),
              ],
              emptyTitle: 'No assigned users',
              emptyMessage: 'Assign staff to this outlet to see them here.',
            ),
          ],
        );
      },
    );
  }
}

TenantAdminStatusType _statusType(String status) {
  switch (status.toLowerCase()) {
    case 'active':
      return TenantAdminStatusType.active;
    case 'pending':
    case 'pending invite':
      return TenantAdminStatusType.pending;
    default:
      return TenantAdminStatusType.inactive;
  }
}

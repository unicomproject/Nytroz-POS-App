import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../presentation/theme/tenant_admin_theme.dart';
import '../../../presentation/widgets/tenant_admin_data_table.dart';
import '../../../presentation/widgets/tenant_admin_states.dart';
import '../../../presentation/widgets/tenant_admin_status_badge.dart';
import '../providers/outlet_detail_providers.dart';
import 'outlet_detail_kpi_row.dart';

class OutletTillsTab extends ConsumerWidget {
  const OutletTillsTab({super.key, required this.outletId});

  final String outletId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(outletTillsDetailProvider(outletId));

    return state.when(
      loading: () => const TenantAdminLoadingSkeleton(rowCount: 8),
      error: (error, stackTrace) => TenantAdminErrorState(
        title: 'Unable to load tills',
        message: 'Please try again.',
        onRetry: () => ref.invalidate(outletTillsDetailProvider(outletId)),
      ),
      data: (result) {
        final summary = result.summary;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            OutletDetailKpiRow(
              cards: [
                OutletDetailKpiCardData(
                  title: 'Total Tills',
                  value: summary.totalTills.toString(),
                  icon: Icons.point_of_sale_outlined,
                ),
                OutletDetailKpiCardData(
                  title: 'Active Tills',
                  value: summary.activeTills.toString(),
                  icon: Icons.check_circle_outline,
                ),
                OutletDetailKpiCardData(
                  title: 'Currently Open Tills',
                  value: summary.currentlyOpenTills.toString(),
                  icon: Icons.schedule_outlined,
                ),
                OutletDetailKpiCardData(
                  title: 'Tills Needing Attention',
                  value: summary.tillsNeedingAttention.toString(),
                  icon: Icons.warning_amber_outlined,
                ),
              ],
            ),
            const SizedBox(height: TenantAdminSpacing.lg),
            TenantAdminDataTable(
              columns: const [
                DataColumn(label: Text('Till Name / Code')),
                DataColumn(label: Text('Status')),
                DataColumn(label: Text('Current Balance')),
                DataColumn(label: Text('Opening Amount')),
                DataColumn(label: Text('Last Opened')),
                DataColumn(label: Text('Last Closed')),
                DataColumn(label: Text('Assigned Cashier')),
                DataColumn(label: Text('Device Status')),
                DataColumn(label: Text('Actions')),
              ],
              rows: [
                for (final till in result.items)
                  DataRow(
                    cells: [
                      DataCell(Text('${till.tillName}\n${till.tillCode}')),
                      DataCell(
                        TenantAdminStatusBadge(
                          label: till.status,
                          status: till.status.toLowerCase() == 'active'
                              ? TenantAdminStatusType.active
                              : TenantAdminStatusType.pending,
                        ),
                      ),
                      DataCell(Text(
                        till.currentBalance == null
                            ? '—'
                            : formatCurrency(till.currentBalance!),
                      )),
                      DataCell(Text(
                        till.openingAmount == null
                            ? '—'
                            : formatCurrency(till.openingAmount!),
                      )),
                      DataCell(Text(_formatDate(till.lastOpenedAt))),
                      DataCell(Text(_formatDate(till.lastClosedAt))),
                      DataCell(
                          Text(till.assignedCashierName ?? 'Not Assigned')),
                      DataCell(
                        TenantAdminStatusBadge(
                          label: till.deviceStatus,
                          status: till.deviceStatus.toLowerCase() == 'online'
                              ? TenantAdminStatusType.active
                              : TenantAdminStatusType.pending,
                        ),
                      ),
                      const DataCell(Icon(Icons.more_vert)),
                    ],
                  ),
              ],
              emptyTitle: 'No tills found',
              emptyMessage: 'Create a till for this outlet to get started.',
              footer: Text(
                'Showing ${result.items.length} of ${result.items.length} tills',
                style: TenantAdminTextStyles.muted(context),
              ),
            ),
          ],
        );
      },
    );
  }
}

String _formatDate(String? value) {
  if (value == null || value.trim().isEmpty) {
    return '—';
  }

  final parsed = DateTime.tryParse(value);
  if (parsed == null) {
    return value;
  }

  return '${parsed.year}-${parsed.month.toString().padLeft(2, '0')}-${parsed.day.toString().padLeft(2, '0')}';
}

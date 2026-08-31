import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nytroz_pos/shared/presentation/app_modal.dart';

import '../../domain/entities/outlet.dart';
import '../../../presentation/theme/tenant_admin_theme.dart';
import '../../../presentation/widgets/tenant_admin_data_table.dart';
import '../../../presentation/widgets/tenant_admin_row_action.dart';
import '../../../presentation/widgets/tenant_admin_status_badge.dart';
import '../config/outlet_row_action_configs.dart';
import '../config/outlet_table_column_configs.dart';
import '../providers/outlet_providers.dart';
import '../providers/outlet_visibility_provider.dart';
import '../providers/selected_outlet_provider.dart';
import '../utils/outlet_list_filters.dart';

class OutletTable extends ConsumerWidget {
  const OutletTable({
    super.key,
    required this.outlets,
    required this.columns,
    required this.rowActions,
    required this.sortBy,
    required this.sortDirection,
    required this.onSort,
    this.page,
    this.pageSize,
    this.totalCount,
    this.onPageChanged,
  });

  final List<Outlet> outlets;
  final List<OutletTableColumnConfig> columns;
  final List<OutletRowActionConfig> rowActions;
  final String sortBy;
  final String sortDirection;
  final void Function(String sortKey) onSort;
  final int? page;
  final int? pageSize;
  final int? totalCount;
  final ValueChanged<int>? onPageChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canEdit = rowActions.any(
      (action) => action.actionId == OutletRowActionId.edit,
    );
    final canDelete = rowActions.any(
      (action) => action.actionId == OutletRowActionId.delete,
    );

    return TenantAdminDataTable(
      showCheckboxColumn: false,
      emptyTitle: 'No outlets found',
      emptyMessage: 'Create an outlet or adjust your search/filter.',
      footer: _buildFooter(),
      columns: [
        for (final column in columns)
          DataColumn(
            label: _SortableHeader(
              label: column.label,
              sortKey: column.sortKey,
              activeSortKey: sortBy,
              sortDirection: sortDirection,
              onSort: onSort,
            ),
            numeric: false,
          ),
      ],
      rows: [
        for (final outlet in outlets)
          DataRow(
            selected: ref.watch(selectedOutletIdProvider) == outlet.id,
            onSelectChanged: (_) => _handleRowTap(context, ref, outlet.id),
            cells: [
              for (final column in columns)
                _buildCell(context, ref, column, outlet, canEdit, canDelete),
            ],
          ),
      ],
    );
  }

  Widget? _buildFooter() {
    if (page == null ||
        pageSize == null ||
        totalCount == null ||
        onPageChanged == null ||
        totalCount! <= 0) {
      return null;
    }

    final currentPage = page!;
    final totalPages =
        pageSize! <= 0 ? 1 : (totalCount! / pageSize!).ceil().clamp(1, 9999);
    final rangeStart = ((currentPage - 1) * pageSize!) + 1;
    final rangeEnd = (currentPage * pageSize!).clamp(0, totalCount!);

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: TenantAdminSpacing.lg,
        vertical: TenantAdminSpacing.md,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Showing $rangeStart to $rangeEnd of $totalCount outlets',
              style: const TextStyle(
                color: TenantAdminColors.mutedText,
                fontWeight: FontWeight.w500,
                fontSize: 12,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Previous page',
            onPressed:
                currentPage > 1 ? () => onPageChanged!(currentPage - 1) : null,
            icon: const Icon(Icons.chevron_left),
          ),
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: TenantAdminColors.primary,
              borderRadius: BorderRadius.circular(TenantAdminRadius.sm),
            ),
            child: Text(
              '$currentPage',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Next page',
            onPressed: currentPage < totalPages
                ? () => onPageChanged!(currentPage + 1)
                : null,
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }

  DataCell _buildCell(
    BuildContext context,
    WidgetRef ref,
    OutletTableColumnConfig column,
    Outlet outlet,
    bool canEdit,
    bool canDelete,
  ) {
    switch (column.columnId) {
      case OutletTableColumnId.name:
        return DataCell(
          InkWell(
            onTap: () => _handleRowTap(context, ref, outlet.id),
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: TenantAdminColors.secondary,
                    borderRadius: BorderRadius.circular(TenantAdminRadius.sm),
                  ),
                  child: const Icon(
                    Icons.storefront_outlined,
                    size: 16,
                    color: TenantAdminColors.primary,
                  ),
                ),
                const SizedBox(width: TenantAdminSpacing.sm),
                Expanded(
                  child: Text(
                    outlet.name,
                    style: const TextStyle(
                      color: TenantAdminColors.bodyText,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      case OutletTableColumnId.code:
        return DataCell(_PlainCell(outlet.code));
      case OutletTableColumnId.type:
        return DataCell(_PlainCell(_outletType(outlet)));
      case OutletTableColumnId.manager:
        return DataCell(_PlainCell(_mockManager(outlet.code)));
      case OutletTableColumnId.city:
        return DataCell(_PlainCell(_cityLabel(outlet)));
      case OutletTableColumnId.status:
        final statusLabel = displayOutletStatus(outlet.status);
        final statusType = _statusType(outlet.status);

        return DataCell(
          TenantAdminStatusBadge(
            label: statusLabel,
            status: statusType,
          ),
        );
      case OutletTableColumnId.tills:
        return DataCell(_PlainCell('${outlet.tillCount}'));
      case OutletTableColumnId.actions:
        return DataCell(
          Align(
            alignment: Alignment.centerRight,
            child: TenantAdminOverflowMenu(
              actions: [
                if (canEdit)
                  TenantAdminOverflowAction(
                    id: 'edit',
                    icon: Icons.edit_outlined,
                    label: 'Edit',
                    onSelected: () => context.go(
                      '/tenant-admin/outlets/${outlet.id}/edit',
                    ),
                  ),
                if (canDelete)
                  TenantAdminOverflowAction(
                    id: 'delete',
                    icon: Icons.delete_outline,
                    label: 'Delete',
                    destructive: true,
                    onSelected: () => _confirmDelete(context, ref, outlet),
                  ),
              ],
            ),
          ),
        );
    }
  }

  void _handleRowTap(BuildContext context, WidgetRef ref, String id) {
    final isDesktop = MediaQuery.of(context).size.width >= 1000;
    if (isDesktop) {
      ref.read(selectedOutletIdProvider.notifier).state = id;
    } else {
      context.go('/tenant-admin/outlets/$id');
    }
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    Outlet outlet,
  ) async {
    final confirmed = await showAppDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete outlet'),
          content: Text(
            'Are you sure you want to delete "${outlet.name}"? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: TenantAdminColors.danger,
              ),
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !context.mounted) {
      return;
    }

    try {
      await ref.read(deleteOutletProvider).call(outlet.id);
      ref.invalidate(outletListProvider);

      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${outlet.name} deleted')),
      );
    } catch (error) {
      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to delete outlet: $error'),
          backgroundColor: TenantAdminColors.danger,
        ),
      );
    }
  }
}

class _SortableHeader extends StatelessWidget {
  const _SortableHeader({
    required this.label,
    required this.sortKey,
    required this.activeSortKey,
    required this.sortDirection,
    required this.onSort,
  });

  final String label;
  final String? sortKey;
  final String activeSortKey;
  final String sortDirection;
  final void Function(String sortKey) onSort;

  @override
  Widget build(BuildContext context) {
    if (sortKey == null) {
      return Text(label);
    }

    final isActive = activeSortKey == sortKey;
    final icon = !isActive
        ? Icons.unfold_more
        : sortDirection == 'desc'
            ? Icons.keyboard_arrow_down
            : Icons.keyboard_arrow_up;

    return InkWell(
      onTap: () => onSort(sortKey!),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label),
          const SizedBox(width: 4),
          Icon(
            icon,
            size: 16,
            color: isActive
                ? TenantAdminColors.primary
                : TenantAdminColors.mutedText,
          ),
        ],
      ),
    );
  }
}

class _PlainCell extends StatelessWidget {
  const _PlainCell(this.value);

  final String value;

  @override
  Widget build(BuildContext context) {
    return Text(
      value,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(
        color: TenantAdminColors.bodyText,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}

String _outletType(Outlet outlet) {
  final value = outlet.outletType?.trim();
  return value == null || value.isEmpty ? 'Company Owned' : value;
}

String _cityLabel(Outlet outlet) {
  final explicitCity = outlet.city?.trim();
  if (explicitCity != null && explicitCity.isNotEmpty) {
    return explicitCity;
  }

  final parts = outlet.location
      .split(',')
      .map((part) => part.trim())
      .where((part) => part.isNotEmpty)
      .toList(growable: false);

  if (parts.length >= 2) {
    return parts[parts.length - 2];
  }

  return parts.isEmpty ? '—' : parts.last;
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

String _mockManager(String code) {
  if (code.contains('DEV')) return 'Kavindu Silva';
  if (code.contains('CITY')) return 'Nadeesha Perera';
  if (code.contains('WH')) return 'Admin Team';
  if (code.contains('FEST')) return 'Tharushi';
  if (code.contains('MALL')) return 'Isuru Fernando';
  return 'Unassigned';
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../domain/services/tenant_admin_access_checker.dart';
import '../../../presentation/theme/tenant_admin_theme.dart';
import '../../../presentation/widgets/tenant_admin_buttons.dart';
import '../../../presentation/widgets/tenant_admin_data_table.dart';
import '../../../presentation/widgets/tenant_admin_status_badge.dart';
import '../../domain/entities/till.dart';
import '../config/till_row_action_configs.dart';
import '../utils/till_api_errors.dart';
import '../utils/till_table_utils.dart';

class TillTable extends StatelessWidget {
  const TillTable({
    super.key,
    required this.tills,
    required this.visibility,
    this.page,
    this.pageSize,
    this.totalCount,
    this.onPageChanged,
  });

  final List<Till> tills;
  final TillListVisibility visibility;
  final int? page;
  final int? pageSize;
  final int? totalCount;
  final ValueChanged<int>? onPageChanged;

  @override
  Widget build(BuildContext context) {
    final inlineActions = tillInlineActions(visibility);
    final moreActions = tillMoreMenuActions(visibility);
    final showActions = inlineActions.isNotEmpty || moreActions.isNotEmpty;

    final columns = <DataColumn>[
      const DataColumn(label: Text('Till Name')),
      const DataColumn(label: Text('Till Code')),
      const DataColumn(label: Text('Outlet')),
      const DataColumn(label: Text('Status')),
      const DataColumn(label: Text('Last Active')),
      if (showActions) const DataColumn(label: Text('Actions')),
    ];

    final rows = tills.map((till) {
      final cells = <DataCell>[
        DataCell(_TillIdentity(till: till)),
        DataCell(Text(till.code)),
        DataCell(Text(till.outletName)),
        DataCell(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TenantAdminStatusBadge(
                label: tillOperationalStatusLabel(
                  till.operationalStatus,
                  attentionLabel: till.attentionLabel,
                ),
                status: tillOperationalStatusType(till.operationalStatus),
              ),
              if (till.attentionLabel != null &&
                  till.attentionLabel!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    till.attentionLabel!,
                    style: const TextStyle(
                      color: TenantAdminColors.mutedText,
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          ),
        ),
        DataCell(Text(formatTillLastSync(till.lastActiveAt))),
        if (showActions)
          DataCell(
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                for (final action in inlineActions)
                  Padding(
                    padding: const EdgeInsets.only(left: TenantAdminSpacing.sm),
                    child: _ActionButton(
                      action: action,
                      till: till,
                    ),
                  ),
                if (moreActions.isNotEmpty)
                  PopupMenuButton<TillRowActionConfig>(
                    tooltip: 'More actions',
                    itemBuilder: (context) => moreActions
                        .map(
                          (action) => PopupMenuItem(
                            value: action,
                            child: Text(action.label),
                          ),
                        )
                        .toList(growable: false),
                    onSelected: (action) =>
                        _handleAction(context, action, till),
                    child: const Padding(
                      padding: EdgeInsets.all(8),
                      child: Icon(Icons.more_vert),
                    ),
                  ),
              ],
            ),
          ),
      ];

      return DataRow(cells: cells);
    }).toList(growable: false);

    return TenantAdminDataTable(
      columns: columns,
      rows: rows,
      footer: _buildFooter(),
    );
  }

  Widget? _buildFooter() {
    if (page == null ||
        pageSize == null ||
        totalCount == null ||
        onPageChanged == null ||
        totalCount! <= pageSize!) {
      return null;
    }

    final currentPage = page!;
    final totalPages = (totalCount! / pageSize!).ceil().clamp(1, 999999);
    final rangeStart = ((currentPage - 1) * pageSize!) + 1;
    final rangeEnd = (currentPage * pageSize!).clamp(1, totalCount!);

    return Padding(
      padding: const EdgeInsets.all(TenantAdminSpacing.lg),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Showing $rangeStart to $rangeEnd of $totalCount tills',
              style: const TextStyle(color: TenantAdminColors.mutedText),
            ),
          ),
          IconButton(
            onPressed:
                currentPage > 1 ? () => onPageChanged!(currentPage - 1) : null,
            icon: const Icon(Icons.chevron_left),
          ),
          Text('$currentPage'),
          IconButton(
            onPressed: currentPage < totalPages
                ? () => onPageChanged!(currentPage + 1)
                : null,
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }

  void _handleAction(
    BuildContext context,
    TillRowActionConfig action,
    Till till,
  ) {
    switch (action.actionId) {
      case TillRowActionId.viewDetails:
        context.go('/tenant-admin/tills/${till.id}');
      case TillRowActionId.edit:
        context.go('/tenant-admin/tills/${till.id}/edit');
      case TillRowActionId.delete:
      case TillRowActionId.generateActivationCode:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${action.label} is not available yet.')),
        );
    }
  }
}

class _TillIdentity extends StatelessWidget {
  const _TillIdentity({required this.till});

  final Till till;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: TenantAdminColors.secondary,
            borderRadius: BorderRadius.circular(TenantAdminRadius.sm),
          ),
          child: const Icon(
            Icons.point_of_sale_outlined,
            size: 18,
            color: TenantAdminColors.primary,
          ),
        ),
        const SizedBox(width: TenantAdminSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                till.name,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              Text(
                till.code,
                style: const TextStyle(
                  color: TenantAdminColors.mutedText,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.action,
    required this.till,
  });

  final TillRowActionConfig action;
  final Till till;

  @override
  Widget build(BuildContext context) {
    if (action.actionId == TillRowActionId.viewDetails) {
      return TenantAdminSecondaryButton(
        label: action.label,
        onPressed: () => context.go('/tenant-admin/tills/${till.id}'),
      );
    }

    if (action.actionId == TillRowActionId.edit) {
      return TenantAdminSecondaryButton(
        label: action.label,
        onPressed: () => context.go('/tenant-admin/tills/${till.id}/edit'),
      );
    }

    return TenantAdminSecondaryButton(
      label: action.label,
      onPressed: () {},
    );
  }
}

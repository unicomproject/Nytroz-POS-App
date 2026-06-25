import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../domain/services/tenant_admin_access_checker.dart';
import '../../../presentation/theme/tenant_admin_theme.dart';
import '../../domain/entities/till.dart';
import '../config/till_row_action_configs.dart';
import 'till_mobile_list.dart';

class TillListView extends StatelessWidget {
  const TillListView({
    super.key,
    required this.result,
    required this.visibility,
    required this.isMobile,
  });

  final TillListResult result;
  final TillListVisibility visibility;
  final bool isMobile;

  @override
  Widget build(BuildContext context) {
    if (isMobile) {
      return Padding(
        padding: const EdgeInsets.all(TenantAdminSpacing.lg),
        child: TillMobileList(
          tills: result.items,
          visibility: visibility,
        ),
      );
    }

    final canView = visibility.visibleRowActions.any(
      (action) => action.actionId == TillRowActionId.viewDetails,
    );
    final canEdit = visibility.visibleRowActions.any(
      (action) => action.actionId == TillRowActionId.edit,
    );
    final canDelete = visibility.visibleMoreMenuActions.any(
      (action) => action.actionId == TillRowActionId.delete,
    );

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowHeight: 48,
        dataRowMinHeight: 54,
        dataRowMaxHeight: 58,
        columnSpacing: TenantAdminSpacing.xl,
        horizontalMargin: TenantAdminSpacing.lg,
        headingTextStyle: const TextStyle(
          color: TenantAdminColors.bodyText,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
        dataTextStyle: const TextStyle(
          color: TenantAdminColors.bodyText,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        columns: const [
          DataColumn(label: _SortableLabel('Till Name')),
          DataColumn(label: _SortableLabel('Till Code')),
          DataColumn(label: _SortableLabel('Outlet')),
          DataColumn(label: _SortableLabel('Status')),
          DataColumn(label: _SortableLabel('Last Active')),
          DataColumn(
              label: Align(
                  alignment: Alignment.centerRight, child: Text('Actions'))),
        ],
        rows: [
          for (final till in result.items)
            DataRow(
              cells: [
                DataCell(_TillNameCell(till: till, canView: canView)),
                DataCell(_PlainCell(till.code)),
                DataCell(_PlainCell(_emptyDash(till.outletName))),
                DataCell(_StatusPill(label: _statusLabel(till))),
                DataCell(_PlainCell(_lastActiveLabel(till.lastSyncAt))),
                DataCell(
                  Align(
                    alignment: Alignment.centerRight,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (canEdit)
                          _ActionIconButton(
                            icon: Icons.edit_outlined,
                            tooltip: 'Edit till',
                            onPressed: () => context.go(
                              '/tenant-admin/tills/${till.id}/edit',
                            ),
                          ),
                        if (canEdit && canDelete)
                          const SizedBox(width: TenantAdminSpacing.sm),
                        if (canDelete)
                          _ActionIconButton(
                            icon: Icons.delete_outline,
                            tooltip: 'Delete till',
                            destructive: true,
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                      'Delete till API is not available yet.'),
                                ),
                              );
                            },
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _SortableLabel extends StatelessWidget {
  const _SortableLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label),
        const SizedBox(width: 4),
        const Icon(
          Icons.unfold_more,
          size: 14,
          color: TenantAdminColors.mutedText,
        ),
      ],
    );
  }
}

class _TillNameCell extends StatelessWidget {
  const _TillNameCell({
    required this.till,
    required this.canView,
  });

  final Till till;
  final bool canView;

  @override
  Widget build(BuildContext context) {
    final content = Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: TenantAdminColors.secondary,
            borderRadius: BorderRadius.circular(TenantAdminRadius.sm),
          ),
          child: const Icon(
            Icons.point_of_sale_outlined,
            color: TenantAdminColors.primary,
            size: 16,
          ),
        ),
        const SizedBox(width: TenantAdminSpacing.sm),
        Flexible(
          child: Text(
            till.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: TenantAdminColors.bodyText,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );

    if (!canView) {
      return content;
    }

    return InkWell(
      onTap: () => context.go('/tenant-admin/tills/${till.id}'),
      child: content,
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
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final active =
        label.toLowerCase() == 'active' || label.toLowerCase() == 'online';
    final color = active ? TenantAdminColors.success : TenantAdminColors.danger;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: TenantAdminSpacing.md,
        vertical: TenantAdminSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: TenantAdminSpacing.xs),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionIconButton extends StatelessWidget {
  const _ActionIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.destructive = false,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      style: IconButton.styleFrom(
        backgroundColor: TenantAdminColors.surface,
        foregroundColor:
            destructive ? TenantAdminColors.danger : TenantAdminColors.primary,
        side: BorderSide(
          color: destructive
              ? TenantAdminColors.danger.withValues(alpha: 0.25)
              : TenantAdminColors.border,
        ),
        minimumSize: const Size(32, 32),
        padding: EdgeInsets.zero,
      ),
      icon: Icon(icon, size: 16),
    );
  }
}

String _emptyDash(String value) {
  final trimmed = value.trim();
  return trimmed.isEmpty ? '—' : trimmed;
}

String _statusLabel(Till till) {
  final status = till.status.trim();
  if (status.isNotEmpty) {
    return _titleCase(status);
  }

  return _titleCase(till.operationalStatus.replaceAll('_', ' '));
}

String _lastActiveLabel(DateTime? value) {
  if (value == null) {
    return '—';
  }

  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  final hour12 = value.hour == 0
      ? 12
      : value.hour > 12
          ? value.hour - 12
          : value.hour;
  final minute = value.minute.toString().padLeft(2, '0');
  final period = value.hour >= 12 ? 'PM' : 'AM';

  return '${months[value.month - 1]} ${value.day}, ${value.year} '
      '${hour12.toString().padLeft(2, '0')}:$minute $period';
}

String _titleCase(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) {
    return '—';
  }

  return trimmed
      .split(' ')
      .where((part) => part.isNotEmpty)
      .map((part) => part[0].toUpperCase() + part.substring(1).toLowerCase())
      .join(' ');
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../domain/services/tenant_admin_access_checker.dart';
import '../../../presentation/theme/tenant_admin_theme.dart';
import '../../../presentation/widgets/tenant_admin_status_badge.dart';
import '../../domain/entities/till.dart';
import '../config/till_row_action_configs.dart';
import 'till_action_menu.dart';
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

  static const _headerHeight = 52.0;
  static const _rowHeight = 62.0;
  static const _tableHeaderColor = Color(0xFFF8FAFC);
  static const _tableHoverColor = Color(0xFFF1F5F9);
  static const _horizontalPadding = 20.0;
  static const _minTableWidth = 960.0;

  static const _columnFlex = <int>[20, 14, 18, 11, 18, 12];

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

    final showActions = visibility.showActionsColumn;
    final canView = visibility.visibleRowActions.any(
      (action) => action.actionId == TillRowActionId.viewDetails,
    );
    final canEdit = visibility.visibleRowActions.any(
      (action) => action.actionId == TillRowActionId.edit,
    );
    final canDelete = visibility.visibleMoreMenuActions.any(
      (action) => action.actionId == TillRowActionId.delete,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final tableWidth = constraints.maxWidth < _minTableWidth
            ? _minTableWidth
            : constraints.maxWidth;

        final table = SizedBox(
          width: tableWidth,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _TillTableHeader(showActions: showActions),
              for (final till in result.items) ...[
                const Divider(height: 1, thickness: 0.5, color: TenantAdminColors.border),
                _TillTableRow(
                  till: till,
                  showActions: showActions,
                  canView: canView,
                  canEdit: canEdit,
                  canDelete: canDelete,
                  showMoreMenu: visibility.showMoreMenu,
                  moreMenuActions: visibility.visibleMoreMenuActions,
                ),
              ],
            ],
          ),
        );

        if (constraints.maxWidth < _minTableWidth) {
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: table,
          );
        }

        return table;
      },
    );
  }
}

class _TillTableHeader extends StatelessWidget {
  const _TillTableHeader({required this.showActions});

  final bool showActions;

  static const _labels = [
    'Till Name',
    'Till Code',
    'Outlet',
    'Status',
    'Last Active',
    'Actions',
  ];

  @override
  Widget build(BuildContext context) {
    final labels = showActions ? _labels : _labels.sublist(0, _labels.length - 1);
    final flexValues = showActions
        ? TillListView._columnFlex
        : TillListView._columnFlex.sublist(0, TillListView._columnFlex.length - 1);

    return _TillTableRowLayout(
      height: TillListView._headerHeight,
      flexValues: flexValues,
      backgroundColor: TillListView._tableHeaderColor,
      children: [
        for (var index = 0; index < labels.length; index++)
          _HeaderLabel(
            labels[index],
            alignRight: index == labels.length - 1 && showActions,
          ),
      ],
    );
  }
}

class _TillTableRow extends StatefulWidget {
  const _TillTableRow({
    required this.till,
    required this.showActions,
    required this.canView,
    required this.canEdit,
    required this.canDelete,
    required this.showMoreMenu,
    required this.moreMenuActions,
  });

  final Till till;
  final bool showActions;
  final bool canView;
  final bool canEdit;
  final bool canDelete;
  final bool showMoreMenu;
  final List<TillRowActionConfig> moreMenuActions;

  @override
  State<_TillTableRow> createState() => _TillTableRowState();
}

class _TillTableRowState extends State<_TillTableRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final flexValues = widget.showActions
        ? TillListView._columnFlex
        : TillListView._columnFlex.sublist(0, TillListView._columnFlex.length - 1);

    final cells = <Widget>[
      _TillNameCell(till: widget.till, canView: widget.canView),
      _PlainCell(widget.till.code),
      _PlainCell(_emptyDash(widget.till.outletName)),
      _TillStatusBadge(till: widget.till),
      _PlainCell(
        _lastActiveLabel(widget.till.lastSyncAt),
        noWrap: true,
      ),
    ];

    if (widget.showActions) {
      cells.add(
        _RowActions(
          till: widget.till,
          canView: widget.canView,
          canEdit: widget.canEdit,
          canDelete: widget.canDelete,
          showMoreMenu: widget.showMoreMenu,
          moreMenuActions: widget.moreMenuActions,
        ),
      );
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: ColoredBox(
        color: _hovered ? TillListView._tableHoverColor : Colors.transparent,
        child: _TillTableRowLayout(
          height: TillListView._rowHeight,
          flexValues: flexValues,
          children: cells,
        ),
      ),
    );
  }
}

class _TillTableRowLayout extends StatelessWidget {
  const _TillTableRowLayout({
    required this.height,
    required this.flexValues,
    required this.children,
    this.backgroundColor,
  });

  final double height;
  final List<int> flexValues;
  final List<Widget> children;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: height,
      child: DecoratedBox(
        decoration: BoxDecoration(color: backgroundColor),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: TillListView._horizontalPadding,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              for (var index = 0; index < children.length; index++)
                Expanded(
                  flex: flexValues[index],
                  child: index == children.length - 1 &&
                          flexValues.length == TillListView._columnFlex.length
                      ? Align(
                          alignment: Alignment.centerRight,
                          child: children[index],
                        )
                      : children[index],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RowActions extends StatelessWidget {
  const _RowActions({
    required this.till,
    required this.canView,
    required this.canEdit,
    required this.canDelete,
    required this.showMoreMenu,
    required this.moreMenuActions,
  });

  final Till till;
  final bool canView;
  final bool canEdit;
  final bool canDelete;
  final bool showMoreMenu;
  final List<TillRowActionConfig> moreMenuActions;

  @override
  Widget build(BuildContext context) {
    final actions = <Widget>[];

    if (canEdit) {
      actions.add(
        _ActionIconButton(
          icon: Icons.edit_outlined,
          tooltip: 'Edit',
          onPressed: () => context.go('/tenant-admin/tills/${till.id}/edit'),
        ),
      );
    } else if (canView) {
      actions.add(
        _ActionIconButton(
          icon: Icons.visibility_outlined,
          tooltip: 'View details',
          onPressed: () => context.go('/tenant-admin/tills/${till.id}'),
        ),
      );
    }

    if (canDelete) {
      if (actions.isNotEmpty) {
        actions.add(const SizedBox(width: TenantAdminSpacing.xs));
      }
      actions.add(
        _ActionIconButton(
          icon: Icons.delete_outline,
          tooltip: 'Delete',
          destructive: true,
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Delete till API is not available yet.'),
              ),
            );
          },
        ),
      );
    }

    if (showMoreMenu) {
      if (actions.isNotEmpty) {
        actions.add(const SizedBox(width: TenantAdminSpacing.xs));
      }
      actions.add(
        TillActionMenu(
          till: till,
          actions: moreMenuActions,
        ),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.end,
      children: actions,
    );
  }
}

class _HeaderLabel extends StatelessWidget {
  const _HeaderLabel(this.label, {this.alignRight = false});

  final String label;
  final bool alignRight;

  @override
  Widget build(BuildContext context) {
    final content = Text(
      label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(
        color: TenantAdminColors.mutedText,
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.2,
      ),
    );

    if (alignRight) {
      return Align(alignment: Alignment.centerRight, child: content);
    }

    return content;
  }
}

class _TillStatusBadge extends StatelessWidget {
  const _TillStatusBadge({required this.till});

  final Till till;

  @override
  Widget build(BuildContext context) {
    final label = _statusLabel(till);
    final normalized = till.operationalStatus.toLowerCase();

    TenantAdminStatusType status;
    if (normalized == 'online') {
      status = TenantAdminStatusType.online;
    } else if (normalized == 'offline') {
      status = TenantAdminStatusType.offline;
    } else if (label.toLowerCase() == 'active') {
      status = TenantAdminStatusType.active;
    } else if (label.toLowerCase() == 'inactive') {
      status = TenantAdminStatusType.inactive;
    } else {
      status = TenantAdminStatusType.warning;
    }

    return Align(
      alignment: Alignment.centerLeft,
      child: TenantAdminStatusBadge(label: label, status: status),
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
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: TenantAdminColors.secondary,
            borderRadius: BorderRadius.circular(TenantAdminRadius.sm),
          ),
          child: const Icon(
            Icons.point_of_sale_outlined,
            color: TenantAdminColors.primary,
            size: 18,
          ),
        ),
        const SizedBox(width: TenantAdminSpacing.md),
        Expanded(
          child: Text(
            till.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: TenantAdminColors.bodyText,
              fontWeight: FontWeight.w600,
              fontSize: 13,
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
  const _PlainCell(this.value, {this.noWrap = false});

  final String value;
  final bool noWrap;

  @override
  Widget build(BuildContext context) {
    return Text(
      value,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      softWrap: !noWrap,
      style: const TextStyle(
        color: TenantAdminColors.bodyText,
        fontSize: 13,
        fontWeight: FontWeight.w500,
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
      visualDensity: VisualDensity.compact,
      style: IconButton.styleFrom(
        minimumSize: const Size(32, 32),
        padding: EdgeInsets.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      icon: Icon(
        icon,
        size: 18,
        color: destructive ? TenantAdminColors.danger : TenantAdminColors.mutedText,
      ),
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

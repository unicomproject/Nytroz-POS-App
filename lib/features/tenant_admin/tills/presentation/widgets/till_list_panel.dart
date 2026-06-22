import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../domain/services/tenant_admin_access_checker.dart';
import '../../../presentation/theme/tenant_admin_theme.dart';
import '../../../presentation/widgets/tenant_admin_buttons.dart';
import '../../../presentation/widgets/tenant_admin_search_field.dart';
import '../../../presentation/widgets/tenant_admin_status_badge.dart';
import '../../domain/entities/till.dart';
import '../config/till_row_action_configs.dart';
import '../utils/till_list_filters.dart';
import 'till_mobile_list.dart';
import 'till_table.dart';

class TillListPanel extends StatelessWidget {
  const TillListPanel({
    super.key,
    required this.result,
    required this.visibility,
    required this.statusFilter,
    required this.isMobile,
    required this.onSearchChanged,
    required this.onStatusFilterChanged,
    required this.onPageChanged,
    required this.page,
    required this.needsAttentionCount,
  });

  final TillListResult result;
  final TillListVisibility visibility;
  final TillStatusFilter statusFilter;
  final bool isMobile;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<TillStatusFilter> onStatusFilterChanged;
  final ValueChanged<int> onPageChanged;
  final int page;
  final int needsAttentionCount;

  @override
  Widget build(BuildContext context) {
    final tillCountLabel =
        '${result.totalCount > 0 ? result.totalCount : result.items.length} '
        '${result.totalCount == 1 ? 'Till' : 'Tills'}';

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: TenantAdminColors.surface,
        borderRadius: BorderRadius.circular(TenantAdminRadius.lg),
        border: Border.all(color: TenantAdminColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(TenantAdminSpacing.xl),
            child: isMobile
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _PanelTitle(countLabel: tillCountLabel),
                      const SizedBox(height: TenantAdminSpacing.lg),
                      _Toolbar(
                        visibility: visibility,
                        statusFilter: statusFilter,
                        needsAttentionCount: needsAttentionCount,
                        isMobile: true,
                        onSearchChanged: onSearchChanged,
                        onStatusFilterChanged: onStatusFilterChanged,
                      ),
                    ],
                  )
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      _PanelTitle(countLabel: tillCountLabel),
                      const Spacer(),
                      Expanded(
                        flex: 3,
                        child: _Toolbar(
                          visibility: visibility,
                          statusFilter: statusFilter,
                          needsAttentionCount: needsAttentionCount,
                          isMobile: false,
                          onSearchChanged: onSearchChanged,
                          onStatusFilterChanged: onStatusFilterChanged,
                        ),
                      ),
                    ],
                  ),
          ),
          const Divider(height: 1, color: TenantAdminColors.border),
          if (result.items.isEmpty)
            Padding(
              padding: const EdgeInsets.all(TenantAdminSpacing.xl),
              child: Center(
                child: Text(
                  statusFilter == TillStatusFilter.all
                      ? 'No tills found.'
                      : 'No tills match the selected filter.',
                  style: const TextStyle(color: TenantAdminColors.mutedText),
                ),
              ),
            )
          else if (isMobile)
            Padding(
              padding: const EdgeInsets.all(TenantAdminSpacing.lg),
              child: TillMobileList(
                tills: result.items,
                visibility: visibility,
              ),
            )
          else
            TillTable(
              tills: result.items,
              visibility: visibility,
              page: visibility.showPagination ? page : null,
              pageSize: visibility.showPagination ? result.pageSize : null,
              totalCount: visibility.showPagination ? result.totalCount : null,
              onPageChanged:
                  visibility.showPagination ? onPageChanged : null,
            ),
        ],
      ),
    );
  }
}

class _PanelTitle extends StatelessWidget {
  const _PanelTitle({required this.countLabel});

  final String countLabel;

  @override
  Widget build(BuildContext context) {
    return Text(
      'Till List ($countLabel)',
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: TenantAdminColors.bodyText,
      ),
    );
  }
}

class _Toolbar extends StatelessWidget {
  const _Toolbar({
    required this.visibility,
    required this.statusFilter,
    required this.needsAttentionCount,
    required this.isMobile,
    required this.onSearchChanged,
    required this.onStatusFilterChanged,
  });

  final TillListVisibility visibility;
  final TillStatusFilter statusFilter;
  final int needsAttentionCount;
  final bool isMobile;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<TillStatusFilter> onStatusFilterChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (visibility.showSearch || visibility.showAddTill)
          Row(
            children: [
              if (visibility.showSearch)
                Expanded(
                  child: TenantAdminSearchField(
                    hint: 'Search tills by name, code or outlet',
                    onChanged: onSearchChanged,
                  ),
                ),
              if (visibility.showSearch && visibility.showAddTill)
                const SizedBox(width: TenantAdminSpacing.md),
              if (visibility.showAddTill)
                TenantAdminPrimaryButton(
                  label: isMobile ? 'Add' : 'Add till',
                  icon: Icons.add,
                  onPressed: () => context.go('/tenant-admin/tills/add'),
                ),
            ],
          ),
        if (visibility.showFilter) ...[
          const SizedBox(height: TenantAdminSpacing.md),
          Wrap(
            spacing: TenantAdminSpacing.sm,
            runSpacing: TenantAdminSpacing.sm,
            children: TillStatusFilter.values.map((filter) {
              final selected = statusFilter == filter;
              final badgeCount = filter == TillStatusFilter.needsAttention
                  ? needsAttentionCount
                  : null;

              return FilterChip(
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(filter.label),
                    if (badgeCount != null && badgeCount > 0) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: TenantAdminColors.warning,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          '$badgeCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                selected: selected,
                onSelected: (_) => onStatusFilterChanged(filter),
              );
            }).toList(growable: false),
          ),
        ],
      ],
    );
  }
}

TenantAdminStatusType tillOperationalStatusType(String status) {
  switch (status.toLowerCase()) {
    case 'online':
      return TenantAdminStatusType.active;
    case 'offline':
      return TenantAdminStatusType.inactive;
    case 'needs_attention':
      return TenantAdminStatusType.warning;
    case 'inactive':
      return TenantAdminStatusType.inactive;
    default:
      return TenantAdminStatusType.inactive;
  }
}

String tillOperationalStatusLabel(String status, {String? attentionLabel}) {
  switch (status.toLowerCase()) {
    case 'online':
      return 'Online';
    case 'offline':
      return 'Offline';
    case 'needs_attention':
      return 'Needs attention';
    case 'inactive':
      return 'Inactive';
    default:
      return attentionLabel ?? status;
  }
}

List<TillRowActionConfig> tillInlineActions(TillListVisibility visibility) {
  return visibility.visibleRowActions
      .where((action) => !action.showInMoreMenu)
      .toList(growable: false);
}

List<TillRowActionConfig> tillMoreMenuActions(TillListVisibility visibility) {
  return visibility.visibleRowActions
      .where((action) => action.showInMoreMenu)
      .toList(growable: false);
}

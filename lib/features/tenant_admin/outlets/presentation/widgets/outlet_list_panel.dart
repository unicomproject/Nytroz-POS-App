import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nytroz_pos/shared/presentation/app_modal.dart';

import '../../../domain/services/tenant_admin_access_checker.dart';
import '../../../presentation/theme/tenant_admin_theme.dart';
import '../../../presentation/widgets/tenant_admin_buttons.dart';
import '../../../presentation/widgets/tenant_admin_search_field.dart';
import '../../../presentation/widgets/tenant_admin_states.dart';
import '../../domain/entities/outlet.dart';
import '../providers/outlet_providers.dart';
import '../utils/outlet_list_filters.dart';
import 'outlet_mobile_list.dart';
import 'outlet_table.dart';

class OutletListPanel extends ConsumerWidget {
  const OutletListPanel({
    super.key,
    required this.result,
    required this.visibility,
    required this.statusFilter,
    required this.isMobile,
    this.showPanelTitle = true,
    this.showAddButton = true,
  });

  final OutletListResult result;
  final OutletListVisibility visibility;
  final OutletStatusFilter statusFilter;
  final bool isMobile;
  final bool showPanelTitle;
  final bool showAddButton;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sortBy = ref.watch(outletSortByProvider);
    final sortDirection = ref.watch(outletSortDirectionProvider);
    final page = ref.watch(outletPageProvider);
    final outletCountLabel =
        '${result.totalCount > 0 ? result.totalCount : result.items.length} '
        '${result.totalCount == 1 ? 'Outlet' : 'Outlets'}';

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: TenantAdminColors.surface,
        borderRadius: BorderRadius.circular(TenantAdminRadius.md),
        border: Border.all(color: TenantAdminColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(TenantAdminSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (showPanelTitle) ...[
                  _PanelTitle(countLabel: outletCountLabel),
                  const SizedBox(height: TenantAdminSpacing.lg),
                ],
                _Toolbar(
                  visibility: visibility,
                  statusFilter: statusFilter,
                  summary: result.summary,
                  isMobile: isMobile,
                  showAddButton: showAddButton,
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: TenantAdminColors.border),
          if (result.items.isEmpty)
            Padding(
              padding: const EdgeInsets.all(TenantAdminSpacing.xl),
              child: TenantAdminEmptyState(
                title: statusFilter == OutletStatusFilter.all
                    ? 'No outlets found'
                    : 'No matching outlets',
                message: statusFilter == OutletStatusFilter.all
                    ? 'Create your first outlet to get started.'
                    : 'Try changing the filter or search term.',
                icon: statusFilter == OutletStatusFilter.all
                    ? Icons.store_outlined
                    : Icons.filter_alt_off_outlined,
                action: statusFilter == OutletStatusFilter.all &&
                        visibility.showAddOutlet
                    ? TenantAdminPrimaryButton(
                        label: 'Add outlet',
                        icon: Icons.add,
                        onPressed: () =>
                            context.go('/tenant-admin/outlets/add'),
                      )
                    : statusFilter != OutletStatusFilter.all
                        ? TenantAdminSecondaryButton(
                            label: 'Clear filters',
                            icon: Icons.clear,
                            onPressed: () => _resetFilters(ref),
                          )
                        : null,
              ),
            )
          else if (isMobile)
            Padding(
              padding: const EdgeInsets.all(TenantAdminSpacing.lg),
              child: OutletMobileList(
                outlets: result.items,
                visibility: visibility,
              ),
            )
          else
            OutletTable(
              outlets: result.items,
              columns: visibility.visibleColumns,
              rowActions: visibility.visibleRowActions,
              sortBy: sortBy,
              sortDirection: sortDirection,
              onSort: (sortKey) => _toggleSort(ref, sortKey),
              page: visibility.showPagination ? page : null,
              pageSize: visibility.showPagination ? result.pageSize : null,
              totalCount: visibility.showPagination ? result.totalCount : null,
              onPageChanged: visibility.showPagination
                  ? (nextPage) =>
                      ref.read(outletPageProvider.notifier).state = nextPage
                  : null,
            ),
          if (isMobile && result.items.isNotEmpty && visibility.showPagination)
            _MobilePagination(
              page: page,
              pageSize: result.pageSize,
              totalCount: result.totalCount,
              onPageChanged: (nextPage) =>
                  ref.read(outletPageProvider.notifier).state = nextPage,
            ),
        ],
      ),
    );
  }

  void _toggleSort(WidgetRef ref, String sortKey) {
    final currentSortBy = ref.read(outletSortByProvider);
    final currentDirection = ref.read(outletSortDirectionProvider);

    if (currentSortBy == sortKey) {
      ref.read(outletSortDirectionProvider.notifier).state =
          currentDirection == 'asc' ? 'desc' : 'asc';
    } else {
      ref.read(outletSortByProvider.notifier).state = sortKey;
      ref.read(outletSortDirectionProvider.notifier).state = 'asc';
    }

    ref.read(outletPageProvider.notifier).state = 1;
  }

  void _resetFilters(WidgetRef ref) {
    ref.read(outletStatusFilterProvider.notifier).state =
        OutletStatusFilter.all;
    ref.read(outletSearchProvider.notifier).state = '';
    ref.read(outletPageProvider.notifier).state = 1;
  }
}

class _PanelTitle extends StatelessWidget {
  const _PanelTitle({required this.countLabel});

  final String countLabel;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Outlet List',
          style: TenantAdminTextStyles.sectionTitle(context),
        ),
        const SizedBox(width: TenantAdminSpacing.sm),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: TenantAdminSpacing.md,
            vertical: TenantAdminSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: TenantAdminColors.secondary,
            borderRadius: BorderRadius.circular(TenantAdminRadius.xl),
          ),
          child: Text(
            countLabel,
            style: const TextStyle(
              color: TenantAdminColors.mutedText,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }
}

class _Toolbar extends ConsumerWidget {
  const _Toolbar({
    required this.visibility,
    required this.statusFilter,
    required this.summary,
    required this.isMobile,
    required this.showAddButton,
  });

  final OutletListVisibility visibility;
  final OutletStatusFilter statusFilter;
  final OutletListSummary summary;
  final bool isMobile;
  final bool showAddButton;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final children = <Widget>[
      if (visibility.showSearch)
        Expanded(
          child: TenantAdminSearchField(
            hint: 'Search outlets...',
            value: ref.watch(outletSearchProvider),
            onChanged: (value) {
              ref.read(outletSearchProvider.notifier).state = value;
              ref.read(outletPageProvider.notifier).state = 1;
            },
          ),
        ),
      if (visibility.showFilter) ...[
        if (visibility.showSearch) const SizedBox(width: TenantAdminSpacing.sm),
        SizedBox(
          width: isMobile ? double.infinity : 142,
          child: const _OutletTypeFilter(),
        ),
        const SizedBox(width: TenantAdminSpacing.sm),
        SizedBox(
          width: isMobile ? double.infinity : 142,
          child: _OutletStatusDropdown(
            value: statusFilter,
            onChanged: (value) {
              ref.read(outletStatusFilterProvider.notifier).state =
                  value ?? OutletStatusFilter.all;
              ref.read(outletPageProvider.notifier).state = 1;
            },
          ),
        ),
        const SizedBox(width: TenantAdminSpacing.sm),
        TenantAdminSecondaryButton(
          label: 'Filters',
          icon: Icons.filter_alt_outlined,
          onPressed: () =>
              _showFilterSheet(context, ref, statusFilter, summary),
        ),
      ],
      const SizedBox(width: TenantAdminSpacing.sm),
      TenantAdminSecondaryButton(
        label: 'Clear',
        icon: Icons.refresh,
        onPressed: () {
          ref.read(outletSearchProvider.notifier).state = '';
          ref.read(outletStatusFilterProvider.notifier).state =
              OutletStatusFilter.all;
          ref.read(outletPageProvider.notifier).state = 1;
        },
      ),
      if (visibility.showAddOutlet && showAddButton) ...[
        const SizedBox(width: TenantAdminSpacing.sm),
        TenantAdminPrimaryButton(
          label: isMobile ? 'Add' : 'Add outlet',
          icon: Icons.add,
          onPressed: () => context.go('/tenant-admin/outlets/add'),
        ),
      ],
    ];

    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (visibility.showSearch) children.first,
          const SizedBox(height: TenantAdminSpacing.sm),
          Wrap(
            spacing: TenantAdminSpacing.sm,
            runSpacing: TenantAdminSpacing.sm,
            children: children.skip(visibility.showSearch ? 1 : 0).toList(),
          ),
        ],
      );
    }

    return Row(children: children);
  }
}

class _OutletTypeFilter extends StatelessWidget {
  const _OutletTypeFilter();

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: 'all',
      isExpanded: true,
      decoration: _dropdownDecoration(),
      items: const [
        DropdownMenuItem(value: 'all', child: Text('All Types')),
      ],
      onChanged: (_) {},
    );
  }
}

class _OutletStatusDropdown extends StatelessWidget {
  const _OutletStatusDropdown({
    required this.value,
    required this.onChanged,
  });

  final OutletStatusFilter value;
  final ValueChanged<OutletStatusFilter?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<OutletStatusFilter>(
      initialValue: value,
      isExpanded: true,
      decoration: _dropdownDecoration(),
      items: OutletStatusFilter.values
          .map(
            (filter) => DropdownMenuItem(
              value: filter,
              child: Text(filter == OutletStatusFilter.all
                  ? 'All Status'
                  : filter.label),
            ),
          )
          .toList(),
      onChanged: onChanged,
    );
  }
}

InputDecoration _dropdownDecoration() {
  return InputDecoration(
    filled: true,
    fillColor: TenantAdminColors.surface,
    contentPadding: const EdgeInsets.symmetric(
      horizontal: TenantAdminSpacing.md,
      vertical: TenantAdminSpacing.sm,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(TenantAdminRadius.md),
      borderSide: const BorderSide(color: TenantAdminColors.border),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(TenantAdminRadius.md),
      borderSide: const BorderSide(color: TenantAdminColors.primary),
    ),
  );
}

class _MobilePagination extends StatelessWidget {
  const _MobilePagination({
    required this.page,
    required this.pageSize,
    required this.totalCount,
    required this.onPageChanged,
  });

  final int page;
  final int pageSize;
  final int totalCount;
  final ValueChanged<int> onPageChanged;

  @override
  Widget build(BuildContext context) {
    final totalPages =
        pageSize <= 0 ? 1 : (totalCount / pageSize).ceil().clamp(1, 9999);
    final rangeStart = totalCount == 0 ? 0 : ((page - 1) * pageSize) + 1;
    final rangeEnd = (page * pageSize).clamp(0, totalCount);

    return Padding(
      padding: const EdgeInsets.all(TenantAdminSpacing.lg),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Showing $rangeStart to $rangeEnd of $totalCount outlets',
              style: const TextStyle(
                color: TenantAdminColors.mutedText,
                fontSize: 12,
              ),
            ),
          ),
          IconButton(
            onPressed: page > 1 ? () => onPageChanged(page - 1) : null,
            icon: const Icon(Icons.chevron_left),
          ),
          Text('$page'),
          IconButton(
            onPressed: page < totalPages ? () => onPageChanged(page + 1) : null,
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }
}

Future<void> _showFilterSheet(
  BuildContext context,
  WidgetRef ref,
  OutletStatusFilter currentFilter,
  OutletListSummary summary,
) {
  return showAppModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (context) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            TenantAdminSpacing.xl,
            TenantAdminSpacing.md,
            TenantAdminSpacing.xl,
            TenantAdminSpacing.xl,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Filter outlets',
                style: TenantAdminTextStyles.sectionTitle(context),
              ),
              const SizedBox(height: TenantAdminSpacing.lg),
              for (final filter in OutletStatusFilter.values)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    filter == OutletStatusFilter.all
                        ? Icons.list_alt
                        : filter == OutletStatusFilter.active
                            ? Icons.check_circle_outline
                            : Icons.pause_circle_outline,
                    color: TenantAdminColors.primary,
                  ),
                  title: Text(filter.label),
                  subtitle: Text(_filterCountLabel(filter, summary)),
                  trailing: currentFilter == filter
                      ? const Icon(Icons.check,
                          color: TenantAdminColors.primary)
                      : null,
                  onTap: () {
                    ref.read(outletStatusFilterProvider.notifier).state =
                        filter;
                    ref.read(outletPageProvider.notifier).state = 1;
                    Navigator.of(context).pop();
                  },
                ),
              const SizedBox(height: TenantAdminSpacing.md),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    ref.read(outletStatusFilterProvider.notifier).state =
                        OutletStatusFilter.all;
                    ref.read(outletSearchProvider.notifier).state = '';
                    ref.read(outletPageProvider.notifier).state = 1;
                    Navigator.of(context).pop();
                  },
                  child: const Text('Reset filters'),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

String _filterCountLabel(OutletStatusFilter filter, OutletListSummary summary) {
  switch (filter) {
    case OutletStatusFilter.all:
      return '${summary.totalOutlets} outlets';
    case OutletStatusFilter.active:
      return '${summary.activeOutlets} active outlets';
    case OutletStatusFilter.inactive:
      return '${summary.inactiveOutlets} inactive outlets';
  }
}

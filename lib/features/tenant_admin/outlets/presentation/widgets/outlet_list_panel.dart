import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
  });

  final OutletListResult result;
  final OutletListVisibility visibility;
  final OutletStatusFilter statusFilter;
  final bool isMobile;

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
                      _PanelTitle(countLabel: outletCountLabel),
                      const SizedBox(height: TenantAdminSpacing.lg),
                      _Toolbar(
                        visibility: visibility,
                        statusFilter: statusFilter,
                        summary: result.summary,
                        isMobile: true,
                      ),
                    ],
                  )
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      _PanelTitle(countLabel: outletCountLabel),
                      const Spacer(),
                      Expanded(
                        flex: 3,
                        child: _Toolbar(
                          visibility: visibility,
                          statusFilter: statusFilter,
                          summary: result.summary,
                          isMobile: false,
                        ),
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
  });

  final OutletListVisibility visibility;
  final OutletStatusFilter statusFilter;
  final OutletListSummary summary;
  final bool isMobile;

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
        TenantAdminSecondaryButton(
          label: isMobile ? 'Filter' : 'Filter',
          icon: Icons.filter_list,
          onPressed: () =>
              _showFilterSheet(context, ref, statusFilter, summary),
        ),
      ],
      const SizedBox(width: TenantAdminSpacing.sm),
      TenantAdminSecondaryButton(
        label: 'Sort',
        icon: Icons.swap_vert,
        onPressed: () => _showSortSheet(context, ref),
      ),
      if (visibility.showAddOutlet) ...[
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
  return showModalBottomSheet<void>(
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

Future<void> _showSortSheet(BuildContext context, WidgetRef ref) {
  const options = [
    ('name', 'Outlet Name'),
    ('code', 'Outlet Code'),
    ('status', 'Status'),
  ];

  final currentSortBy = ref.read(outletSortByProvider);
  final currentDirection = ref.read(outletSortDirectionProvider);

  return showModalBottomSheet<void>(
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
                'Sort outlets',
                style: TenantAdminTextStyles.sectionTitle(context),
              ),
              const SizedBox(height: TenantAdminSpacing.lg),
              for (final option in options)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(option.$2),
                  trailing: currentSortBy == option.$1
                      ? Icon(
                          currentDirection == 'desc'
                              ? Icons.arrow_downward
                              : Icons.arrow_upward,
                          color: TenantAdminColors.primary,
                        )
                      : null,
                  onTap: () {
                    if (currentSortBy == option.$1) {
                      ref.read(outletSortDirectionProvider.notifier).state =
                          currentDirection == 'asc' ? 'desc' : 'asc';
                    } else {
                      ref.read(outletSortByProvider.notifier).state = option.$1;
                      ref.read(outletSortDirectionProvider.notifier).state =
                          'asc';
                    }
                    ref.read(outletPageProvider.notifier).state = 1;
                    Navigator.of(context).pop();
                  },
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

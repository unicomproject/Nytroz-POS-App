import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nytroz_pos/shared/presentation/app_modal.dart';

import '../../../domain/services/tenant_admin_access_checker.dart';
import '../../../presentation/theme/tenant_admin_theme.dart';
import '../../../presentation/widgets/tenant_admin_buttons.dart';
import '../../../presentation/widgets/tenant_admin_pagination.dart';
import '../../../presentation/widgets/tenant_admin_search_field.dart';
import '../../../presentation/widgets/tenant_admin_states.dart';
import '../../domain/entities/outlet.dart';
import '../providers/outlet_providers.dart';
import '../providers/outlet_visibility_provider.dart';
import '../utils/outlet_list_filters.dart';
import 'outlet_mobile_list.dart';
import 'outlet_card_list.dart';

class OutletListPanel extends ConsumerWidget {
  const OutletListPanel({
    super.key,
    required this.result,
    required this.visibility,
    required this.statusFilter,
    required this.isMobile,
    this.showPanelTitle = true,
    this.showAddButton = true,
    this.boundedHeight = false,
  });

  final OutletListResult result;
  final OutletListVisibility visibility;
  final OutletStatusFilter statusFilter;
  final bool isMobile;
  final bool showPanelTitle;
  final bool showAddButton;
  final bool boundedHeight;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final page = ref.watch(outletPageProvider);

    final header = Padding(
      padding: const EdgeInsets.all(TenantAdminSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showPanelTitle) ...[
            LayoutBuilder(
              builder: (context, constraints) {
                final stackHeader = constraints.maxWidth < 560;

                final titleBlock = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      visibility.showTitle ? 'Outlets' : 'Outlet List',
                      style: TenantAdminTextStyles.pageTitle(context),
                    ),
                    if (visibility.showSubtitle) ...[
                      const SizedBox(height: TenantAdminSpacing.xs),
                      Text(
                        'Manage all business outlets and sales locations.',
                        style: TenantAdminTextStyles.muted(context),
                      ),
                    ],
                  ],
                );

                final addButton = visibility.showAddOutlet
                    ? TenantAdminPrimaryButton(
                        label: isMobile ? 'Add' : 'Add Outlet',
                        icon: Icons.add,
                        onPressed: () => context.go('/tenant-admin/outlets/add'),
                      )
                    : null;

                if (stackHeader) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      titleBlock,
                      if (addButton != null) ...[
                        const SizedBox(height: TenantAdminSpacing.md),
                        SizedBox(width: double.infinity, child: addButton),
                      ],
                    ],
                  );
                }

                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: titleBlock),
                    if (addButton != null) ...[
                      const SizedBox(width: TenantAdminSpacing.lg),
                      addButton,
                    ],
                  ],
                );
              },
            ),
            const SizedBox(height: TenantAdminSpacing.lg),
          ],
          _Toolbar(
            visibility: visibility,
            statusFilter: statusFilter,
            typeFilter: ref.watch(outletTypeFilterProvider),
            summary: result.summary,
            isMobile: isMobile,
          ),
        ],
      ),
    );

    final listSection = _ListSection(
      result: result,
      visibility: visibility,
      statusFilter: statusFilter,
      isMobile: isMobile,
      scrollable: boundedHeight && !isMobile,
      page: page,
      onResetFilters: () => _resetFilters(ref),
      onPageChanged: (nextPage) =>
          ref.read(outletPageProvider.notifier).state = nextPage,
    );

    return Container(
      width: double.infinity,
      color: TenantAdminColors.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          header,
          const Divider(height: 1, color: TenantAdminColors.border),
          if (boundedHeight) Expanded(child: listSection) else listSection,
        ],
      ),
    );
  }

  void _resetFilters(WidgetRef ref) {
    ref.read(outletTypeFilterProvider.notifier).state = OutletTypeFilter.all;
    ref.read(outletStatusFilterProvider.notifier).state =
        OutletStatusFilter.all;
    ref.read(outletSearchProvider.notifier).state = '';
    ref.read(outletPageProvider.notifier).state = 1;
  }
}

class _ListSection extends ConsumerWidget {
  const _ListSection({
    required this.result,
    required this.visibility,
    required this.statusFilter,
    required this.isMobile,
    required this.scrollable,
    required this.page,
    required this.onResetFilters,
    required this.onPageChanged,
  });

  final OutletListResult result;
  final OutletListVisibility visibility;
  final OutletStatusFilter statusFilter;
  final bool isMobile;
  final bool scrollable;
  final int page;
  final VoidCallback onResetFilters;
  final ValueChanged<int> onPageChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (result.items.isEmpty) {
      final emptyState = Padding(
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
          action:
              statusFilter == OutletStatusFilter.all && visibility.showAddOutlet
                  ? TenantAdminPrimaryButton(
                      label: 'Add outlet',
                      icon: Icons.add,
                      onPressed: () => context.go('/tenant-admin/outlets/add'),
                    )
                  : statusFilter != OutletStatusFilter.all
                      ? TenantAdminSecondaryButton(
                          label: 'Clear filters',
                          icon: Icons.clear,
                          onPressed: onResetFilters,
                        )
                      : null,
        ),
      );

      return scrollable ? SingleChildScrollView(child: emptyState) : emptyState;
    }

    if (isMobile) {
      return Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(TenantAdminSpacing.lg),
            child: OutletMobileList(
              outlets: result.items,
              visibility: visibility,
            ),
          ),
          if (visibility.showPagination)
            TenantAdminPaginationBar(
              currentPage: page,
              pageSize: result.pageSize,
              totalCount: result.totalCount,
              itemLabel: 'outlets',
              onPageChanged: onPageChanged,
            ),
        ],
      );
    }

    final cardList = OutletCardList(
      outlets: result.items,
      scrollable: scrollable,
      onEdit: (outlet) => context.go('/tenant-admin/outlets/${outlet.id}/edit'),
      onDisable: (outlet) {
        _confirmDisable(context, ref, outlet);
      },
    );

    if (!visibility.showPagination) {
      return cardList;
    }

    return Column(
      children: [
        if (scrollable) Expanded(child: cardList) else cardList,
        TenantAdminPaginationBar(
          currentPage: page,
          pageSize: result.pageSize,
          totalCount: result.totalCount,
          itemLabel: 'outlets',
          onPageChanged: onPageChanged,
        ),
      ],
    );
  }

  Future<void> _confirmDisable(
    BuildContext context,
    WidgetRef ref,
    Outlet outlet,
  ) async {
    final confirmed = await showAppDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('${outlet.status.toUpperCase() == 'ACTIVE' ? 'Disable' : 'Activate'} outlet'),
          content: Text(
            'Are you sure you want to ${outlet.status.toUpperCase() == 'ACTIVE' ? 'disable' : 'activate'} "${outlet.name}"?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: outlet.status.toUpperCase() == 'ACTIVE' ? TenantAdminColors.danger : TenantAdminColors.success,
              ),
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(outlet.status.toUpperCase() == 'ACTIVE' ? 'Disable' : 'Activate'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !context.mounted) {
      return;
    }

    try {
      // Assuming deleteOutletProvider acts as toggle/disable for this MVP
      await ref.read(deleteOutletProvider).call(outlet.id);
      ref.invalidate(outletListProvider);
      
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${outlet.name} updated successfully')),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update outlet: $e'),
          backgroundColor: TenantAdminColors.danger,
        ),
      );
    }
  }
}

class _Toolbar extends ConsumerWidget {
  const _Toolbar({
    required this.visibility,
    required this.statusFilter,
    required this.typeFilter,
    required this.summary,
    required this.isMobile,
  });

  final OutletListVisibility visibility;
  final OutletStatusFilter statusFilter;
  final OutletTypeFilter typeFilter;
  final OutletListSummary summary;
  final bool isMobile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (visibility.showSearch)
          LayoutBuilder(
            builder: (context, constraints) {
              final stackSearch = constraints.maxWidth < 520;
              final searchField = TenantAdminSearchField(
                hint: 'Search outlets by name, code, manager, or location...',
                value: ref.watch(outletSearchProvider),
                onChanged: (value) {
                  ref.read(outletSearchProvider.notifier).state = value;
                  ref.read(outletPageProvider.notifier).state = 1;
                },
              );
              final filterButton = Container(
                height: 44,
                decoration: BoxDecoration(
                  color: TenantAdminColors.surface,
                  border: Border.all(color: TenantAdminColors.border),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  tooltip: 'Filter outlets',
                  icon: const Icon(Icons.filter_list_rounded),
                  color: TenantAdminColors.bodyText,
                  onPressed: () =>
                      _showFilterSheet(context, ref, statusFilter, summary),
                ),
              );

              if (stackSearch) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    searchField,
                    const SizedBox(height: TenantAdminSpacing.sm),
                    filterButton,
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(child: searchField),
                  const SizedBox(width: TenantAdminSpacing.md),
                  filterButton,
                ],
              );
            },
          ),
        if (visibility.showFilter) ...[
          const SizedBox(height: TenantAdminSpacing.md),
          Wrap(
            spacing: TenantAdminSpacing.sm,
            runSpacing: TenantAdminSpacing.sm,
            children: [
              _FilterPill(
                label: 'All',
                isSelected: typeFilter == OutletTypeFilter.all &&
                    statusFilter == OutletStatusFilter.all,
                onTap: () {
                  ref.read(outletTypeFilterProvider.notifier).state =
                      OutletTypeFilter.all;
                  ref.read(outletStatusFilterProvider.notifier).state =
                      OutletStatusFilter.all;
                  ref.read(outletPageProvider.notifier).state = 1;
                },
              ),
              _FilterPill(
                label: 'Store',
                isSelected: typeFilter == OutletTypeFilter.store,
                onTap: () {
                  ref.read(outletTypeFilterProvider.notifier).state =
                      OutletTypeFilter.store;
                  ref.read(outletPageProvider.notifier).state = 1;
                },
              ),
              _FilterPill(
                label: 'Warehouse',
                isSelected: typeFilter == OutletTypeFilter.warehouse,
                onTap: () {
                  ref.read(outletTypeFilterProvider.notifier).state =
                      OutletTypeFilter.warehouse;
                  ref.read(outletPageProvider.notifier).state = 1;
                },
              ),
              _FilterPill(
                label: 'Active',
                isSelected: statusFilter == OutletStatusFilter.active,
                dotColor: TenantAdminColors.success,
                onTap: () {
                  ref.read(outletStatusFilterProvider.notifier).state =
                      OutletStatusFilter.active;
                  ref.read(outletPageProvider.notifier).state = 1;
                },
              ),
              _FilterPill(
                label: 'Needs Attention',
                isSelected: statusFilter == OutletStatusFilter.inactive,
                dotColor: TenantAdminColors.warning,
                onTap: () {
                  ref.read(outletStatusFilterProvider.notifier).state =
                      OutletStatusFilter.inactive;
                  ref.read(outletPageProvider.notifier).state = 1;
                },
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _FilterPill extends StatelessWidget {
  const _FilterPill({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.dotColor,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Color? dotColor;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? TenantAdminColors.posHomeAccentOrange
              : TenantAdminColors.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected
                ? TenantAdminColors.posHomeAccentOrange
                : TenantAdminColors.border,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: TenantAdminColors.posHomeAccentOrange
                        .withValues(alpha: 0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (dotColor != null) ...[
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : dotColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                color: isSelected ? Colors.white : TenantAdminColors.bodyText,
              ),
            ),
          ],
        ),
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

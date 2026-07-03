import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../domain/services/tenant_admin_access_checker.dart';
import '../../../presentation/theme/tenant_admin_theme.dart';
import '../../../presentation/widgets/tenant_admin_buttons.dart';
import '../../../presentation/widgets/tenant_admin_search_field.dart';
import '../../../presentation/widgets/tenant_admin_states.dart';
import '../../domain/entities/till.dart';
import '../providers/till_providers.dart';
import '../utils/till_list_filters.dart';
import 'till_list_view.dart';

class TillListPanel extends ConsumerWidget {
  const TillListPanel({
    super.key,
    required this.result,
    required this.visibility,
    required this.statusFilter,
    required this.isMobile,
  });

  final TillListResult result;
  final TillListVisibility visibility;
  final TillStatusFilter statusFilter;
  final bool isMobile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tillCountLabel =
        '${result.totalCount > 0 ? result.totalCount : result.items.length} '
        '${result.totalCount == 1 ? 'Till' : 'Tills'}';

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: TenantAdminColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: TenantAdminColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08071A33),
            blurRadius: 24,
            offset: Offset(0, 8),
          ),
          BoxShadow(
            color: Color(0x04071A33),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 16,
            ),
            child: isMobile
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _PanelTitle(countLabel: tillCountLabel),
                      const SizedBox(height: TenantAdminSpacing.md),
                      _PanelToolbar(
                        visibility: visibility,
                        statusFilter: statusFilter,
                        isMobile: true,
                      ),
                    ],
                  )
                : Row(
                    children: [
                      _PanelTitle(countLabel: tillCountLabel),
                      const SizedBox(width: TenantAdminSpacing.xl),
                      Expanded(
                        child: _PanelToolbar(
                          visibility: visibility,
                          statusFilter: statusFilter,
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
                title: statusFilter == TillStatusFilter.all
                    ? 'No tills found'
                    : 'No matching tills',
                message: statusFilter == TillStatusFilter.all
                    ? 'Create your first till to get started.'
                    : 'Try changing the filter or search term.',
                icon: statusFilter == TillStatusFilter.all
                    ? Icons.point_of_sale_outlined
                    : Icons.filter_alt_off_outlined,
                action: statusFilter == TillStatusFilter.all &&
                        visibility.showAddTill
                    ? TenantAdminPrimaryButton(
                        label: 'Add till',
                        icon: Icons.add,
                        onPressed: () => context.go('/tenant-admin/tills/add'),
                      )
                    : statusFilter != TillStatusFilter.all
                        ? TenantAdminSecondaryButton(
                            label: 'Clear filters',
                            icon: Icons.clear,
                            onPressed: () => _resetFilters(ref),
                          )
                        : null,
              ),
            )
          else
            TillListView(
              result: result,
              visibility: visibility,
              isMobile: isMobile,
            ),
          if (visibility.showPagination && result.totalCount > 0)
            _PaginationFooter(
              page: result.page,
              pageSize: result.pageSize,
              totalCount: result.totalCount,
              onPageChanged: (nextPage) =>
                  ref.read(tillPageProvider.notifier).state = nextPage,
            ),
        ],
      ),
    );
  }

  void _resetFilters(WidgetRef ref) {
    ref.read(tillStatusFilterProvider.notifier).state = TillStatusFilter.all;
    ref.read(tillSearchProvider.notifier).state = '';
    ref.read(tillPageProvider.notifier).state = 1;
  }
}

class TillSearchToolbar extends ConsumerWidget {
  const TillSearchToolbar({
    super.key,
    required this.visibility,
    required this.isMobile,
  });

  final TillListVisibility visibility;
  final bool isMobile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!visibility.showSearch && !visibility.showAddTill) {
      return const SizedBox.shrink();
    }

    final children = <Widget>[
      if (visibility.showSearch)
        Expanded(
          child: TenantAdminSearchField(
            hint: 'Search tills by name, code or outlet',
            value: ref.watch(tillSearchProvider),
            onChanged: (value) {
              ref.read(tillSearchProvider.notifier).state = value;
              ref.read(tillPageProvider.notifier).state = 1;
            },
          ),
        ),
      if (visibility.showAddTill) ...[
        if (visibility.showSearch) const SizedBox(width: TenantAdminSpacing.sm),
        TenantAdminPrimaryButton(
          label: isMobile ? 'Add' : 'Add till',
          icon: Icons.add,
          onPressed: () => context.go('/tenant-admin/tills/add'),
        ),
      ],
    ];

    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (visibility.showSearch)
            TenantAdminSearchField(
              hint: 'Search tills by name, code or outlet',
              value: ref.watch(tillSearchProvider),
              onChanged: (value) {
                ref.read(tillSearchProvider.notifier).state = value;
                ref.read(tillPageProvider.notifier).state = 1;
              },
            ),
          if (visibility.showAddTill) ...[
            if (visibility.showSearch)
              const SizedBox(height: TenantAdminSpacing.sm),
            Align(
              alignment: Alignment.centerRight,
              child: TenantAdminPrimaryButton(
                label: 'Add',
                icon: Icons.add,
                onPressed: () => context.go('/tenant-admin/tills/add'),
              ),
            ),
          ],
        ],
      );
    }

    return Row(children: children);
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
          'Till List',
          style: TenantAdminTextStyles.sectionTitle(context),
        ),
        const SizedBox(width: TenantAdminSpacing.sm),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: TenantAdminSpacing.sm,
            vertical: TenantAdminSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: TenantAdminColors.secondary,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            countLabel,
            style: const TextStyle(
              color: TenantAdminColors.primary,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

class _PanelToolbar extends ConsumerWidget {
  const _PanelToolbar({
    required this.visibility,
    required this.statusFilter,
    required this.isMobile,
  });

  final TillListVisibility visibility;
  final TillStatusFilter statusFilter;
  final bool isMobile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchField = visibility.showSearch
        ? TenantAdminSearchField(
            hint: 'Search tills by name, code or outlet',
            value: ref.watch(tillSearchProvider),
            onChanged: (value) {
              ref.read(tillSearchProvider.notifier).state = value;
              ref.read(tillPageProvider.notifier).state = 1;
            },
          )
        : null;

    final actionButtons = <Widget>[
      if (visibility.showFilters)
        TenantAdminSecondaryButton(
          label: 'Filter',
          icon: Icons.filter_alt_outlined,
          onPressed: () => _showFilterSheet(context, ref, statusFilter),
        ),
      if (visibility.showAddTill)
        TenantAdminPrimaryButton(
          label: isMobile ? 'Add' : 'Add New Till',
          icon: Icons.add,
          onPressed: () => context.go('/tenant-admin/tills/add'),
        ),
    ];

    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (searchField != null) searchField,
          if (searchField != null && actionButtons.isNotEmpty)
            const SizedBox(height: TenantAdminSpacing.sm),
          if (actionButtons.isNotEmpty)
            Wrap(
              spacing: TenantAdminSpacing.sm,
              runSpacing: TenantAdminSpacing.sm,
              children: actionButtons,
            ),
        ],
      );
    }

    return Row(
      children: [
        if (searchField != null) Expanded(child: searchField),
        for (var index = 0; index < actionButtons.length; index++) ...[
          if (searchField != null || index > 0)
            const SizedBox(width: TenantAdminSpacing.sm),
          actionButtons[index],
        ],
      ],
    );
  }
}

class _PaginationFooter extends StatelessWidget {
  const _PaginationFooter({
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
      padding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: TenantAdminSpacing.sm,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Showing $rangeStart to $rangeEnd of $totalCount tills',
              style: const TextStyle(
                color: TenantAdminColors.mutedText,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          _PageButton(
            icon: Icons.chevron_left,
            onPressed: page > 1 ? () => onPageChanged(page - 1) : null,
          ),
          const SizedBox(width: TenantAdminSpacing.sm),
          _PageNumber(
            label: '$page',
            active: true,
            onPressed: () {},
          ),
          if (page < totalPages) ...[
            const SizedBox(width: TenantAdminSpacing.sm),
            _PageNumber(
              label: '${page + 1}',
              active: false,
              onPressed: () => onPageChanged(page + 1),
            ),
          ],
          const SizedBox(width: TenantAdminSpacing.sm),
          _PageButton(
            icon: Icons.chevron_right,
            onPressed: page < totalPages ? () => onPageChanged(page + 1) : null,
          ),
        ],
      ),
    );
  }
}

class _PageButton extends StatelessWidget {
  const _PageButton({
    required this.icon,
    required this.onPressed,
  });

  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      style: IconButton.styleFrom(
        minimumSize: const Size(34, 34),
        padding: EdgeInsets.zero,
        side: const BorderSide(color: TenantAdminColors.border),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(TenantAdminRadius.sm),
        ),
      ),
      icon: Icon(icon, size: 18),
    );
  }
}

class _PageNumber extends StatelessWidget {
  const _PageNumber({
    required this.label,
    required this.active,
    required this.onPressed,
  });

  final String label;
  final bool active;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 34,
      height: 34,
      child: OutlinedButton(
        onPressed: active ? null : onPressed,
        style: OutlinedButton.styleFrom(
          padding: EdgeInsets.zero,
          backgroundColor:
              active ? TenantAdminColors.primary : TenantAdminColors.surface,
          foregroundColor: active ? Colors.white : TenantAdminColors.bodyText,
          disabledBackgroundColor: TenantAdminColors.primary,
          disabledForegroundColor: Colors.white,
          side: BorderSide(
            color:
                active ? TenantAdminColors.primary : TenantAdminColors.border,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(TenantAdminRadius.sm),
          ),
        ),
        child: Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
      ),
    );
  }
}

Future<void> _showFilterSheet(
  BuildContext context,
  WidgetRef ref,
  TillStatusFilter currentFilter,
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
                'Filter tills',
                style: TenantAdminTextStyles.sectionTitle(context),
              ),
              const SizedBox(height: TenantAdminSpacing.lg),
              for (final filter in TillStatusFilter.values)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    filter == TillStatusFilter.all
                        ? Icons.list_alt
                        : filter == TillStatusFilter.online
                            ? Icons.check_circle_outline
                            : filter == TillStatusFilter.offline
                                ? Icons.wifi_off
                                : Icons.warning_amber_rounded,
                    color: TenantAdminColors.primary,
                  ),
                  title: Text(filter.label),
                  trailing: currentFilter == filter
                      ? const Icon(Icons.check,
                          color: TenantAdminColors.primary)
                      : null,
                  onTap: () {
                    ref.read(tillStatusFilterProvider.notifier).state = filter;
                    ref.read(tillPageProvider.notifier).state = 1;
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

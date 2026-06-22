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
      padding: const EdgeInsets.all(TenantAdminSpacing.lg),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Showing $rangeStart to $rangeEnd of $totalCount tills',
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

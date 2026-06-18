import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../presentation/widgets/tenant_admin_buttons.dart';
import '../../../presentation/widgets/tenant_admin_filter_chip.dart';
import '../../../presentation/widgets/tenant_admin_page_scaffold.dart';
import '../../../presentation/widgets/tenant_admin_search_field.dart';
import '../../../presentation/widgets/tenant_admin_states.dart';
import '../providers/outlet_providers.dart';
import '../providers/outlet_visibility_provider.dart';
import '../widgets/outlet_metric_cards.dart';
import '../widgets/outlet_mobile_list.dart';
import '../widgets/outlet_table.dart';

class OutletListScreen extends ConsumerWidget {
  const OutletListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final visibilityState = ref.watch(outletListVisibilityProvider);
    final outletsState = ref.watch(outletListProvider);

    return visibilityState.when(
      loading: () => const TenantAdminPageScaffold(
        title: 'Outlets',
        subtitle: 'Manage the places where your business sells.',
        child: TenantAdminLoadingSkeleton(rowCount: 8),
      ),
      error: (error, stackTrace) => TenantAdminPageScaffold(
        title: 'Outlets',
        subtitle: 'Manage the places where your business sells.',
        child: TenantAdminErrorState(
          title: 'Unable to load outlets',
          message: 'Please try again.',
          onRetry: () => ref.invalidate(outletListVisibilityProvider),
        ),
      ),
      data: (visibility) {
        if (!visibility.showPage) {
          return const TenantAdminPageScaffold(
            title: 'No access to Outlets',
            child: TenantAdminEmptyState(
              title: 'No access',
              message: 'You do not have permission to view outlets.',
            ),
          );
        }

        return outletsState.when(
          loading: () => TenantAdminPageScaffold(
            title: visibility.showTitle ? 'Outlets' : '',
            subtitle: visibility.showSubtitle
                ? 'Manage the places where your business sells.'
                : null,
            child: const TenantAdminLoadingSkeleton(rowCount: 8),
          ),
          error: (error, stackTrace) => TenantAdminPageScaffold(
            title: 'Outlets',
            subtitle: 'Manage the places where your business sells.',
            child: TenantAdminErrorState(
              title: 'Unable to load outlets',
              message: 'Please try again.',
              onRetry: () => ref.refresh(outletListProvider),
            ),
          ),
          data: (result) {
            if (result == null) {
              return const TenantAdminPageScaffold(
                title: 'No access to Outlets',
                child: TenantAdminEmptyState(
                  title: 'No access',
                  message: 'You do not have permission to view outlets.',
                ),
              );
            }

            return LayoutBuilder(
              builder: (context, constraints) {
                final isMobile = constraints.maxWidth < 700;

                return TenantAdminPageScaffold(
                  title: visibility.showTitle ? 'Outlets' : '',
                  subtitle: visibility.showSubtitle
                      ? 'Manage the places where your business sells.'
                      : null,
                  actions: [
                    if (visibility.showAddOutlet)
                      TenantAdminPrimaryButton(
                        label: isMobile ? 'Add' : 'Add outlet',
                        icon: Icons.add,
                        onPressed: () =>
                            context.go('/tenant-admin/outlets/add'),
                      ),
                  ],
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (visibility.showSearch || visibility.showFilter)
                        Row(
                          children: [
                            if (visibility.showSearch)
                              Expanded(
                                child: TenantAdminSearchField(
                                  hint: 'Search outlets...',
                                  value: ref.watch(outletSearchProvider),
                                  onChanged: (value) {
                                    ref
                                        .read(outletSearchProvider.notifier)
                                        .state = value;
                                  },
                                ),
                              ),
                            if (visibility.showSearch && visibility.showFilter)
                              const SizedBox(width: 12),
                            if (visibility.showFilter)
                              TenantAdminSecondaryButton(
                                label: 'Filters',
                                icon: Icons.filter_list,
                                onPressed: () {},
                              ),
                          ],
                        ),
                      if (visibility.showSearch || visibility.showFilter)
                        const SizedBox(height: 16),
                      if (visibility.showSummarySection) ...[
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            TenantAdminFilterChip(
                              label: 'All',
                              selected: true,
                              count: result.summary.totalOutlets,
                              onTap: () {},
                            ),
                            TenantAdminFilterChip(
                              label: 'Active',
                              selected: false,
                              count: result.summary.activeOutlets,
                              onTap: () {},
                            ),
                            TenantAdminFilterChip(
                              label: 'Inactive',
                              selected: false,
                              count: result.summary.inactiveOutlets,
                              onTap: () {},
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        OutletMetricCards(
                          summary: result.summary,
                          compact: isMobile,
                          cards: visibility.visibleSummaryCards,
                        ),
                        const SizedBox(height: 24),
                      ],
                      if (visibility.showList && result.items.isEmpty)
                        const TenantAdminEmptyState(
                          title: 'No outlets found',
                          message: 'Create an outlet or adjust your search.',
                        )
                      else if (visibility.showList && isMobile)
                        OutletMobileList(
                          outlets: result.items,
                          visibility: visibility,
                        )
                      else if (visibility.showList)
                        OutletTable(
                          outlets: result.items,
                          columns: visibility.visibleColumns,
                          rowActions: visibility.visibleRowActions,
                        ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}

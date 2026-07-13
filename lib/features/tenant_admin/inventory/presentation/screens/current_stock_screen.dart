import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../presentation/theme/tenant_admin_theme.dart';
import '../../../presentation/widgets/tenant_admin_buttons.dart';
import '../../../presentation/widgets/tenant_admin_page_scaffold.dart';
import '../../../presentation/widgets/tenant_admin_states.dart';
import '../navigation/inventory_routes.dart';
import '../providers/inventory_providers.dart';
import '../providers/inventory_visibility_provider.dart';
import '../utils/inventory_api_errors.dart';
import '../widgets/current_stock_filter_bar.dart';
import '../widgets/current_stock_table.dart';
import '../widgets/inventory_summary_section.dart';
import '../widgets/inventory_pagination.dart';

class CurrentStockScreen extends ConsumerStatefulWidget {
  const CurrentStockScreen({super.key});

  @override
  ConsumerState<CurrentStockScreen> createState() => _CurrentStockScreenState();
}

class _CurrentStockScreenState extends ConsumerState<CurrentStockScreen> {
  bool _routeFiltersApplied = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_routeFiltersApplied) {
      return;
    }

    _routeFiltersApplied = true;
    Uri? uri;
    try {
      uri = GoRouterState.of(context).uri;
    } catch (_) {
      return;
    }

    final params = uri.queryParameters;
    applyCurrentStockRouteFilters(
      ref,
      stockStatus: params['stockStatus'] ??
          (params['filter'] == 'low-stock'
              ? 'LOW_STOCK'
              : params['filter'] == 'out-of-stock'
                  ? 'OUT_OF_STOCK'
                  : null),
      expiryStatus: params['expiryStatus'] ??
          (params['filter'] == 'expiring' ? 'EXPIRING' : null),
    );
  }

  @override
  Widget build(BuildContext context) {
    final visibilityState = ref.watch(currentStockVisibilityProvider);
    final listState = ref.watch(currentStockListProvider);
    final summaryState = ref.watch(currentStockSummaryProvider);
    final outlets = ref.watch(accessibleOutletOptionsProvider);
    final activeFilterCount = currentStockActiveFilterCount(ref);

    return visibilityState.when(
      loading: () => const TenantAdminPageScaffold(
        title: 'Current Stock',
        subtitle: 'View stock availability across accessible outlets.',
        child: TenantAdminLoadingSkeleton(rowCount: 8),
      ),
      error: (error, stackTrace) => TenantAdminPageScaffold(
        title: 'Current Stock',
        subtitle: 'View stock availability across accessible outlets.',
        child: TenantAdminErrorState(
          title: 'Unable to load current stock',
          message: inventoryApiErrorMessage(error),
          onRetry: () => ref.invalidate(currentStockVisibilityProvider),
        ),
      ),
      data: (visibility) {
        if (!visibility.showPage) {
          return const TenantAdminPageScaffold(
            title: 'No access to Current Stock',
            child: TenantAdminEmptyState(
              title: 'No access',
              message: 'You do not have permission to view current stock.',
              icon: Icons.inventory_2_outlined,
            ),
          );
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth < 700;
            final isCompactFilters = constraints.maxWidth < 1200;

            return TenantAdminPageScaffold(
              title: 'Current Stock',
              subtitle: 'View stock availability across accessible outlets.',
              actions: visibility.showStockInAction
                  ? [
                      TenantAdminPrimaryButton(
                        label: 'Stock In',
                        icon: Icons.add,
                        onPressed: () => context.go(InventoryRoutes.stockIn),
                      ),
                    ]
                  : const [],
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (visibility.showSummarySection) ...[
                    InventorySummarySection(
                      summary: summaryState.asData?.value,
                      compact: isMobile,
                      loading: summaryState.isLoading,
                    ),
                    const SizedBox(height: TenantAdminSpacing.xl),
                  ],
                  if (visibility.showFilters)
                    CurrentStockFilterBar(
                      outlets: outlets,
                      isMobile: isMobile || isCompactFilters,
                      activeFilterCount: activeFilterCount,
                      onClearFilters: () => clearCurrentStockFilters(ref),
                    ),
                  if (visibility.showFilters)
                    const SizedBox(height: TenantAdminSpacing.lg),
                  if (outlets.isEmpty)
                    const TenantAdminEmptyState(
                      title: 'No accessible outlets',
                      message:
                          'You do not have access to any outlets for stock visibility.',
                      icon: Icons.store_outlined,
                    )
                  else
                    listState.when(
                      loading: () => const TenantAdminLoadingSkeleton(
                        rowCount: 8,
                      ),
                      error: (error, stackTrace) => TenantAdminErrorState(
                        title: 'Unable to load stock',
                        message: inventoryApiErrorMessage(error),
                        onRetry: () => ref.refresh(currentStockListProvider),
                      ),
                      data: (page) {
                        if (page == null) {
                          return const TenantAdminEmptyState(
                            title: 'No access',
                            message:
                                'You do not have permission to view current stock.',
                          );
                        }

                        final hasFilters = ref
                            .read(currentStockQueryProvider)
                            .hasActiveFilters;

                        if (page.items.isEmpty && !hasFilters) {
                          return TenantAdminEmptyState(
                            title: 'No stock records yet',
                            message:
                                'Stock will appear after products are received into an accessible outlet.',
                            icon: Icons.inventory_2_outlined,
                            action: visibility.showStockInAction
                                ? TenantAdminPrimaryButton(
                                    label: 'Stock In',
                                    icon: Icons.add,
                                    onPressed: () =>
                                        context.go(InventoryRoutes.stockIn),
                                  )
                                : null,
                          );
                        }

                        if (page.items.isEmpty && hasFilters) {
                          return TenantAdminEmptyState(
                            title: 'No matching stock found',
                            message:
                                'Try changing or clearing the selected filters.',
                            action: TenantAdminSecondaryButton(
                              label: 'Clear filters',
                              onPressed: () => clearCurrentStockFilters(ref),
                            ),
                          );
                        }

                        if (isMobile) {
                          return Column(
                            children: [
                              ...page.items.map(
                                (item) => CurrentStockMobileCard(
                                  item: item,
                                  showStockInAction:
                                      visibility.showStockInAction,
                                  onStockIn: () =>
                                      context.go(InventoryRoutes.stockIn),
                                ),
                              ),
                              InventoryPagination(
                                page: page.page,
                                pageSize: page.pageSize,
                                totalCount: page.totalCount,
                                label: 'stock records',
                                onPageChanged: (nextPage) => ref
                                    .read(currentStockPageProvider.notifier)
                                    .state = nextPage,
                              ),
                            ],
                          );
                        }

                        return CurrentStockTable(
                          page: page,
                          loading: false,
                          errorMessage: null,
                          onRetry: null,
                          onPageChanged: (nextPage) => ref
                              .read(currentStockPageProvider.notifier)
                              .state = nextPage,
                          showStockInAction: visibility.showStockInAction,
                          onStockIn: () => context.go(InventoryRoutes.stockIn),
                        );
                      },
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../presentation/providers/tenant_admin_access_provider.dart';
import '../../../presentation/theme/tenant_admin_theme.dart';
import '../../../presentation/widgets/tenant_admin_page_scaffold.dart';
import '../../../presentation/widgets/tenant_admin_states.dart';
import '../../domain/entities/product_dashboard.dart';
import 'product_dashboard_header.dart';
import 'product_dashboard_providers.dart';
import 'product_dashboard_skeleton.dart';
import 'product_dashboard_summary_grid.dart';
import 'product_dashboard_visibility.dart';
import 'product_stock_movement_card.dart';
import 'product_stock_value_card.dart';

class ProductDashboardPage extends ConsumerWidget {
  const ProductDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final visibilityState = ref.watch(productDashboardVisibilityProvider);

    return visibilityState.when(
      loading: () => const TenantAdminPageScaffold(
        title: 'Product Dashboard',
        child: ProductDashboardSkeleton(),
      ),
      error: (error, stackTrace) => TenantAdminPageScaffold(
        title: 'Product Dashboard',
        child: ProductDashboardErrorState(
          onRetry: () => ref.invalidate(productDashboardVisibilityProvider),
        ),
      ),
      data: (visibility) {
        if (!visibility.showPage) {
          return const TenantAdminPageScaffold(
            title: 'Product Dashboard',
            child: TenantAdminEmptyState(
              title: 'No access',
              message:
                  'You do not have permission to view the product dashboard.',
              icon: Icons.dashboard_outlined,
            ),
          );
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth < 700;

            return TenantAdminPageScaffold(
              title: 'Product Dashboard',
              child: _ProductDashboardBody(
                visibility: visibility,
                compact: isMobile,
              ),
            );
          },
        );
      },
    );
  }
}

class _ProductDashboardBody extends ConsumerWidget {
  const _ProductDashboardBody({
    required this.visibility,
    required this.compact,
  });

  final ProductDashboardVisibility visibility;
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardState = ref.watch(productDashboardProvider);
    final cachedDashboard = ref.watch(productDashboardCacheProvider);
    final isRefreshing = ref.watch(productDashboardRefreshingProvider);
    final access = ref.watch(tenantAdminAccessCheckerProvider).valueOrNull;

    final isInitialLoading = dashboardState.isLoading && cachedDashboard == null;
    final isStaleLoading =
        dashboardState.isLoading && dashboardState.hasError == false;

    if (isInitialLoading || (isStaleLoading && cachedDashboard == null)) {
      return ProductDashboardSkeleton(compact: compact);
    }

    if (dashboardState.hasError &&
        dashboardState.error is! StaleProductDashboardRequest &&
        cachedDashboard == null) {
      return ProductDashboardErrorState(
        onRetry: () => ref.refresh(productDashboardProvider),
      );
    }

    final dashboard = dashboardState.value ?? cachedDashboard;
    if (dashboard == null) {
      return const TenantAdminEmptyState(
        title: 'No access',
        message: 'You do not have permission to view dashboard data.',
        icon: Icons.dashboard_outlined,
      );
    }

    if (_isEmptyProductCatalog(dashboard, visibility)) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ProductDashboardHeader(
            visibility: visibility,
            lastUpdatedAt: dashboard.lastUpdatedAt,
            isRefreshing: isRefreshing,
            onRefresh: () => refreshProductDashboard(ref),
            compact: compact,
          ),
          ProductDashboardEmptyState(
            showAddProduct: access?.canCreateProduct() ?? false,
          ),
        ],
      );
    }

    final hasSummary = visibility.showSummarySection &&
        dashboard.summary != null &&
        visibility.visibleSummaryMetrics.isNotEmpty;
    final hasStockValue =
        visibility.showStockValueCard && dashboard.stockValue != null;
    final hasStockMovement = visibility.showStockMovementCard &&
        dashboard.stockMovement != null;

    if (!hasSummary && !hasStockValue && !hasStockMovement) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ProductDashboardHeader(
            visibility: visibility,
            lastUpdatedAt: dashboard.lastUpdatedAt,
            isRefreshing: isRefreshing,
            onRefresh: () => refreshProductDashboard(ref),
            compact: compact,
          ),
          const ProductDashboardPermissionEmptyState(),
        ],
      );
    }

    final filter = ref.watch(productDashboardFilterProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ProductDashboardHeader(
          visibility: visibility,
          lastUpdatedAt: dashboard.lastUpdatedAt,
          isRefreshing: isRefreshing,
          onRefresh: () => refreshProductDashboard(ref),
          compact: compact,
        ),
        if (hasSummary) ...[
          ProductDashboardSummaryGrid(
            summary: dashboard.summary!,
            visibility: visibility,
            access: access,
            currencyCode: dashboard.currencyCode,
            compact: compact,
          ),
          const SizedBox(height: TenantAdminSpacing.xl),
        ],
        if (hasStockValue || hasStockMovement)
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 900;

              if (isNarrow) {
                return Column(
                  children: [
                    if (hasStockValue)
                      ProductStockValueCard(
                        stockValue: dashboard.stockValue!,
                        currencyCode: dashboard.currencyCode,
                      ),
                    if (hasStockValue && hasStockMovement)
                      const SizedBox(height: TenantAdminSpacing.lg),
                    if (hasStockMovement)
                      ProductStockMovementCard(
                        stockMovement: dashboard.stockMovement!,
                        dateLabel: filter.dateLabel,
                        access: access,
                      ),
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (hasStockValue)
                    Expanded(
                      flex: 3,
                      child: ProductStockValueCard(
                        stockValue: dashboard.stockValue!,
                        currencyCode: dashboard.currencyCode,
                      ),
                    ),
                  if (hasStockValue && hasStockMovement)
                    const SizedBox(width: TenantAdminSpacing.lg),
                  if (hasStockMovement)
                    Expanded(
                      flex: 2,
                      child: ProductStockMovementCard(
                        stockMovement: dashboard.stockMovement!,
                        dateLabel: filter.dateLabel,
                        access: access,
                      ),
                    ),
                ],
              );
            },
          ),
      ],
    );
  }

  bool _isEmptyProductCatalog(
    ProductDashboard dashboard,
    ProductDashboardVisibility visibility,
  ) {
    if (!visibility.visibleSummaryMetrics
        .contains(ProductDashboardSummaryMetricKey.totalProducts)) {
      return false;
    }

    final totalProducts = dashboard.summary?.totalProducts?.value ?? 0;
    return totalProducts == 0;
  }
}

class ProductDashboardErrorState extends StatelessWidget {
  const ProductDashboardErrorState({
    super.key,
    required this.onRetry,
  });

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return TenantAdminErrorState(
      title: 'Unable to load dashboard data',
      message: 'Please try again.',
      onRetry: onRetry,
    );
  }
}

class ProductDashboardEmptyState extends StatelessWidget {
  const ProductDashboardEmptyState({
    super.key,
    required this.showAddProduct,
  });

  final bool showAddProduct;

  @override
  Widget build(BuildContext context) {
    return TenantAdminEmptyState(
      title: 'No products yet',
      message: 'No products have been created yet.',
      icon: Icons.inventory_2_outlined,
      action: showAddProduct
          ? FilledButton(
              onPressed: () => context.go('/tenant-admin/products/add'),
              child: const Text('Add Product'),
            )
          : null,
    );
  }
}

class ProductDashboardPermissionEmptyState extends StatelessWidget {
  const ProductDashboardPermissionEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return const TenantAdminEmptyState(
      title: 'No dashboard data',
      message: 'No metrics are available for your current permissions.',
      icon: Icons.insights_outlined,
    );
  }
}

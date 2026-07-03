import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../presentation/theme/tenant_admin_theme.dart';
import '../../../presentation/widgets/tenant_admin_page_scaffold.dart';
import '../../../presentation/widgets/tenant_admin_states.dart';
import '../../domain/entities/inventory.dart';
import '../../domain/repositories/inventory_repository.dart';
import '../config/inventory_api_capabilities.dart';
import '../providers/inventory_providers.dart';
import '../providers/inventory_visibility_provider.dart';
import '../utils/inventory_api_errors.dart';
import '../widgets/current_stock_metric_cards.dart';
import '../widgets/current_stock_panel.dart';
import '../widgets/inventory_form_widgets.dart';

class CurrentStockScreen extends ConsumerWidget {
  const CurrentStockScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final visibilityState = ref.watch(currentStockVisibilityProvider);

    return visibilityState.when(
      loading: () => const TenantAdminPageScaffold(
        title: 'Current Stock',
        child: TenantAdminLoadingSkeleton(rowCount: 8),
      ),
      error: (error, stackTrace) => TenantAdminPageScaffold(
        title: 'Current Stock',
        child: TenantAdminErrorState(
          title: 'Unable to load permissions',
          message: 'Please try again.',
          onRetry: () => ref.invalidate(currentStockVisibilityProvider),
        ),
      ),
      data: (visibility) {
        if (!visibility.showPage) {
          return const TenantAdminPageScaffold(
            title: 'Current Stock',
            child: TenantAdminEmptyState(
              title: 'Permission denied',
              message: 'You do not have permission to view stock.',
            ),
          );
        }

        if (!visibility.balancesApiAvailable) {
          return TenantAdminPageScaffold(
            title: 'Current Stock',
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InventoryApiBanner(
                  message:
                      'Inventory balances API is not available yet (GET /api/v1/inventory/balances). '
                      'Stock levels will appear here once the backend endpoint is enabled.',
                ),
                TenantAdminEmptyState(
                  title: 'Stock data unavailable',
                  message:
                      'Current stock cannot be loaded until the inventory balances API is available.',
                  icon: Icons.inventory_2_outlined,
                ),
              ],
            ),
          );
        }

        final balancesState = ref.watch(inventoryBalancesProvider);
        final locationsState = InventoryApiCapabilities.listLocations
            ? ref.watch(inventoryLocationsProvider)
            : const AsyncData(<InventoryLocation>[]);

        return balancesState.when(
          loading: () => const TenantAdminPageScaffold(
            title: 'Current Stock',
            child: TenantAdminLoadingSkeleton(rowCount: 8),
          ),
          error: (error, stackTrace) {
            if (error is InventoryApiUnavailable) {
              return TenantAdminPageScaffold(
                title: 'Current Stock',
                child: TenantAdminEmptyState(
                  title: 'Stock data unavailable',
                  message: inventoryLoadErrorMessage(error),
                  icon: Icons.inventory_2_outlined,
                ),
              );
            }

            final isForbidden =
                error is DioException && error.response?.statusCode == 403;
            final isUnauthorized =
                error is DioException && error.response?.statusCode == 401;

            return TenantAdminPageScaffold(
              title: 'Current Stock',
              child: isForbidden
                  ? const TenantAdminEmptyState(
                      title: 'Permission denied',
                      message:
                          'You do not have permission to view stock balances.',
                    )
                  : isUnauthorized
                      ? const TenantAdminEmptyState(
                          title: 'Session expired',
                          message:
                              'Your session has expired. Please sign in again.',
                        )
                      : TenantAdminErrorState(
                          title: 'Unable to load stock',
                          message: inventoryLoadErrorMessage(error),
                          onRetry: () => ref.refresh(inventoryBalancesProvider),
                        ),
            );
          },
          data: (result) {
            if (result == null) {
              return const TenantAdminPageScaffold(
                title: 'Current Stock',
                child: TenantAdminEmptyState(
                  title: 'Permission denied',
                  message: 'You do not have permission to view stock.',
                ),
              );
            }

            return LayoutBuilder(
              builder: (context, constraints) {
                final isMobile = constraints.maxWidth < 700;

                return TenantAdminPageScaffold(
                  title: 'Current Stock',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (visibility.showSummaryCards) ...[
                        CurrentStockMetricCards(
                          summary: result.summary,
                          compact: isMobile,
                          showLowStockCount:
                              result.summary.lowStockItems != null,
                        ),
                        const SizedBox(height: TenantAdminSpacing.lg),
                      ],
                      CurrentStockPanel(
                        result: result,
                        visibility: visibility,
                        isMobile: isMobile,
                        locations: locationsState.valueOrNull ?? const [],
                        locationsLoading: locationsState.isLoading,
                        onView: visibility.showTable ? (_) {} : null,
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

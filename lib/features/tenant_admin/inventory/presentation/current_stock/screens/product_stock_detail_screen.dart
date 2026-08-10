import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../presentation/widgets/tenant_admin_page_scaffold.dart';
import '../../../../presentation/widgets/tenant_admin_states.dart';
import '../providers/current_stock_providers.dart';

import '../widgets/product_info_card.dart';
import '../widgets/product_location_balances_list.dart';
import '../widgets/product_movement_history_tab.dart';
import '../widgets/stock_metrics_cards.dart';

/// Entry point for the Product Stock Detail page.
///
/// Uses [TenantAdminPageScaffold] so the shared sidebar and dark top-bar
/// are preserved. The page header (breadcrumb, title, scope selector) is
/// rendered inline as part of the page content via [ProductDetailPageHeader].
class ProductStockDetailScreen extends ConsumerWidget {
  const ProductStockDetailScreen({
    super.key,
    required this.variantId,
  });

  final String variantId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailState = ref.watch(productStockDetailProvider(variantId));

    // Resolve outlet label for metric cards
    final selectedOutletId = ref.watch(currentStockOutletFilterProvider);
    final outletsAsync = ref.watch(inventoryOutletsProvider);
    final outletLabel = outletsAsync.maybeWhen(
      data: (outlets) {
        if (selectedOutletId == null) return 'At All Outlets';
        final match = outlets.where((o) => o.id == selectedOutletId);
        return match.isNotEmpty ? 'At ${match.first.name}' : 'At All Outlets';
      },
      orElse: () => 'At All Outlets',
    );

    return TenantAdminPageScaffold(
      title: 'Product Stock Detail',
      subtitle: 'Detailed stock information and movement history for this product.',
      showBackButton: true,
      onBackButtonPressed: () {
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        } else {
          context.go('/tenant-admin/stock/current');
        }
      },
      child: detailState.when(
        loading: () => const TenantAdminLoadingSkeleton(),
        error: (err, stack) => TenantAdminErrorState(
          title: 'Error loading product',
          message: err.toString(),
        ),
        data: (detail) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── Product image, name, status chips, action buttons ──
            ProductInfoCard(detail: detail),
            const SizedBox(height: 20),
            // ── Metric cards: On Hand / Reserved / Available / Reorder ──
            StockMetricsCards(detail: detail, outletLabel: outletLabel),
            const SizedBox(height: 20),
            // ── Location Balances (left) + Recent Movements (right) ──
            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth < 1000) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ProductLocationBalancesTable(detail: detail),
                      const SizedBox(height: 20),
                      RecentMovementsTable(variantId: variantId),
                    ],
                  );
                }

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: ProductLocationBalancesTable(detail: detail),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: RecentMovementsTable(variantId: variantId),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../presentation/theme/tenant_admin_theme.dart';
import '../../../presentation/widgets/tenant_admin_page_scaffold.dart';
import '../../../presentation/widgets/tenant_admin_states.dart';
import '../providers/product_providers.dart';
import '../providers/product_visibility_provider.dart';
import '../utils/product_api_errors.dart';
import '../widgets/product_list_panel.dart';
import '../widgets/product_metric_cards.dart';
import '../widgets/product_top_selling_card.dart';

class ProductListScreen extends ConsumerWidget {
  const ProductListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final visibilityState = ref.watch(productListVisibilityProvider);
    final productsState = ref.watch(productListProvider);
    final statusFilter = ref.watch(productStatusFilterProvider);

    return visibilityState.when(
      loading: () => const TenantAdminPageScaffold(
        title: 'Products',
        subtitle: 'Manage your products, categories and pricing.',
        child: TenantAdminLoadingSkeleton(rowCount: 8),
      ),
      error: (error, stackTrace) => TenantAdminPageScaffold(
        title: 'Products',
        subtitle: 'Manage your products, categories and pricing.',
        child: TenantAdminErrorState(
          title: 'Unable to load products',
          message: productLoadErrorMessage(error),
          onRetry: () => ref.invalidate(productListVisibilityProvider),
        ),
      ),
      data: (visibility) {
        if (!visibility.showPage) {
          return const TenantAdminPageScaffold(
            title: 'No access to Products',
            child: TenantAdminEmptyState(
              title: 'No access',
              message: 'You do not have permission to view products.',
            ),
          );
        }

        return productsState.when(
          loading: () => TenantAdminPageScaffold(
            title: visibility.showTitle ? 'Products' : '',
            subtitle: visibility.showSubtitle
                ? 'Manage your products, categories and pricing.'
                : null,
            child: const TenantAdminLoadingSkeleton(rowCount: 8),
          ),
          error: (error, stackTrace) {
            final isForbidden =
                error is DioException && error.response?.statusCode == 403;

            return TenantAdminPageScaffold(
              title: 'Products',
              subtitle: 'Manage your products, categories and pricing.',
              child: isForbidden
                  ? const TenantAdminEmptyState(
                      title: 'Permission denied',
                      message:
                          'You do not have permission to view products.',
                    )
                  : TenantAdminErrorState(
                      title: 'Unable to load products',
                      message: productLoadErrorMessage(error),
                      onRetry: () => ref.refresh(productListProvider),
                    ),
            );
          },
          data: (result) {
            if (result == null) {
              return const TenantAdminPageScaffold(
                title: 'No access to Products',
                child: TenantAdminEmptyState(
                  title: 'No access',
                  message: 'You do not have permission to view products.',
                ),
              );
            }

            return LayoutBuilder(
              builder: (context, constraints) {
                final isMobile = constraints.maxWidth < 700;
                final showTopSellingLayout =
                    visibility.showTopSelling && !isMobile;

                return TenantAdminPageScaffold(
                  title: visibility.showTitle ? 'Products' : '',
                  subtitle: visibility.showSubtitle
                      ? 'Manage your products, categories and pricing.'
                      : null,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (visibility.showSummarySection) ...[
                        if (showTopSellingLayout)
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 3,
                                child: ProductMetricCards(
                                  summary: result.summary,
                                  compact: false,
                                  cards: visibility.visibleSummaryCards,
                                ),
                              ),
                              const SizedBox(width: 18),
                              const Expanded(
                                flex: 2,
                                child: ProductTopSellingCard(),
                              ),
                            ],
                          )
                        else
                          ProductMetricCards(
                            summary: result.summary,
                            compact: isMobile,
                            cards: visibility.visibleSummaryCards,
                          ),
                        const SizedBox(height: 24),
                      ],
                      if (visibility.showList)
                        ProductListPanel(
                          result: result,
                          visibility: visibility,
                          statusFilter: statusFilter,
                          isMobile: isMobile,
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

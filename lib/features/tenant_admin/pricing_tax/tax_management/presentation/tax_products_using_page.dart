import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../presentation/theme/tenant_admin_theme.dart';
import '../../../presentation/widgets/tenant_admin_page_scaffold.dart';
import '../../../presentation/widgets/tenant_admin_pagination.dart';
import '../../../presentation/widgets/tenant_admin_search_field.dart';
import '../../../presentation/widgets/tenant_admin_states.dart';
import '../../../presentation/widgets/tenant_admin_status_badge.dart';
import '../application/tax_management_controller.dart';
import 'providers/tax_list_providers.dart';
import 'utils/tax_formatters.dart';

class TaxProductsUsingPage extends ConsumerWidget {
  const TaxProductsUsingPage({
    super.key,
    required this.taxId,
    required this.taxName,
  });

  final String taxId;
  final String taxName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(taxProductsProvider(taxId));
    final search = ref.watch(taxProductsSearchProvider(taxId));

    return TenantAdminPageScaffold(
      title: 'Products Using Tax',
      subtitle: 'Products currently assigned to $taxName.',
      scrollable: false,
      fillHeight: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TenantAdminSearchField(
            hint: 'Search products by name or code...',
            value: search,
            onChanged: (value) {
              ref.read(taxProductsSearchProvider(taxId).notifier).state = value;
              ref.read(taxProductsPageProvider(taxId).notifier).state = 1;
            },
          ),
          const SizedBox(height: TenantAdminSpacing.lg),
          Expanded(
            child: productsAsync.when(
              loading: () => const TenantAdminLoadingSkeleton(rowCount: 5),
              error: (error, _) => TenantAdminErrorState(
                title: 'Unable to load products',
                message: taxApiErrorMessage(error),
                onRetry: () => ref.invalidate(taxProductsProvider(taxId)),
              ),
              data: (result) {
                if (result.items.isEmpty) {
                  return TenantAdminEmptyState(
                    title: search.trim().isEmpty
                        ? 'No products using this tax'
                        : 'No matching products',
                    message: search.trim().isEmpty
                        ? 'No products are currently assigned to this tax setup.'
                        : 'No products match your search.',
                    icon: Icons.inventory_2_outlined,
                  );
                }

                return Column(
                  children: [
                    Expanded(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: TenantAdminColors.surface,
                          borderRadius:
                              BorderRadius.circular(TenantAdminRadius.lg),
                          border:
                              Border.all(color: TenantAdminColors.border),
                        ),
                        child: ClipRRect(
                          borderRadius:
                              BorderRadius.circular(TenantAdminRadius.lg),
                          child: ListView.separated(
                            itemCount: result.items.length,
                            separatorBuilder: (_, __) => const Divider(
                              height: 1,
                              color: TenantAdminColors.border,
                            ),
                            itemBuilder: (context, index) {
                              final item = result.items[index];
                              final isActive =
                                  item.status.toUpperCase() == 'ACTIVE';
                              return ListTile(
                                title: Text(
                                  item.productName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                subtitle: Text(item.productCode),
                                trailing: Wrap(
                                  spacing: 8,
                                  crossAxisAlignment:
                                      WrapCrossAlignment.center,
                                  children: [
                                    Text(
                                      item.taxPriceMode.label,
                                      style: const TextStyle(
                                        color: TenantAdminColors.mutedText,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    TenantAdminStatusBadge(
                                      label: taxProductStatusLabel(item.status),
                                      status: isActive
                                          ? TenantAdminStatusType.active
                                          : TenantAdminStatusType.inactive,
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                    if (result.totalCount > 0)
                      TenantAdminPaginationBar(
                        currentPage: result.pageNumber,
                        pageSize: result.pageSize,
                        totalCount: result.totalCount,
                        itemLabel: 'products',
                        onPageChanged: (page) => ref
                            .read(taxProductsPageProvider(taxId).notifier)
                            .state = page,
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

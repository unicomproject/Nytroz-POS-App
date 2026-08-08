import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../presentation/theme/tenant_admin_theme.dart';
import '../../../presentation/widgets/tenant_admin_buttons.dart';
import '../../../presentation/widgets/tenant_admin_page_scaffold.dart';
import '../../../presentation/widgets/tenant_admin_search_field.dart';
import '../../../presentation/widgets/tenant_admin_states.dart';
import '../../domain/entities/curated_popular_product.dart';
import '../providers/popular_products_provider.dart';

class PopularProductsCurationScreen extends ConsumerWidget {
  const PopularProductsCurationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stateAsync = ref.watch(popularProductsCurationProvider);

    return stateAsync.when(
      loading: () => const TenantAdminPageScaffold(
        title: 'Popular Products',
        subtitle:
            'Curate and reorder popular products displayed on the cashier screen.',
        child: TenantAdminLoadingSkeleton(rowCount: 8),
      ),
      error: (error, stackTrace) => TenantAdminPageScaffold(
        title: 'Popular Products',
        subtitle:
            'Curate and reorder popular products displayed on the cashier screen.',
        child: TenantAdminErrorState(
          title: 'Unable to load popular products',
          message: 'Please try again.',
          onRetry: () => ref.invalidate(popularProductsCurationProvider),
        ),
      ),
      data: (products) {
        return TenantAdminPageScaffold(
          title: 'Popular Products',
          subtitle:
              'Curate and reorder popular products displayed on the cashier screen.',
          actions: [
            TenantAdminPrimaryButton(
              label: 'Save Changes',
              icon: Icons.save,
              onPressed: products.isNotEmpty
                  ? () async {
                      try {
                        await ref
                            .read(popularProductsCurationProvider.notifier)
                            .save();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text(
                                    'Popular products configuration saved successfully.')),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                  'Failed to save changes: ${e.toString()}'),
                              backgroundColor: TenantAdminColors.danger,
                            ),
                          );
                        }
                      }
                    }
                  : null,
            ),
          ],
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Curated List (${products.length} Products)',
                    style: const TextStyle(
                      color: TenantAdminColors.bodyText,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TenantAdminSecondaryButton(
                    label: 'Add Product',
                    icon: Icons.add,
                    onPressed: () =>
                        _showAddProductDialog(context, ref, products),
                  ),
                ],
              ),
              const SizedBox(height: TenantAdminSpacing.md),
              if (products.isEmpty)
                const Card(
                  color: Colors.white,
                  child: Padding(
                    padding: EdgeInsets.all(TenantAdminSpacing.xl),
                    child: Center(
                      child: TenantAdminEmptyState(
                        title: 'No products curated yet',
                        message:
                            'Click "Add Product" to select popular items for the POS dashboard.',
                        icon: Icons.star_outline_rounded,
                      ),
                    ),
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    final product = products[index];
                    return Card(
                      key: ValueKey(product.productId),
                      margin:
                          const EdgeInsets.only(bottom: TenantAdminSpacing.sm),
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(TenantAdminRadius.md),
                        side: const BorderSide(color: TenantAdminColors.border),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          radius: 16,
                          backgroundColor: TenantAdminColors.secondary,
                          child: Text(
                            '${index + 1}',
                            style: const TextStyle(
                              color: TenantAdminColors.primary,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(
                          product.productName,
                          style: const TextStyle(
                            color: TenantAdminColors.bodyText,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        subtitle: Text(
                          product.sku ?? 'No SKU',
                          style: const TextStyle(
                            color: TenantAdminColors.mutedText,
                            fontSize: 12,
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.arrow_upward_rounded,
                                  size: 20),
                              tooltip: 'Move up',
                              onPressed: index > 0
                                  ? () => ref
                                      .read(popularProductsCurationProvider
                                          .notifier)
                                      .reorder(index, index - 1)
                                  : null,
                            ),
                            IconButton(
                              icon: const Icon(Icons.arrow_downward_rounded,
                                  size: 20),
                              tooltip: 'Move down',
                              onPressed: index < products.length - 1
                                  ? () => ref
                                      .read(popularProductsCurationProvider
                                          .notifier)
                                      .reorder(index, index + 2)
                                  : null,
                            ),
                            const SizedBox(width: TenantAdminSpacing.sm),
                            IconButton(
                              icon: const Icon(Icons.delete_outline_rounded,
                                  color: TenantAdminColors.danger, size: 20),
                              tooltip: 'Remove',
                              onPressed: () => ref
                                  .read(
                                      popularProductsCurationProvider.notifier)
                                  .removeProduct(product.productId),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  void _showAddProductDialog(BuildContext context, WidgetRef ref,
      List<CuratedPopularProduct> currentPopular) {
    ref.invalidate(popularSearchQueryProvider);
    ref.invalidate(popularSearchPageProvider);

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(TenantAdminRadius.lg),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
            child: Consumer(
              builder: (context, ref, _) {
                final searchAsync = ref.watch(popularSearchProductsProvider);
                final query = ref.watch(popularSearchQueryProvider);

                return Padding(
                  padding: const EdgeInsets.all(TenantAdminSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Add Product to Popular List',
                        style: TextStyle(
                          color: TenantAdminColors.bodyText,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: TenantAdminSpacing.md),
                      TenantAdminSearchField(
                        hint: 'Search products by name or SKU',
                        value: query,
                        onChanged: (val) {
                          ref.read(popularSearchQueryProvider.notifier).state =
                              val;
                          ref.read(popularSearchPageProvider.notifier).state =
                              1;
                        },
                      ),
                      const SizedBox(height: TenantAdminSpacing.md),
                      Expanded(
                        child: searchAsync.when(
                          loading: () =>
                              const Center(child: CircularProgressIndicator()),
                          error: (err, stack) => const TenantAdminErrorState(
                            title: 'Unable to search products',
                            message: 'Please try again.',
                          ),
                          data: (result) {
                            if (result == null || result.items.isEmpty) {
                              return const Center(
                                child: Text(
                                    'No active products found matching search.'),
                              );
                            }

                            return ListView.builder(
                              itemCount: result.items.length,
                              itemBuilder: (context, index) {
                                final product = result.items[index];
                                final isAlreadyAdded = currentPopular
                                    .any((p) => p.productId == product.id);

                                return Container(
                                  margin: const EdgeInsets.only(
                                      bottom: TenantAdminSpacing.xs),
                                  decoration: const BoxDecoration(
                                    border: Border(
                                        bottom: BorderSide(
                                            color: TenantAdminColors.border)),
                                  ),
                                  child: ListTile(
                                    title: Text(
                                      product.name,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w600),
                                    ),
                                    subtitle: Text(product.sku),
                                    trailing: isAlreadyAdded
                                        ? const Chip(
                                            label: Text('Curated',
                                                style: TextStyle(
                                                    fontSize: 11,
                                                    fontWeight:
                                                        FontWeight.bold)),
                                            backgroundColor:
                                                TenantAdminColors.secondary,
                                            side: BorderSide.none,
                                          )
                                        : TextButton.icon(
                                            icon:
                                                const Icon(Icons.add, size: 16),
                                            label: const Text('Add'),
                                            onPressed: () {
                                              ref
                                                  .read(
                                                      popularProductsCurationProvider
                                                          .notifier)
                                                  .addProduct(
                                                    product.id,
                                                    product.name,
                                                    product.sku,
                                                    product.status,
                                                  );
                                              Navigator.of(dialogContext).pop();
                                            },
                                          ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: TenantAdminSpacing.md),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TenantAdminSecondaryButton(
                            label: 'Close',
                            onPressed: () => Navigator.of(dialogContext).pop(),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}

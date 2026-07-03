import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../presentation/theme/tenant_admin_theme.dart';
import '../../../presentation/widgets/tenant_admin_search_field.dart';
import '../../domain/entities/inventory.dart';
import '../providers/inventory_providers.dart';

class StockInProductSelect extends ConsumerWidget {
  const StockInProductSelect({
    super.key,
    required this.enabled,
    required this.errorText,
    required this.onSelected,
  });

  final bool enabled;
  final String? errorText;
  final ValueChanged<StockProductOption?> onSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsState = ref.watch(stockInProductsProvider);
    final search = ref.watch(stockInProductSearchProvider);
    final selectedProductId = ref.watch(stockInSelectedProductIdProvider);
    final products = productsState.valueOrNull ?? const <StockProductOption>[];

    StockProductOption? selectedProduct;
    for (final product in products) {
      if (product.productId == selectedProductId) {
        selectedProduct = product;
        break;
      }
    }

    if (productsState.isLoading) {
      return const LinearProgressIndicator();
    }

    if (productsState.hasError) {
      return const Text(
        'Unable to load products. Please try again.',
        style: TextStyle(color: TenantAdminColors.mutedText),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TenantAdminSearchField(
          hint: 'Search by product name or SKU...',
          value: search,
          onChanged: enabled
              ? (value) {
                  ref.read(stockInProductSearchProvider.notifier).state = value;
                }
              : (_) {},
        ),
        const SizedBox(height: TenantAdminSpacing.sm),
        if (products.isEmpty)
          Text(
            search.trim().isEmpty
                ? 'No products found. Create a product first.'
                : 'No matching products found.',
            style: const TextStyle(color: TenantAdminColors.mutedText),
          )
        else
          DropdownButtonFormField<String>(
            initialValue: products.any(
              (product) => product.productId == selectedProductId,
            )
                ? selectedProductId
                : null,
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              hintText: 'Select product',
              errorText: errorText,
              suffixIcon: const Icon(Icons.search, size: 18),
            ),
            items: products
                .map(
                  (product) => DropdownMenuItem(
                    value: product.productId,
                    child: Text(
                      product.displayLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                )
                .toList(),
            onChanged: !enabled
                ? null
                : (value) {
                    StockProductOption? product;
                    for (final item in products) {
                      if (item.productId == value) {
                        product = item;
                        break;
                      }
                    }

                    ref.read(stockInSelectedProductIdProvider.notifier).state =
                        value;
                    onSelected(product);
                  },
          ),
        if (selectedProduct != null && enabled) ...[
          const SizedBox(height: 4),
          Text(
            'Selected: ${selectedProduct.displayLabel}',
            style: const TextStyle(
              color: TenantAdminColors.mutedText,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }
}

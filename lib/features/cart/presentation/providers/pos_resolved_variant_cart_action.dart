import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/pos_resolved_sale_item.dart';
import 'pos_new_sale_cart_provider.dart';

final posResolvedVariantCartActionProvider =
    Provider<PosResolvedVariantCartAction>(PosResolvedVariantCartAction.new);

class PosResolvedVariantCartAction {
  PosResolvedVariantCartAction(this.ref);

  final Ref ref;

  PosCartMutationResult add(
    PosResolvedSaleItem item, {
    required int requestedQuantity,
  }) {
    if (item.productId.trim().isEmpty ||
        (item.hasVariants && (item.variantId?.trim().isEmpty ?? true))) {
      return PosCartMutationResult.variantUnavailable;
    }

    final cartKey = item.variantId ?? item.productId;
    final product = PosNewSaleProduct(
      id: cartKey,
      productId: item.productId,
      variantId: item.variantId,
      name: item.name,
      category: item.category,
      price: item.unitPrice,
      sku: item.sku,
      stockLabel: _stockLabel(item.stockStatus),
      stockStatus: item.stockStatus,
      hasVariants: item.hasVariants,
      selectedAttributes: item.selectedAttributes,
      maxQuantity: item.availableQuantity?.floor(),
    );

    return ref.read(posNewSaleCartProvider.notifier).addToCart(
          product,
          quantity: requestedQuantity,
        );
  }

  String _stockLabel(String status) => switch (status) {
        'InStock' => 'In Stock',
        'LowStock' => 'Low Stock',
        'OutOfStock' => 'Out of Stock',
        _ => 'Unavailable',
      };
}

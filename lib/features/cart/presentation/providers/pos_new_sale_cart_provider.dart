import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/pos_cart_discount.dart';
import '../../domain/entities/pos_catalog_models.dart';
import '../../../sale/domain/entities/pos_customer.dart';

final posNewSaleCartProvider =
    NotifierProvider<PosNewSaleCartNotifier, PosNewSaleCartState>(
  PosNewSaleCartNotifier.new,
);

final posNewSaleSearchQueryProvider = StateProvider.autoDispose<String>(
  (ref) => '',
);

class PosNewSaleCartNotifier extends Notifier<PosNewSaleCartState> {
  @override
  PosNewSaleCartState build() => const PosNewSaleCartState();

  PosCartMutationResult addToCart(
    PosNewSaleProduct product, {
    int quantity = 1,
  }) {
    if (quantity <= 0) {
      return PosCartMutationResult.invalidQuantity;
    }
    if (product.price <= 0) {
      return PosCartMutationResult.priceUnavailable;
    }
    if (product.stockStatus == 'OutOfStock' || product.maxQuantity == 0) {
      return PosCartMutationResult.outOfStock;
    }
    if (product.stockStatus != 'InStock' && product.stockStatus != 'LowStock') {
      return PosCartMutationResult.productUnavailable;
    }

    final cartKey = product.cartLineKey;
    final existingItem = state.items[cartKey];
    final nextQuantity = (existingItem?.quantity ?? 0) + quantity;
    final maxQuantity = product.maxQuantity;
    if (maxQuantity != null && nextQuantity > maxQuantity) {
      return PosCartMutationResult.insufficientStock;
    }
    _upsertCartItem(product, nextQuantity);
    return existingItem == null
        ? PosCartMutationResult.added
        : PosCartMutationResult.quantityIncreased;
  }

  void updateCartItem({
    required String cartLineKey,
    required PosNewSaleProduct product,
    required int quantity,
  }) {
    _upsertCartItem(product, quantity, replaceKey: cartLineKey);
  }

  void _upsertCartItem(
    PosNewSaleProduct product,
    int quantity, {
    String? replaceKey,
  }) {
    final cartKey = product.cartLineKey;
    final updatedItems = Map<String, PosNewSaleCartItem>.of(state.items);

    if (replaceKey != null && replaceKey != cartKey) {
      updatedItems.remove(replaceKey);
    }

    final existingCartItem = updatedItems[cartKey];
    updatedItems[cartKey] = PosNewSaleCartItem(
      product: product,
      quantity: quantity,
      discount: existingCartItem?.discount,
    );

    state = state.copyWith(
      items: _withoutItemDiscounts(updatedItems),
      cartDiscountSet: true,
    );
  }

  void decreaseQuantity(String cartLineKey) {
    final existingItem = state.items[cartLineKey];
    if (existingItem == null) {
      return;
    }

    final updatedItems = Map<String, PosNewSaleCartItem>.of(state.items);
    if (existingItem.quantity <= 1) {
      updatedItems.remove(cartLineKey);
    } else {
      updatedItems[cartLineKey] = existingItem.copyWith(
        quantity: existingItem.quantity - 1,
      );
    }

    state = state.copyWith(
      items: _withoutItemDiscounts(updatedItems),
      cartDiscountSet: true,
    );
  }

  void increaseQuantity(String cartLineKey) {
    final existingItem = state.items[cartLineKey];
    if (existingItem == null) {
      return;
    }

    addToCart(existingItem.product);
  }

  void removeItem(String cartLineKey) {
    if (!state.items.containsKey(cartLineKey)) {
      return;
    }

    final updatedItems = Map<String, PosNewSaleCartItem>.of(state.items)
      ..remove(cartLineKey);
    state = state.copyWith(
      items: _withoutItemDiscounts(updatedItems),
      cartDiscountSet: true,
    );
  }

  void clear() {
    if (!state.hasItems && state.selectedCustomer == null) {
      return;
    }

    state = const PosNewSaleCartState();
  }

  void restore(PosNewSaleCartState cart) {
    state = cart;
  }

  void setCustomer(PosCustomer? customer) {
    state = state.copyWith(
      selectedCustomer: customer,
      selectedCustomerSet: true,
    );
  }

  void applyCartDiscount(PosCartDiscount discount) {
    if (!state.hasItems) {
      return;
    }

    state = state.copyWith(
      cartDiscount: discount,
      cartDiscountSet: true,
      items: _withoutItemDiscounts(state.items),
    );
  }

  void applyItemDiscount({
    required String cartLineKey,
    required PosCartDiscount discount,
  }) {
    final item = state.items[cartLineKey];
    if (item == null) {
      return;
    }

    final updatedItems = Map<String, PosNewSaleCartItem>.of(state.items);
    final clearedItems = _withoutItemDiscounts(updatedItems);
    clearedItems[cartLineKey] = item.copyWith(
      discount: discount,
      discountSet: true,
    );
    state = state.copyWith(
      items: clearedItems,
      cartDiscountSet: true,
    );
  }

  Map<String, PosNewSaleCartItem> _withoutItemDiscounts(
    Map<String, PosNewSaleCartItem> items,
  ) =>
      {
        for (final entry in items.entries)
          entry.key: entry.value.copyWith(discountSet: true),
      };

  void clearCartDiscount() {
    state = state.copyWith(cartDiscountSet: true);
  }

  void clearItemDiscount(String cartLineKey) {
    final item = state.items[cartLineKey];
    if (item == null || item.discount == null) {
      return;
    }

    final updatedItems = Map<String, PosNewSaleCartItem>.of(state.items);
    updatedItems[cartLineKey] = item.copyWith(discountSet: true);
    state = state.copyWith(items: updatedItems);
  }

  void clearDiscounts() {
    if (!state.hasDiscount) {
      return;
    }

    state = state.copyWith(
      cartDiscountSet: true,
      items: {
        for (final entry in state.items.entries)
          entry.key: entry.value.copyWith(discountSet: true),
      },
    );
  }
}

class PosNewSaleCartState {
  const PosNewSaleCartState({
    this.items = const {},
    this.selectedCustomer,
    this.cartDiscount,
  });

  final Map<String, PosNewSaleCartItem> items;
  final PosCustomer? selectedCustomer;
  final PosCartDiscount? cartDiscount;

  bool get hasItems => items.isNotEmpty;

  bool get hasDiscount => discount > 0;

  String? get discountApplicationId {
    if (cartDiscount?.isBackendApproved == true) {
      return cartDiscount!.applicationId;
    }
    for (final item in items.values) {
      if (item.discount?.isBackendApproved == true) {
        return item.discount!.applicationId;
      }
    }
    return null;
  }

  PosCartDiscount? get pendingDiscount {
    if (cartDiscount?.isPendingApproval == true) return cartDiscount;
    for (final item in items.values) {
      if (item.discount?.isPendingApproval == true) return item.discount;
    }
    return null;
  }

  String? get pendingDiscountCartLineKey {
    for (final entry in items.entries) {
      if (entry.value.discount?.isPendingApproval == true) return entry.key;
    }
    return null;
  }

  List<PosNewSaleCartItem> get itemList => List.unmodifiable(items.values);

  int get subtotal =>
      items.values.fold(0, (total, item) => total + item.lineTotal);

  int get itemDiscountTotal => items.values.fold(
        0,
        (total, item) => total + item.discountAmount,
      );

  int get cartDiscountAmount {
    final discount = cartDiscount;
    if (discount == null || discount.isPendingApproval) {
      return 0;
    }

    if (subtotal <= 0) {
      return 0;
    }

    return discount.amountFor(subtotal);
  }

  int get discount {
    final totalDiscount = itemDiscountTotal + cartDiscountAmount;
    return totalDiscount.clamp(0, subtotal).toInt();
  }

  int get tax => 0;

  int get total {
    final nextTotal = subtotal - discount + tax;
    return nextTotal < 0 ? 0 : nextTotal;
  }

  PosNewSaleCartState copyWith({
    Map<String, PosNewSaleCartItem>? items,
    PosCustomer? selectedCustomer,
    bool selectedCustomerSet = false,
    PosCartDiscount? cartDiscount,
    bool cartDiscountSet = false,
  }) {
    return PosNewSaleCartState(
      items: items ?? this.items,
      selectedCustomer:
          selectedCustomerSet ? selectedCustomer : this.selectedCustomer,
      cartDiscount: cartDiscountSet ? cartDiscount : this.cartDiscount,
    );
  }
}

class PosNewSaleCartItem {
  const PosNewSaleCartItem({
    required this.product,
    this.quantity = 1,
    this.discount,
  });

  final PosNewSaleProduct product;
  final int quantity;
  final PosCartDiscount? discount;

  int get lineTotal => product.price * quantity;

  int get discountAmount => discount?.isPendingApproval == true
      ? 0
      : discount?.amountFor(lineTotal) ?? 0;

  int get discountedLineTotal {
    final nextTotal = lineTotal - discountAmount;
    return nextTotal < 0 ? 0 : nextTotal;
  }

  PosNewSaleCartItem copyWith({
    PosNewSaleProduct? product,
    int? quantity,
    PosCartDiscount? discount,
    bool discountSet = false,
  }) {
    return PosNewSaleCartItem(
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
      discount: discountSet ? discount : this.discount,
    );
  }
}

class PosNewSaleProduct {
  const PosNewSaleProduct({
    required this.id,
    required this.productId,
    required this.name,
    required this.category,
    required this.price,
    this.variantId,
    this.sku,
    this.stockLabel = 'In Stock',
    this.stockStatus = 'InStock',
    this.hasVariants = false,
    this.selectedAttributes = const {},
    this.maxQuantity,
  });

  final String id;
  final String productId;
  final String? variantId;
  final String name;
  final String category;
  final int price;
  final String? sku;
  final String stockLabel;
  final String stockStatus;
  final bool hasVariants;
  final Map<String, String> selectedAttributes;
  final int? maxQuantity;

  String get cartLineKey => variantId ?? id;

  String get variantSummary => formatVariantSummary(selectedAttributes);

  bool matches(String query) {
    return id.toLowerCase().contains(query) ||
        productId.toLowerCase().contains(query) ||
        name.toLowerCase().contains(query) ||
        category.toLowerCase().contains(query) ||
        (sku?.toLowerCase().contains(query) ?? false);
  }
}

enum PosCartMutationResult {
  added,
  quantityIncreased,
  invalidQuantity,
  outOfStock,
  insufficientStock,
  productUnavailable,
  variantUnavailable,
  priceUnavailable,
}

String formatLkr(int value) {
  return 'LKR ${_formatNumber(value)}.00';
}

String formatLkrInputPrefix() => 'LKR';

String _formatNumber(int value) {
  final raw = value.toString();
  final buffer = StringBuffer();

  for (var index = 0; index < raw.length; index += 1) {
    final digitsFromEnd = raw.length - index;
    buffer.write(raw[index]);
    if (digitsFromEnd > 1 && digitsFromEnd % 3 == 1) {
      buffer.write(',');
    }
  }

  return buffer.toString();
}

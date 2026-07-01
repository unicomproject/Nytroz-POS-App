import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/pos_catalog_models.dart';

final posNewSaleCartProvider =
    NotifierProvider<PosNewSaleCartNotifier, PosNewSaleCartState>(
  PosNewSaleCartNotifier.new,
);

final posNewSaleSearchQueryProvider = StateProvider.autoDispose<String>(
  (ref) => '',
);

const posNewSaleCategories = <String>[
  'All',
  'Apparel',
  'Accessories',
  'Tickets',
  'Services',
  'Retail',
  'Food',
  'Drinks',
  'Memberships',
];

final posNewSaleSelectedCategoryProvider = StateProvider.autoDispose<String>(
  (ref) => posNewSaleCategories.first,
);

bool posNewSaleProductMatchesCategory(
  String productCategory,
  String selectedCategory,
) {
  if (selectedCategory == 'All') {
    return true;
  }

  return productCategory.toLowerCase() == selectedCategory.toLowerCase();
}

class PosNewSaleCartNotifier extends Notifier<PosNewSaleCartState> {
  @override
  PosNewSaleCartState build() => const PosNewSaleCartState();

  void addToCart(PosNewSaleProduct product, {int quantity = 1}) {
    final cartKey = product.cartLineKey;
    final existingItem = state.items[cartKey];
    final nextQuantity = (existingItem?.quantity ?? 0) + quantity;
    _upsertCartItem(product, nextQuantity);
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

    updatedItems[cartKey] = PosNewSaleCartItem(
      product: product,
      quantity: quantity,
    );

    state = state.copyWith(items: updatedItems);
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

    state = state.copyWith(items: updatedItems);
  }

  void increaseQuantity(String cartLineKey) {
    final existingItem = state.items[cartLineKey];
    if (existingItem == null) {
      return;
    }

    final maxQty = existingItem.product.maxQuantity;
    if (maxQty != null && existingItem.quantity >= maxQty) {
      return;
    }

    final updatedItems = Map<String, PosNewSaleCartItem>.of(state.items);
    updatedItems[cartLineKey] = existingItem.copyWith(
      quantity: existingItem.quantity + 1,
    );
    state = state.copyWith(items: updatedItems);
  }

  void removeItem(String cartLineKey) {
    if (!state.items.containsKey(cartLineKey)) {
      return;
    }

    final updatedItems = Map<String, PosNewSaleCartItem>.of(state.items)
      ..remove(cartLineKey);
    state = state.copyWith(items: updatedItems);
  }

  void clear() {
    if (!state.hasItems) {
      return;
    }

    state = const PosNewSaleCartState();
  }
}

class PosNewSaleCartState {
  const PosNewSaleCartState({
    this.items = const {},
  });

  final Map<String, PosNewSaleCartItem> items;

  bool get hasItems => items.isNotEmpty;

  List<PosNewSaleCartItem> get itemList => List.unmodifiable(items.values);

  int get subtotal =>
      items.values.fold(0, (total, item) => total + item.lineTotal);

  int get discount => 0;

  int get tax => 0;

  int get total => subtotal - discount + tax;

  PosNewSaleCartState copyWith({
    Map<String, PosNewSaleCartItem>? items,
  }) {
    return PosNewSaleCartState(
      items: items ?? this.items,
    );
  }
}

class PosNewSaleCartItem {
  const PosNewSaleCartItem({
    required this.product,
    this.quantity = 1,
  });

  final PosNewSaleProduct product;
  final int quantity;

  int get lineTotal => product.price * quantity;

  PosNewSaleCartItem copyWith({
    PosNewSaleProduct? product,
    int? quantity,
  }) {
    return PosNewSaleCartItem(
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
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
    this.hasVariants = false,
    this.selectedAttributes = const {},
    this.maxQuantity,
    this.imageUrl,
  });

  final String id;
  final String productId;
  final String? variantId;
  final String name;
  final String category;
  final int price;
  final String? sku;
  final String stockLabel;
  final bool hasVariants;
  final Map<String, String> selectedAttributes;
  final int? maxQuantity;
  final String? imageUrl;

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

String formatLkr(int value) {
  return 'LKR ${_formatNumber(value)}.00';
}

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

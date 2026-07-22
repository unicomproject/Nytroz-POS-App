import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nytroz_pos/features/cart/domain/entities/pos_resolved_sale_item.dart';
import 'package:nytroz_pos/features/cart/presentation/providers/pos_new_sale_cart_provider.dart';
import 'package:nytroz_pos/features/cart/presentation/providers/pos_resolved_variant_cart_action.dart';

void main() {
  late ProviderContainer container;

  setUp(() => container = ProviderContainer());
  tearDown(() => container.dispose());

  PosCartMutationResult add(
    PosResolvedSaleItem item, {
    int quantity = 1,
  }) =>
      container.read(posResolvedVariantCartActionProvider).add(
            item,
            requestedQuantity: quantity,
          );

  test('new exact variant adds one line and bypasses UI selection', () {
    expect(add(_item('V1')), PosCartMutationResult.added);

    final cart = container.read(posNewSaleCartProvider);
    expect(cart.itemList, hasLength(1));
    expect(cart.itemList.single.product.variantId, 'V1');
    expect(cart.itemList.single.quantity, 1);
  });

  test('same variant increments and quantity-per-scan greater than one works',
      () {
    add(_item('V1'));

    expect(
        add(_item('V1'), quantity: 2), PosCartMutationResult.quantityIncreased);
    expect(container.read(posNewSaleCartProvider).itemList.single.quantity, 3);
  });

  test('different variants create separate lines and newest line is last', () {
    add(_item('V1'));
    add(_item('V2'));

    final items = container.read(posNewSaleCartProvider).itemList;
    expect(items.map((item) => item.product.variantId), ['V1', 'V2']);
    expect(items.reversed.first.product.variantId, 'V2');
  });

  test('stock overflow is rejected and exact remaining stock is accepted', () {
    add(_item('V1', available: 5), quantity: 4);

    expect(add(_item('V1', available: 5), quantity: 2),
        PosCartMutationResult.insufficientStock);
    expect(container.read(posNewSaleCartProvider).itemList.single.quantity, 4);

    expect(add(_item('V1', available: 5)),
        PosCartMutationResult.quantityIncreased);
    expect(container.read(posNewSaleCartProvider).itemList.single.quantity, 5);
  });

  test('out of stock and unavailable items are rejected', () {
    expect(
      add(_item('V1', available: 0, stockStatus: 'OutOfStock')),
      PosCartMutationResult.outOfStock,
    );
    expect(
      add(_item('V2', stockStatus: 'Unknown')),
      PosCartMutationResult.productUnavailable,
    );
    expect(container.read(posNewSaleCartProvider).hasItems, isFalse);
  });

  test('zero and negative requested quantities are rejected', () {
    expect(
        add(_item('V1'), quantity: 0), PosCartMutationResult.invalidQuantity);
    expect(
        add(_item('V1'), quantity: -1), PosCartMutationResult.invalidQuantity);
    expect(container.read(posNewSaleCartProvider).hasItems, isFalse);
  });

  test('variant products require an exact variant id', () {
    expect(
      add(_item(null, hasVariants: true)),
      PosCartMutationResult.variantUnavailable,
    );
    expect(container.read(posNewSaleCartProvider).hasItems, isFalse);
  });

  test('quantity mutation recalculates existing subtotal and total', () {
    add(_item('V1', price: 1250), quantity: 2);
    var cart = container.read(posNewSaleCartProvider);
    expect(cart.subtotal, 2500);
    expect(cart.total, 2500);

    add(_item('V1', price: 1250));
    cart = container.read(posNewSaleCartProvider);
    expect(cart.subtotal, 3750);
    expect(cart.tax, 0);
    expect(cart.total, 3750);
  });

  test('cart increment button path uses the same maximum stock rule', () {
    add(_item('V1', available: 1));

    container.read(posNewSaleCartProvider.notifier).increaseQuantity('V1');

    expect(container.read(posNewSaleCartProvider).itemList.single.quantity, 1);
  });
}

PosResolvedSaleItem _item(
  String? variantId, {
  int price = 1000,
  double? available = 10,
  String stockStatus = 'InStock',
  bool hasVariants = true,
}) {
  return PosResolvedSaleItem(
    productId: 'P1',
    variantId: variantId,
    name: 'Team Jersey',
    variantName: variantId,
    category: 'Apparel',
    unitPrice: price,
    sku: variantId == null ? null : 'SKU-$variantId',
    stockStatus: stockStatus,
    availableQuantity: available,
    hasVariants: hasVariants,
  );
}

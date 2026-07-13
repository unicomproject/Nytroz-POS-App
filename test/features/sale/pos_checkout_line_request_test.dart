import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nytroz_pos/features/cart/domain/entities/pos_cart_discount.dart';
import 'package:nytroz_pos/features/cart/domain/entities/pos_catalog_models.dart';
import 'package:nytroz_pos/features/cart/presentation/providers/pos_new_sale_cart_provider.dart';
import 'package:nytroz_pos/features/sale/presentation/providers/pos_checkout_summary_provider.dart';

void main() {
  group('checkoutLinesFromCart', () {
    test('uses summary variantId for simple catalog products', () {
      const summary = PosCatalogProductSummary(
        productId: 'product-id',
        variantId: 'variant-id',
        name: 'General Admission',
        categoryName: 'Tickets',
        basePrice: 19250,
        hasVariants: false,
      );
      final product = toCartProduct(
        summary: summary,
        variant: null,
        quantity: 2,
      );
      final cart = PosNewSaleCartState(
        items: {
          product.cartLineKey: PosNewSaleCartItem(
            product: product,
            quantity: 2,
          ),
        },
      );

      final lines = checkoutLinesFromCart(cart);

      expect(lines, hasLength(1));
      expect(lines.single.variantId, 'variant-id');
      expect(lines.single.toJson(), {'variantId': 'variant-id', 'qty': 2});
    });

    test('preserves an invalid missing variant for backend rejection', () {
      const product = PosNewSaleProduct(
        id: 'product-id',
        productId: 'product-id',
        name: 'General Admission',
        category: 'Tickets',
        price: 19250,
      );
      final cart = PosNewSaleCartState(
        items: {
          product.cartLineKey: const PosNewSaleCartItem(product: product),
        },
      );

      final lines = checkoutLinesFromCart(cart);

      expect(lines, hasLength(1));
      expect(lines.single.variantId, isEmpty);
    });
  });

  group('PosNewSaleCartState discounts', () {
    test('applies manual percentage discount to cart subtotal', () {
      const cart = PosNewSaleCartState(
        items: {
          'product-id': PosNewSaleCartItem(
            product: PosNewSaleProduct(
              id: 'product-id',
              productId: 'product-id',
              name: 'General Admission',
              category: 'Tickets',
              price: 2000,
            ),
            quantity: 2,
          ),
        },
        cartDiscount: PosCartDiscount(
          valueType: PosDiscountValueType.percentage,
          value: 10,
        ),
      );

      expect(cart.subtotal, 4000);
      expect(cart.discount, 400);
      expect(cart.total, 3600);
    });

    test('combines item fixed discount with manual fixed discount', () {
      const cart = PosNewSaleCartState(
        items: {
          'product-id': PosNewSaleCartItem(
            product: PosNewSaleProduct(
              id: 'product-id',
              productId: 'product-id',
              name: 'General Admission',
              category: 'Tickets',
              price: 2000,
            ),
            quantity: 2,
            discount: PosCartDiscount(
              valueType: PosDiscountValueType.fixedAmount,
              value: 500,
            ),
          ),
        },
        cartDiscount: PosCartDiscount(
          valueType: PosDiscountValueType.fixedAmount,
          value: 250,
        ),
      );

      expect(cart.subtotal, 4000);
      expect(cart.itemDiscountTotal, 500);
      expect(cart.cartDiscountAmount, 250);
      expect(cart.discount, 750);
      expect(cart.total, 3250);
    });

    test('clears manual discount when the last cart item is removed', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      const product = PosNewSaleProduct(
        id: 'product-id',
        productId: 'product-id',
        name: 'General Admission',
        category: 'Tickets',
        price: 2000,
      );

      final notifier = container.read(posNewSaleCartProvider.notifier);
      notifier.addToCart(product);
      notifier.applyCartDiscount(
        const PosCartDiscount(
          valueType: PosDiscountValueType.fixedAmount,
          value: 500,
        ),
      );
      notifier.removeItem(product.cartLineKey);

      final cart = container.read(posNewSaleCartProvider);
      expect(cart.hasItems, isFalse);
      expect(cart.cartDiscount, isNull);
      expect(cart.discount, 0);
    });
  });
}

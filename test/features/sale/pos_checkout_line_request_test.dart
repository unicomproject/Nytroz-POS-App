import 'package:flutter_test/flutter_test.dart';
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

    test('does not send productId as variantId when variant is missing', () {
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

      expect(lines, isEmpty);
    });
  });
}

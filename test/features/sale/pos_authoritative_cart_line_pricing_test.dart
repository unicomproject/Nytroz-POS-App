import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nytroz_pos/features/cart/presentation/providers/pos_new_sale_cart_provider.dart';
import 'package:nytroz_pos/features/pos/presentation/widgets/new_sale/cart/pos_cart_authoritative_price_display.dart';
import 'package:nytroz_pos/features/sale/domain/entities/pos_checkout_summary.dart';
import 'package:nytroz_pos/features/sale/presentation/providers/pos_checkout_summary_provider.dart';

void main() {
  group('authoritative cart line pricing', () {
    test('maps calculated lines by clientLineId', () {
      const line = PosCalculatedCartLinePayload(
        clientLineId: 'client-line-1',
        variantId: 'variant-1',
        quantity: 1,
        unitPrice: 2800,
        discount: 700,
        tax: 0,
        lineTotal: 2100,
        baseUnitPrice: 2800,
        automaticDiscount: 700,
        effectiveUnitPrice: 2100,
        appliedPromotion: PosAppliedPromotionPayload(
          policyId: 'policy-1',
          policyCode: 'OFF25',
          policyName: '25% Off',
          calculationMethod: 'Percentage',
          discountValue: 25,
        ),
      );
      final pricing = PosCheckoutSummaryViewData(
        itemCount: 1,
        subtotal: 2800,
        discount: 700,
        tax: 0,
        totalPayable: 2100,
        saleType: 'New Sale',
        itemsInCart: 1,
        saleDate: DateTime.utc(2026, 8, 14),
        cashierName: 'Cashier',
        paymentMethods: const [],
        usedFallback: false,
        currency: 'LKR',
        calculatedLines: const [line],
        linesByClientLineId: const {'client-line-1': line},
        pricingInputFingerprint: checkoutPricingInputFingerprint(_cart()),
      );

      final mapped = authoritativeLinePricingFor(item: _cart().itemList.single, pricing: pricing);

      expect(mapped?.effectiveUnitPrice, 2100);
      expect(mapped?.lineTotal, 2100);
    });

    test('same variant on distinct client lines does not cross-map', () {
      const lineA = PosCalculatedCartLinePayload(
        clientLineId: 'line-a',
        variantId: 'variant-1',
        quantity: 1,
        unitPrice: 2800,
        discount: 700,
        tax: 0,
        lineTotal: 2100,
        effectiveUnitPrice: 2100,
        baseUnitPrice: 2800,
        automaticDiscount: 700,
      );
      const lineB = PosCalculatedCartLinePayload(
        clientLineId: 'line-b',
        variantId: 'variant-1',
        quantity: 1,
        unitPrice: 2800,
        discount: 0,
        tax: 0,
        lineTotal: 2800,
        effectiveUnitPrice: 2800,
        baseUnitPrice: 2800,
      );
      final pricing = PosCheckoutSummaryViewData(
        itemCount: 2,
        subtotal: 5600,
        discount: 700,
        tax: 0,
        totalPayable: 4900,
        saleType: 'New Sale',
        itemsInCart: 2,
        saleDate: DateTime.utc(2026, 8, 14),
        cashierName: 'Cashier',
        paymentMethods: const [],
        usedFallback: false,
        currency: 'LKR',
        calculatedLines: const [lineA, lineB],
        linesByClientLineId: const {'line-a': lineA, 'line-b': lineB},
        pricingInputFingerprint: checkoutPricingInputFingerprint(_twoLineCart()),
      );

      final items = _twoLineCart().itemList;
      expect(
        authoritativeLinePricingFor(item: items.first, pricing: pricing)?.lineTotal,
        2100,
      );
      expect(
        authoritativeLinePricingFor(item: items.last, pricing: pricing)?.lineTotal,
        2800,
      );
    });

    test('stale pricing fingerprint rejects line mapping', () {
      final cart = _cart(quantity: 2);
      final stalePricing = PosCheckoutSummaryViewData(
        itemCount: 1,
        subtotal: 2800,
        discount: 700,
        tax: 0,
        totalPayable: 2100,
        saleType: 'New Sale',
        itemsInCart: 1,
        saleDate: DateTime.utc(2026, 8, 14),
        cashierName: 'Cashier',
        paymentMethods: const [],
        usedFallback: false,
        currency: 'LKR',
        calculatedLines: const [
          PosCalculatedCartLinePayload(
            clientLineId: 'client-line-1',
            variantId: 'variant-1',
            quantity: 1,
            unitPrice: 2800,
            discount: 700,
            tax: 0,
            lineTotal: 2100,
            effectiveUnitPrice: 2100,
            baseUnitPrice: 2800,
            automaticDiscount: 700,
          ),
        ],
        linesByClientLineId: const {
          'client-line-1': PosCalculatedCartLinePayload(
            clientLineId: 'client-line-1',
            variantId: 'variant-1',
            quantity: 1,
            unitPrice: 2800,
            discount: 700,
            tax: 0,
            lineTotal: 2100,
            effectiveUnitPrice: 2100,
            baseUnitPrice: 2800,
            automaticDiscount: 700,
          ),
        },
        pricingInputFingerprint: checkoutPricingInputFingerprint(_cart()),
      );

      expect(
        isCurrentAuthoritativePricing(cart: cart, pricing: stalePricing),
        isFalse,
      );
    });

    testWidgets('promoted line shows struck-through original and effective price',
        (tester) async {
      const linePricing = PosCalculatedCartLinePayload(
        clientLineId: 'client-line-1',
        variantId: 'variant-1',
        quantity: 1,
        unitPrice: 2800,
        discount: 700,
        tax: 0,
        lineTotal: 2100,
        baseUnitPrice: 2800,
        automaticDiscount: 700,
        effectiveUnitPrice: 2100,
        appliedPromotion: PosAppliedPromotionPayload(
          policyId: 'policy-1',
          policyCode: 'OFF25',
          policyName: '25% Off',
          calculationMethod: 'Percentage',
          discountValue: 25,
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Row(
              children: const [
                Expanded(
                  child: PosCartAuthoritativeUnitPriceDisplay(
                    catalogUnitPrice: 2800,
                    currency: 'LKR',
                    isAuthoritative: true,
                    linePricing: linePricing,
                  ),
                ),
                Expanded(
                  child: PosCartAuthoritativeLineTotalDisplay(
                    catalogLineTotal: 2800,
                    currency: 'LKR',
                    isAuthoritative: true,
                    linePricing: linePricing,
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('LKR 2,800.00'), findsOneWidget);
      expect(find.text('LKR 2,100.00'), findsNWidgets(2));
      expect(find.text('25% OFF'), findsOneWidget);
    });

    testWidgets('non-authoritative line total is not shown as final', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PosCartAuthoritativeLineTotalDisplay(
              catalogLineTotal: 2800,
              currency: 'LKR',
              isAuthoritative: false,
            ),
          ),
        ),
      );

      expect(find.text('—'), findsOneWidget);
      expect(find.text('LKR 2,800.00'), findsNothing);
    });

    test('direct add assigns stable clientLineId', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      const product = PosNewSaleProduct(
        id: 'variant-1',
        productId: 'product-1',
        variantId: 'variant-1',
        name: 'Match Shorts',
        category: 'Apparel',
        price: 2800,
        stockStatus: 'InStock',
      );

      container.read(posNewSaleCartProvider.notifier).addToCart(product);
      final lineId =
          container.read(posNewSaleCartProvider).itemList.single.product.clientLineId;

      expect(lineId, isNotNull);
      expect(lineId, isNotEmpty);
      expect(
        RegExp(
          r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
        ).hasMatch(lineId!),
        isTrue,
      );
    });
  });
}

PosNewSaleCartState _cart({int quantity = 1}) {
  const product = PosNewSaleProduct(
    id: 'line-1',
    productId: 'product-1',
    variantId: 'variant-1',
    name: 'Match Shorts',
    category: 'Apparel',
    price: 2800,
    clientLineId: 'client-line-1',
    stockStatus: 'InStock',
  );
  return PosNewSaleCartState(
    items: {
      product.cartLineKey: PosNewSaleCartItem(product: product, quantity: quantity),
    },
  );
}

PosNewSaleCartState _twoLineCart() {
  const productA = PosNewSaleProduct(
    id: 'line-a',
    productId: 'product-1',
    variantId: 'variant-1',
    name: 'Match Shorts A',
    category: 'Apparel',
    price: 2800,
    clientLineId: 'line-a',
    lineNote: 'note-a',
    stockStatus: 'InStock',
  );
  const productB = PosNewSaleProduct(
    id: 'line-b',
    productId: 'product-1',
    variantId: 'variant-1',
    name: 'Match Shorts B',
    category: 'Apparel',
    price: 2800,
    clientLineId: 'line-b',
    lineNote: 'note-b',
    stockStatus: 'InStock',
  );
  return PosNewSaleCartState(
    items: {
      productA.cartLineKey: PosNewSaleCartItem(product: productA, quantity: 1),
      productB.cartLineKey: PosNewSaleCartItem(product: productB, quantity: 1),
    },
  );
}

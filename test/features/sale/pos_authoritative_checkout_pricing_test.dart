import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nytroz_pos/features/cart/presentation/providers/pos_new_sale_cart_provider.dart';
import 'package:nytroz_pos/features/pos/presentation/widgets/new_sale/summary/pos_payment_bar.dart';
import 'package:nytroz_pos/features/sale/presentation/providers/pos_checkout_summary_provider.dart';

void main() {
  group('authoritative checkout pricing identity', () {
    test('accepts backend total for the current cart, not local cart total',
        () {
      final cart = _cart(quantity: 1);
      final pricing = _pricing(cart: cart, total: 2400);

      expect(cart.total, 3200);
      expect(pricing.totalPayable, 2400);
      expect(
        isCurrentAuthoritativePricing(cart: cart, pricing: pricing),
        isTrue,
      );
    });

    test('cart change makes a previous successful result stale', () {
      final oldCart = _cart(quantity: 1);
      final oldPricing = _pricing(cart: oldCart, total: 2400);
      final currentCart = _cart(quantity: 2);

      expect(
        isCurrentAuthoritativePricing(
          cart: currentCart,
          pricing: oldPricing,
        ),
        isFalse,
      );
    });

    test('newer response cannot be replaced by an older cart response', () {
      final requestA = _cart(quantity: 1);
      final requestB = _cart(quantity: 2);
      final responseB = _pricing(cart: requestB, total: 4800);
      final lateResponseA = _pricing(cart: requestA, total: 2400);

      expect(
        isCurrentAuthoritativePricing(cart: requestB, pricing: responseB),
        isTrue,
      );
      expect(
        isCurrentAuthoritativePricing(cart: requestB, pricing: lateResponseA),
        isFalse,
      );
    });

    test('new sale reset rejects pricing from the completed sale', () {
      final previousCart = _cart(quantity: 1);
      final previousPricing = _pricing(cart: previousCart, total: 2400);

      expect(
        isCurrentAuthoritativePricing(
          cart: const PosNewSaleCartState(),
          pricing: previousPricing,
        ),
        isFalse,
      );
    });

    test('loading and failure contain no local authoritative payable value',
        () {
      const loading = AsyncValue<PosCheckoutSummaryViewData>.loading();
      final failure = AsyncValue<PosCheckoutSummaryViewData>.error(
        StateError('pricing failed'),
        StackTrace.empty,
      );

      expect(loading.valueOrNull, isNull);
      expect(failure.valueOrNull, isNull);
      expect(
        resolvePaymentBarPricingState(
          cart: _cart(quantity: 1),
          pricingAsync: loading,
        ).label,
        'Calculating…',
      );
      final failedState = resolvePaymentBarPricingState(
        cart: _cart(quantity: 1),
        pricingAsync: failure,
      );
      expect(failedState.label, 'Total unavailable');
      expect(failedState.canUseForPayment, isFalse);
    });

    test('payment bar displays and authorizes the backend offer total', () {
      final cart = _cart(quantity: 1);
      final state = resolvePaymentBarPricingState(
        cart: cart,
        pricingAsync: AsyncValue.data(_pricing(cart: cart, total: 2400)),
      );

      expect(state.label, 'LKR 2,400.00');
      expect(state.authoritativeTotal, 2400);
      expect(state.canUseForPayment, isTrue);
    });

    test('empty cart shows zero and remains payment-ineligible', () {
      final state = resolvePaymentBarPricingState(
        cart: const PosNewSaleCartState(),
        pricingAsync: const AsyncValue.loading(),
      );

      expect(state.label, 'LKR 0.00');
      expect(state.canUseForPayment, isFalse);
    });

    test('retry success replaces error with authoritative total', () {
      final cart = _cart(quantity: 1);
      final failed = resolvePaymentBarPricingState(
        cart: cart,
        pricingAsync: AsyncValue.error(
          StateError('network'),
          StackTrace.empty,
        ),
      );
      final succeeded = resolvePaymentBarPricingState(
        cart: cart,
        pricingAsync: AsyncValue.data(_pricing(cart: cart, total: 2400)),
      );

      expect(failed.canUseForPayment, isFalse);
      expect(succeeded.label, 'LKR 2,400.00');
      expect(succeeded.canUseForPayment, isTrue);
    });

    test('refresh blocks a retained successful value until recalculation ends',
        () {
      final cart = _cart(quantity: 1);
      final previous = AsyncValue.data(_pricing(cart: cart, total: 2400));
      final refreshing = const AsyncLoading<PosCheckoutSummaryViewData>()
          .copyWithPrevious(previous);

      final state = resolvePaymentBarPricingState(
        cart: cart,
        pricingAsync: refreshing,
      );

      expect(state.label, 'Calculating…');
      expect(state.canUseForPayment, isFalse);
      expect(state.authoritativeTotal, isNull);
    });

    test('failed refresh blocks a retained successful value until retry passes',
        () {
      final cart = _cart(quantity: 1);
      final previous = AsyncValue.data(_pricing(cart: cart, total: 2400));
      final failedRefresh = AsyncError<PosCheckoutSummaryViewData>(
        StateError('network'),
        StackTrace.empty,
      ).copyWithPrevious(previous);

      final state = resolvePaymentBarPricingState(
        cart: cart,
        pricingAsync: failedRefresh,
      );

      expect(state.label, 'Total unavailable');
      expect(state.canUseForPayment, isFalse);
      expect(state.authoritativeTotal, isNull);
    });
  });
}

PosNewSaleCartState _cart({required int quantity}) {
  const product = PosNewSaleProduct(
    id: 'line-1',
    productId: 'product-1',
    variantId: 'variant-1',
    name: 'Training Jersey',
    category: 'Apparel',
    price: 3200,
    clientLineId: 'client-line-1',
    stockStatus: 'InStock',
  );
  return PosNewSaleCartState(
    items: {
      product.cartLineKey:
          PosNewSaleCartItem(product: product, quantity: quantity),
    },
  );
}

PosCheckoutSummaryViewData _pricing({
  required PosNewSaleCartState cart,
  required int total,
}) {
  return PosCheckoutSummaryViewData(
    itemCount: cart.itemList.fold(0, (sum, item) => sum + item.quantity),
    subtotal: cart.subtotal,
    discount: cart.subtotal - total,
    tax: 0,
    totalPayable: total,
    saleType: 'New Sale',
    itemsInCart: cart.itemList.length,
    saleDate: DateTime.utc(2026, 8, 13),
    cashierName: 'Cashier',
    paymentMethods: const [],
    usedFallback: false,
    pricingInputFingerprint: checkoutPricingInputFingerprint(cart),
  );
}

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nytroz_pos/features/cart/presentation/providers/pos_new_sale_cart_provider.dart';
import 'package:nytroz_pos/features/sale/presentation/providers/pos_checkout_summary_provider.dart';
import 'package:nytroz_pos/features/sale/presentation/providers/pos_cash_payment_intent_provider.dart';

void main() {
  test('Click & Collect collection paths bypass Cash Payment safety redirect',
      () {
    for (final path in [
      '/pos/online-orders/collection',
      '/pos/online-orders/collection/handover',
    ]) {
      for (final phase in [
        CashPaymentIntentPhase.inFlight,
        CashPaymentIntentPhase.unknown,
        CashPaymentIntentPhase.succeeded,
        null,
      ]) {
        for (final cartCompleted in [false, true]) {
          expect(
            cashPaymentSafetyRedirect(path, phase,
                cartCompleted: cartCompleted),
            isNull,
            reason: '$path, phase=$phase, cartCompleted=$cartCompleted',
          );
        }
      }
    }
  });

  test('pending and completed routes cannot expose another checkout', () {
    for (final phase in [
      CashPaymentIntentPhase.inFlight,
      CashPaymentIntentPhase.unknown
    ]) {
      expect(cashPaymentSafetyRedirect('/pos/new-sale', phase),
          '/pos/new-sale/payment/cash');
      expect(cashPaymentSafetyRedirect('/pos/new-sale/payment/cash', phase),
          isNull);
    }
    expect(
        cashPaymentSafetyRedirect(
            '/pos/new-sale/payment/cash', CashPaymentIntentPhase.succeeded),
        '/pos/new-sale/payment/cash/success');
    expect(
        cashPaymentSafetyRedirect('/pos/new-sale', null, cartCompleted: true),
        '/pos/new-sale/payment/cash/success');
    expect(
        cashPaymentSafetyRedirect(
            '/pos/new-sale/payment/cash/success/print-receipt',
            CashPaymentIntentPhase.succeeded),
        isNull);
  });

  test(
      'completed cart cannot be serialized or cleared until explicit next sale',
      () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final cart = container.read(posNewSaleCartProvider.notifier);
    cart.completeSale('confirmed-sale');
    cart.clear();
    expect(container.read(posNewSaleCartProvider).completedSaleId,
        'confirmed-sale');
    expect(() => checkoutLinesFromCart(container.read(posNewSaleCartProvider)),
        throwsStateError);
    cart.restore(const PosNewSaleCartState());
    expect(container.read(posNewSaleCartProvider).completedSaleId,
        'confirmed-sale');
    cart.startNextSale();
    container.invalidate(posCashPaymentIntentProvider);
    expect(container.read(posNewSaleCartProvider).completedSaleId, isNull);
    expect(container.read(posNewSaleCartProvider).hasItems, isFalse);
    expect(
        container
            .read(posCashPaymentIntentProvider.notifier)
            .open('new-sale')
            .phase,
        CashPaymentIntentPhase.draft);
  });
  late int sequence;
  late CashPaymentIntentNotifier notifier;

  setUp(() {
    sequence = 0;
    notifier =
        CashPaymentIntentNotifier(keyFactory: () => 'private-${++sequence}');
  });

  test('same draft intent survives rebuild and pre-submit tender edit', () {
    final first = notifier.open('cart-a');
    final rebuilt = notifier.open('cart-a');
    final submitted = notifier.beginSubmission(
      saleIdentity: 'cart-a',
      requestFingerprint: 'cart-a|cash=3500',
    );
    expect(rebuilt.key, first.key);
    expect(submitted.key, first.key);
  });

  test('known rejection requires explicit new attempt and fresh key', () {
    final first = notifier.open('cart-a');
    notifier.beginSubmission(
      saleIdentity: 'cart-a',
      requestFingerprint: 'request-a',
    );
    notifier.markKnownRejected();
    expect(
      () => notifier.beginSubmission(
        saleIdentity: 'cart-a',
        requestFingerprint: 'request-a',
      ),
      throwsStateError,
    );
    final next = notifier.startNew('cart-a');
    expect(next.key, isNot(first.key));
  });

  test('unknown outcome retains key and prevents blind new-key retry', () {
    final first = notifier.open('cart-a');
    notifier.beginSubmission(
      saleIdentity: 'cart-a',
      requestFingerprint: 'request-a',
    );
    notifier.markUnknown();
    expect(() => notifier.startNew('cart-a'), throwsStateError);
    expect(notifier.open('cart-a').key, first.key);
  });

  test('materially changed cart gets fresh key only when resolved', () {
    final first = notifier.open('cart-a');
    final next = notifier.open('cart-b');
    expect(next.key, isNot(first.key));
  });

  test('completed sale retains key and blocks all new submissions', () {
    final first = notifier.open('cart-a');
    notifier.beginSubmission(
      saleIdentity: 'cart-a',
      requestFingerprint: 'request-a',
    );
    notifier.markSucceeded();
    final next = notifier.open('cart-a');
    expect(next.key, first.key);
    expect(notifier.open('changed-cart').key, first.key);
    expect(() => notifier.startNew('cart-a'), throwsStateError);
    expect(
        () => notifier.beginSubmission(
            saleIdentity: 'cart-a', requestFingerprint: 'request-a'),
        throwsStateError);
  });
}

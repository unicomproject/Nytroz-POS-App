import 'package:flutter_test/flutter_test.dart';
import 'package:nytroz_pos/features/sale/presentation/providers/pos_cash_payment_intent_provider.dart';

void main() {
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

  test('completed sale opens a fresh payment intent', () {
    final first = notifier.open('cart-a');
    notifier.beginSubmission(
      saleIdentity: 'cart-a',
      requestFingerprint: 'request-a',
    );
    notifier.markSucceeded();
    final next = notifier.open('cart-a');
    expect(next.key, isNot(first.key));
  });
}

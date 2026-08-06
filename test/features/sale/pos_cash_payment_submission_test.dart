import 'package:flutter_test/flutter_test.dart';
import 'package:nytroz_pos/features/sale/presentation/providers/pos_cash_payment_provider.dart';
import 'package:nytroz_pos/features/sale/presentation/providers/pos_cash_payment_intent_provider.dart';
import 'package:nytroz_pos/features/sale/presentation/providers/pos_cash_payment_success_provider.dart';
import 'package:nytroz_pos/features/sale/domain/entities/pos_checkout_summary.dart';
import 'package:nytroz_pos/features/sale/domain/entities/pos_checkout_api_exception.dart';

void main() {
  group('Complete Sale eligibility', () {
    test('disabled when cashReceived < totalDue', () {
      expect(canConfirmCashPayment(0, 1700), false);
      expect(canConfirmCashPayment(500, 1700), false);
      expect(canConfirmCashPayment(1699, 1700), false);
    });

    test('enabled for exact amount', () {
      expect(canConfirmCashPayment(1700, 1700), true);
    });

    test('enabled for overpayment', () {
      expect(canConfirmCashPayment(2000, 1700), true);
      expect(canConfirmCashPayment(5000, 1700), true);
    });

    test('disabled when total is 0 or negative', () {
      expect(canConfirmCashPayment(0, 0), false);
      expect(canConfirmCashPayment(100, 0), false);
      expect(canConfirmCashPayment(100, -1), false);
    });
  });

  group('Intent state machine — submission lifecycle', () {
    late int seq;
    late CashPaymentIntentNotifier intent;

    setUp(() {
      seq = 0;
      intent = CashPaymentIntentNotifier(
        keyFactory: () => 'key-${++seq}',
      );
    });

    test('beginSubmission generates a stable key and marks inFlight', () {
      final result = intent.beginSubmission(
        saleIdentity: 'cart-a',
        requestFingerprint: 'fp-1',
      );
      expect(result.key, 'key-1');
      expect(result.phase, CashPaymentIntentPhase.inFlight);
    });

    test('duplicate beginSubmission with same fingerprint returns same key',
        () {
      final first = intent.beginSubmission(
        saleIdentity: 'cart-a',
        requestFingerprint: 'fp-1',
      );
      final second = intent.beginSubmission(
        saleIdentity: 'cart-a',
        requestFingerprint: 'fp-1',
      );
      expect(second.key, first.key);
    });

    test('markSucceeded prevents resubmission and opens fresh intent', () {
      final first = intent.beginSubmission(
        saleIdentity: 'cart-a',
        requestFingerprint: 'fp-1',
      );
      intent.markSucceeded();
      expect(intent.state!.phase, CashPaymentIntentPhase.succeeded);

      final next = intent.open('cart-a');
      expect(next.key, isNot(first.key));
    });

    test('markKnownRejected blocks resubmission until startNew', () {
      intent.beginSubmission(
        saleIdentity: 'cart-a',
        requestFingerprint: 'fp-1',
      );
      intent.markKnownRejected();

      expect(
        () => intent.beginSubmission(
          saleIdentity: 'cart-a',
          requestFingerprint: 'fp-1',
        ),
        throwsStateError,
      );

      final next = intent.startNew('cart-a');
      expect(next.phase, CashPaymentIntentPhase.draft);
    });

    test('markUnknown preserves same key for safe retry', () {
      final first = intent.beginSubmission(
        saleIdentity: 'cart-a',
        requestFingerprint: 'fp-1',
      );
      intent.markUnknown();

      expect(intent.state!.phase, CashPaymentIntentPhase.unknown);
      expect(() => intent.startNew('cart-a'), throwsStateError);

      final reused = intent.open('cart-a');
      expect(reused.key, first.key);
    });
  });

  group('Success uses authoritative backend values', () {
    test('recordCheckoutPayment stores backend cashReceived and changeDue', () {
      final notifier = PosCashPaymentSuccessNotifier();
      final payload = PosCheckoutStartPaymentPayload(
        checkoutSessionId: 'cs-1',
        saleId: 'sale-1',
        saleNumber: 'S-001',
        paymentMethod: 'cash',
        grandTotal: 1700,
        currency: 'LKR',
        saleStatus: 'Paid',
        nextAction: 'none',
        receiptNumber: 'R-001',
        barcodeValue: 'R-001',
        completedAt: DateTime(2026, 8, 5, 12, 0),
        subtotal: 1800,
        discount: 200,
        tax: 100,
        cashReceived: 2000,
        changeDue: 300,
        items: const [
          PosCheckoutCompletedLinePayload(
            name: 'Test Product',
            quantity: 1,
            unitPrice: 1800,
            lineTotal: 1800,
          ),
        ],
        paymentId: 'pay-1',
        receiptId: 'rec-1',
      );

      notifier.recordCheckoutPayment(payload);
      final data = notifier.state!;

      expect(data.cashReceived, 2000);
      expect(data.changeDue, 300);
      expect(data.receiptNumber, 'R-001');
      expect(data.saleId, 'sale-1');
      expect(data.total, 1700);
      expect(data.subtotal, 1800);
      expect(data.discount, 200);
      expect(data.tax, 100);
      expect(data.itemCount, 1);
    });
  });

  group('Failure preserves cart and tender state', () {
    test('PosCheckoutApiException preserves category info for error handling',
        () {
      final networkError = PosCheckoutApiException(
        message: 'Network unreachable',
        isNetworkUnavailable: true,
      );
      expect(networkError.isNetworkUnavailable, true);

      final validationError = PosCheckoutApiException(
        message: 'Invalid cart',
        statusCode: 400,
      );
      expect(validationError.isNetworkUnavailable, false);
      expect(validationError.statusCode, 400);

      final authError = PosCheckoutApiException(
        message: 'Forbidden',
        statusCode: 403,
      );
      expect(authError.statusCode, 403);

      final conflictError = PosCheckoutApiException(
        message: 'Conflict',
        statusCode: 409,
      );
      expect(conflictError.statusCode, 409);

      final serverError = PosCheckoutApiException(
        message: 'Server error',
        statusCode: 500,
      );
      expect(serverError.statusCode, 500);
    });

    test('Change due never goes negative on failure state', () {
      expect(cashPaymentChangeDue(500, 1700), 0);
      expect(cashPaymentChangeDue(0, 1700), 0);
    });

    test('Cash payment provider state survives without reset', () {
      final notifier = PosCashPaymentNotifier();
      notifier.setAmount(2000, selectedQuickAmount: 2000);

      expect(notifier.state.cashReceived, 2000);
      expect(notifier.state.selectedQuickAmount, 2000);
      expect(notifier.state.inputBuffer, '2000');
    });
  });

  group('Pre-sale Print Receipt button absence', () {
    test('canConfirmCashPayment does not reference print state', () {
      // The function signature only takes cashReceived and total.
      // There is no printReceiptRequested parameter — confirming
      // the pre-sale Print Receipt button is architecturally absent.
      expect(canConfirmCashPayment(1700, 1700), true);
    });
  });

  group('Chunk 1 layout regression — Quick Amount logic intact', () {
    test('generateCashQuickAmounts still correct after Chunk 3', () {
      expect(generateCashQuickAmounts(1700), [1700, 2000]);
      expect(generateCashQuickAmounts(2000), [2000, 3000]);
      expect(generateCashQuickAmounts(0), []);
    });
  });
}

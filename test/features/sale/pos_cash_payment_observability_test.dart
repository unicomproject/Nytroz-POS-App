import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nytroz_pos/features/sale/domain/entities/pos_cash_payment_observability.dart';
import 'package:nytroz_pos/features/sale/presentation/widgets/cash_payment/tender/cash_payment_amount_received_section.dart';

void main() {
  tearDown(CashPaymentTrace.resetSink);

  test('correlation is deterministic and does not expose idempotency key', () {
    const key = 'pos-private-idempotency-key';

    final first = cashPaymentCorrelation(key);
    final second = cashPaymentCorrelation(key);

    expect(first, second);
    expect(first, hasLength(12));
    expect(first, matches(RegExp(r'^[0-9a-f]{12}$')));
    expect(first, isNot(contains(key)));
  });

  test('trace emits structured safe fields without the raw key', () {
    const key = 'pos-private-idempotency-key';
    String? captured;
    CashPaymentTrace.sink = (message, {required event}) {
      captured = message;
    };

    CashPaymentTrace.emit('payment_test', {
      'correlation': cashPaymentCorrelation(key),
      'httpStatus': 503,
    });

    final decoded = jsonDecode(captured!) as Map<String, dynamic>;
    expect(decoded['event'], 'payment_test');
    expect(decoded['correlation'], cashPaymentCorrelation(key));
    expect(captured, isNot(contains(key)));
  });

  testWidgets('unknown outcome remains visible with safe retry guidance',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CashPaymentAmountReceivedSection(
            cashReceived: 3000,
            inputBuffer: '3000',
            totalDue: 2800,
            failure: const CashPaymentFailure(
              message: 'The payment result is unknown.',
              correlation: 'a1b2c3d4e5f6',
              code: 'network_timeout',
              unknownOutcome: true,
            ),
          ),
        ),
      ),
    );

    expect(find.byKey(const ValueKey('cash-payment-persistent-error')),
        findsOneWidget);
    expect(find.text('Payment result could not be confirmed.'), findsOneWidget);
    expect(find.text('Reference: A1B2C3D4E5F6'), findsOneWidget);
    expect(
      find.text('Do not retry until the transaction status has been checked.'),
      findsOneWidget,
    );
  });

  for (final size in <Size>[
    const Size(1280, 800),
    const Size(1200, 760),
    const Size(900, 700),
    const Size(600, 600),
  ]) {
    testWidgets('persistent error scrolls without overflow at $size',
        (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(
              size: size,
              textScaler: const TextScaler.linear(1.3),
              viewInsets: const EdgeInsets.only(bottom: 280),
            ),
            child: Scaffold(
              body: SingleChildScrollView(
                child: SizedBox(
                  height: 700,
                  child: CashPaymentAmountReceivedSection(
                    cashReceived: 3500,
                    inputBuffer: '3500',
                    totalDue: 2800,
                    failure: const CashPaymentFailure(
                      message:
                          'The request could not be completed. Contact support before retrying this payment.',
                      correlation: 'd43121d40bb3',
                      code: 'pos_checkout.idempotency_conflict',
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('Reference: D43121D40BB3'), findsOneWidget);
    });
  }
}

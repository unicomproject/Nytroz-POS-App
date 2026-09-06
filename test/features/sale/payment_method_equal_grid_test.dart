import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nytroz_pos/features/sale/domain/entities/pos_payment_method_type.dart';
import 'package:nytroz_pos/features/sale/presentation/widgets/payment/payment_method_capability.dart';
import 'package:nytroz_pos/features/sale/presentation/widgets/payment/payment_method_equal_grid.dart';
import 'package:nytroz_pos/features/sale/presentation/widgets/payment/payment_method_card.dart';

void main() {
  group('PaymentMethodEqualGrid', () {
    for (final width in <double>[1200, 900, 600]) {
      for (var count = 1; count <= 4; count++) {
        testWidgets('$count cards follow equal layout at width $width',
            (tester) async {
          await tester.pumpWidget(
            MaterialApp(
              home: Center(
                child: SizedBox(
                  width: width,
                  child: PaymentMethodEqualGrid(
                    children: List.generate(
                      count,
                      (index) => ColoredBox(
                        key: ValueKey('card-$index'),
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );

          final rects = List.generate(
            count,
            (index) => tester.getRect(find.byKey(ValueKey('card-$index'))),
          );
          for (final rect in rects.skip(1)) {
            expect(rect.width, closeTo(rects.first.width, 0.01));
            expect(rect.height, closeTo(rects.first.height, 0.01));
          }

          if (count <= 2) {
            expect(rects.map((rect) => rect.top).toSet(), hasLength(1));
          } else {
            expect(rects.map((rect) => rect.top).toSet(), hasLength(2));
            if (count == 3) {
              expect(
                rects[2].center.dx,
                closeTo(
                  tester.getCenter(find.byType(PaymentMethodEqualGrid)).dx,
                  0.01,
                ),
              );
            } else {
              expect(rects[2].left, closeTo(rects[0].left, 0.01));
            }
          }
        });
      }
    }
  });

  group('payment capability policy', () {
    test('only authoritative backend-allowed cash is executable', () {
      for (final method in PosPaymentMethodType.values) {
        final capability = paymentMethodCapability(
          method,
          backendAllowed: true,
          authoritativeSummary: true,
        );
        expect(capability.executable, method == PosPaymentMethodType.cash);
      }
    });

    test('fallback and backend-absent cash fail closed', () {
      expect(
        paymentMethodCapability(
          PosPaymentMethodType.cash,
          backendAllowed: true,
          authoritativeSummary: false,
        ).executable,
        isFalse,
      );
      expect(
        paymentMethodCapability(
          PosPaymentMethodType.cash,
          backendAllowed: false,
          authoritativeSummary: true,
        ).executable,
        isFalse,
      );
    });
  });

  group('PaymentMethodCard interaction', () {
    testWidgets('card content fits the minimum responsive grid height',
        (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Center(
          child: SizedBox(
            width: 300,
            height: 116,
            child: PaymentMethodCard(
              method: PosPaymentMethodType.cash,
              onTap: _noop,
            ),
          ),
        ),
      ));

      expect(tester.takeException(), isNull);
    });

    testWidgets('executable Cash invokes only its supplied action',
        (tester) async {
      var taps = 0;
      await tester.pumpWidget(MaterialApp(
        home: SizedBox(
          width: 300,
          height: 200,
          child: PaymentMethodCard(
            method: PosPaymentMethodType.cash,
            selected: true,
            onTap: () => taps++,
          ),
        ),
      ));
      await tester.tap(find.byType(PaymentMethodCard));
      expect(taps, 1);
    });

    for (final method in <PosPaymentMethodType>[
      PosPaymentMethodType.card,
      PosPaymentMethodType.qrMobile,
      PosPaymentMethodType.split,
    ]) {
      testWidgets('${method.name} unavailable cannot invoke navigation action',
          (tester) async {
        var taps = 0;
        await tester.pumpWidget(MaterialApp(
          home: SizedBox(
            width: 300,
            height: 200,
            child: PaymentMethodCard(
              method: method,
              enabled: false,
              unavailableReason: 'Unavailable',
              onTap: () => taps++,
            ),
          ),
        ));
        await tester.tap(find.byType(PaymentMethodCard));
        expect(taps, 0);
      });
    }
  });
}

void _noop() {}

import 'package:flutter_test/flutter_test.dart';
import 'package:nytroz_pos/features/sale/presentation/providers/pos_cash_payment_provider.dart';

void main() {
  group('PosCashPaymentNotifier', () {
    test('supports 00, backspace, clear and ok keys', () {
      final notifier = PosCashPaymentNotifier();

      notifier.appendKey('1');
      notifier.appendKey('00');
      expect(notifier.state.inputBuffer, '100');
      expect(notifier.state.cashReceived, 100);

      notifier.appendKey('backspace');
      expect(notifier.state.inputBuffer, '10');
      expect(notifier.state.cashReceived, 10);

      notifier.appendKey('ok');
      expect(notifier.state.inputBuffer, '10');
      expect(notifier.state.cashReceived, 10);

      notifier.appendKey('clear');
      expect(notifier.state.inputBuffer, '');
      expect(notifier.state.cashReceived, 0);
    });
  });

  group('cash payment helpers', () {
    test('change due computes using total and received', () {
      expect(cashPaymentChangeDue(5000, 4200), 800);
      expect(cashPaymentChangeDue(1000, 4200), -3200);
    });

    test('confirm requires cash >= total and total > 0', () {
      expect(canConfirmCashPayment(4200, 4200), isTrue);
      expect(canConfirmCashPayment(5000, 4200), isTrue);
      expect(canConfirmCashPayment(1000, 4200), isFalse);
      expect(canConfirmCashPayment(0, 0), isFalse);
    });
  });
}

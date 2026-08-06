import 'package:flutter_test/flutter_test.dart';
import 'package:nytroz_pos/features/sale/presentation/providers/pos_cash_payment_provider.dart';

void main() {
  group('Cash Payment Logic Tests', () {
    test('generateCashQuickAmounts produces correct options for LKR', () {
      expect(generateCashQuickAmounts(1700), [1700, 2000]);
      expect(generateCashQuickAmounts(2800), [2800, 3000]);
      expect(generateCashQuickAmounts(16280), [16280, 17000]);
      expect(generateCashQuickAmounts(2000), [2000, 3000]);
      expect(generateCashQuickAmounts(1), [1, 1000]);
      expect(generateCashQuickAmounts(999), [999, 1000]);
      expect(generateCashQuickAmounts(1000), [1000, 2000]);
      expect(generateCashQuickAmounts(0), []);
      expect(generateCashQuickAmounts(-500), []);
    });

    test('cashPaymentChangeDue never returns negative change', () {
      expect(cashPaymentChangeDue(0, 1700), 0);
      expect(cashPaymentChangeDue(1000, 1700), 0);
      expect(cashPaymentChangeDue(1700, 1700), 0);
      expect(cashPaymentChangeDue(2000, 1700), 300);
    });
  });

  group('PosCashPaymentNotifier Tests', () {
    test('Initial state is empty', () {
      final notifier = PosCashPaymentNotifier();
      expect(notifier.state.cashReceived, 0);
      expect(notifier.state.inputBuffer, '');
      expect(notifier.state.selectedQuickAmount, isNull);
    });

    test('Digit entry appends correctly and removes selected Quick Amount', () {
      final notifier = PosCashPaymentNotifier();

      notifier.setAmount(1000, selectedQuickAmount: 1000);
      expect(notifier.state.cashReceived, 1000);
      expect(notifier.state.selectedQuickAmount, 1000);

      // Appending digit replaces or adds to buffer, and since it changes, clears selected
      notifier.appendKey('5');
      expect(notifier.state.cashReceived, 10005);
      expect(notifier.state.inputBuffer, '10005');
      expect(notifier.state.selectedQuickAmount, isNull);
    });

    test('00 appends correctly but prevents meaningless leading zeros', () {
      final notifier = PosCashPaymentNotifier();

      notifier.appendKey('00');
      expect(notifier.state.cashReceived, 0);
      expect(notifier.state.inputBuffer, '');

      notifier.appendKey('1');
      notifier.appendKey('00');
      expect(notifier.state.cashReceived, 100);
      expect(notifier.state.inputBuffer, '100');
    });

    test('Leading zeros are handled safely', () {
      final notifier = PosCashPaymentNotifier();

      notifier.appendKey('0');
      notifier.appendKey('0');
      notifier.appendKey('7');

      expect(notifier.state.cashReceived, 7);
      expect(notifier.state.inputBuffer, '7');
    });

    test('Decimal, plus, minus are ignored', () {
      final notifier = PosCashPaymentNotifier();
      notifier.appendKey('1');
      notifier.appendKey('.');
      notifier.appendKey('+');
      notifier.appendKey('-');

      expect(notifier.state.cashReceived, 1);
      expect(notifier.state.inputBuffer, '1');
    });

    test('Backspace removes last digit', () {
      final notifier = PosCashPaymentNotifier();
      notifier.appendKey('1');
      notifier.appendKey('7');
      notifier.appendKey('0');

      notifier.appendKey('backspace');
      expect(notifier.state.cashReceived, 17);
      expect(notifier.state.inputBuffer, '17');
    });

    test('Clear resets amount and selectedQuickAmount', () {
      final notifier = PosCashPaymentNotifier();
      notifier.setAmount(1500, selectedQuickAmount: 1500);

      notifier.appendKey('clear');
      expect(notifier.state.cashReceived, 0);
      expect(notifier.state.inputBuffer, '');
      expect(notifier.state.selectedQuickAmount, isNull);
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:nytroz_pos/features/cash_drawer/presentation/providers/close_till_provider.dart';

void main() {
  group('CloseTillFormController', () {
    test('applyDefaultCountedCash pre-fills expected cash when form is empty',
        () {
      final controller = CloseTillFormController();

      controller.applyDefaultCountedCash(150);

      expect(controller.state.countedCashText, '150.00');
      expect(controller.state.hasValidCountedCash, isTrue);
    });

    test('applyDefaultCountedCash does not override saved draft', () {
      final controller = CloseTillFormController();
      controller.setCountedCashText('200.00');
      controller.saveDraft();

      controller.applyDefaultCountedCash(150);

      expect(controller.state.countedCashText, '200.00');
    });
  });
}

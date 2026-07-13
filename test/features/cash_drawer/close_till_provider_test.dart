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

    test('matching counted and expected cash is balanced without mismatch reason',
        () {
      final controller = CloseTillFormController();
      controller.setCountedCashText('150.00');

      expect(controller.state.differenceFor(150), 0);
      expect(controller.state.summaryClosingStatusLabel(150), 'Balanced');
      expect(
        validateCloseTillMismatchReason(
          controller.state.mismatchReason,
          required: controller.state.differenceFor(150) != 0,
        ),
        isNull,
      );
    });

    test('cash variance requires mismatch reason', () {
      final controller = CloseTillFormController();
      controller.setCountedCashText('140.00');

      expect(controller.state.differenceFor(150), -10);
      expect(
        controller.state.summaryClosingStatusLabel(150),
        'Variance Reason Required',
      );
      expect(
        validateCloseTillMismatchReason(
          controller.state.mismatchReason,
          required: controller.state.differenceFor(150) != 0,
        ),
        'Mismatch reason is required',
      );
    });
  });
}

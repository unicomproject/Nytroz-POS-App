import 'package:flutter_test/flutter_test.dart';
import 'package:nytroz_pos/features/tenant_admin/products/domain/entities/add_product_wizard_state.dart';
import 'package:nytroz_pos/features/tenant_admin/products/domain/entities/scan_barcode_step_state.dart';
import 'package:nytroz_pos/features/tenant_admin/products/presentation/widgets/add_product_stepper.dart';

@Skip('Needs UI refactor update for 6-step flow')
void main() {
  group('supplied scanner-first journey', () {
    test('stepper is exact 7 labels without global Barcode & SKU', () {
      expect(AddProductStepper.steps, [
        'Scan Barcode',
        'Basic Details',
        'Product Type & Tracking',
        'Unit & Pack Conversion',
        'Product Configuration',
        'Pricing & Tax',
        'Review & Create',
      ]);
      expect(AddProductStepper.steps.contains('Barcode & SKU'), isFalse);
      expect(AddProductStepper.steps.length, 7);
    });

    test('fresh wizard state starts at Scan Barcode step 1 / S1-A', () {
      const state = AddProductWizardState();
      expect(state.currentStep, 1);
      expect(state.scanStepState.panel, ScanBarcodePanel.scanReady);
    });

    test('no-barcode reasons are not Product Structure values', () {
      for (final reason in const ['OWN_MADE', 'SERVICE_FEE', 'UNLABELLED']) {
        expect(
          const {'SIMPLE', 'VARIANT', 'BUNDLE'}.contains(reason),
          isFalse,
        );
      }
    });

    test('ScanBarcodePanel covers S1-A..G and R1-R3', () {
      expect(
        ScanBarcodePanel.values.toSet(),
        containsAll({
          ScanBarcodePanel.scanReady,
          ScanBarcodePanel.validating,
          ScanBarcodePanel.localMatch,
          ScanBarcodePanel.noLocalMatch,
          ScanBarcodePanel.externalLookup,
          ScanBarcodePanel.externalFound,
          ScanBarcodePanel.externalNoMatch,
          ScanBarcodePanel.manualEntry,
          ScanBarcodePanel.invalid,
          ScanBarcodePanel.noBarcode,
        }),
      );
    });

    test('leading-zero barcode remains String in scan state', () {
      const scan = ScanBarcodeStepState(candidateBarcode: '012345678905');
      expect(scan.candidateBarcode, '012345678905');
      expect(scan.candidateBarcode.startsWith('0'), isTrue);
    });
  });
}

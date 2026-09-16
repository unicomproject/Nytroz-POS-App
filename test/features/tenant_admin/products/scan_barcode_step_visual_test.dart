import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nytroz_pos/features/tenant_admin/products/domain/entities/add_product_wizard_state.dart';
import 'package:nytroz_pos/features/tenant_admin/products/domain/entities/scan_barcode_step_state.dart';
import 'package:nytroz_pos/features/tenant_admin/products/domain/repositories/tenant_product_repository.dart';
import 'package:nytroz_pos/features/tenant_admin/products/presentation/controllers/add_product_wizard_controller.dart';
import 'package:nytroz_pos/features/tenant_admin/products/presentation/widgets/add_product_stepper.dart';
import 'package:nytroz_pos/features/tenant_admin/products/presentation/widgets/scan_barcode/scan_barcode_step.dart';

class _DummyRepository implements TenantProductRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _TestController extends AddProductWizardController {
  _TestController() : super(_DummyRepository());
}

void main() {
  group('screen-reference Step 1 panels', () {
    Future<void> pumpScan(
      WidgetTester tester, {
      required ScanBarcodeStepState scan,
      Size size = const Size(1024, 768),
    }) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final state = AddProductWizardState(scanStepState: scan);
      final controller = _TestController();

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: size.width,
                height: size.height,
                child: ScanBarcodeStep(
                  state: state,
                  controller: controller,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
    }

    testWidgets('S1-A scan ready layout', (tester) async {
      await pumpScan(tester, scan: const ScanBarcodeStepState());
      expect(find.text('Scan Product Barcode'), findsOneWidget);
      expect(find.text('Waiting for scan'), findsOneWidget);
      expect(find.text('Enter barcode manually'), findsOneWidget);
      expect(find.text('Product has no barcode'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('S1-B validating status rows', (tester) async {
      await pumpScan(
        tester,
        scan: const ScanBarcodeStepState(
          panel: ScanBarcodePanel.validating,
          candidateBarcode: '5012345678900',
          barcodeType: 'EAN-13',
          isBusy: true,
        ),
      );
      expect(find.text('Barcode Detected'), findsOneWidget);
      expect(find.text('Barcode Format'), findsOneWidget);
      expect(find.text('GTIN Check Digit'), findsOneWidget);
      expect(find.text('Checking Your Catalogue'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('S1-D no local match', (tester) async {
      await pumpScan(
        tester,
        scan: const ScanBarcodeStepState(
          panel: ScanBarcodePanel.noLocalMatch,
          candidateBarcode: '5012345678900',
        ),
      );
      expect(find.text('No local match found'), findsOneWidget);
      expect(find.text('Search Product Data'), findsOneWidget);
      expect(find.text('Enter details manually'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('S1-E external loading', (tester) async {
      await pumpScan(
        tester,
        scan: const ScanBarcodeStepState(
          panel: ScanBarcodePanel.externalLookup,
          candidateBarcode: '5012345678900',
          isBusy: true,
        ),
      );
      expect(find.text('Searching Product Data'), findsOneWidget);
      expect(find.textContaining('Searching product data'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('S1-G exactly four options', (tester) async {
      await pumpScan(
        tester,
        scan: const ScanBarcodeStepState(
          panel: ScanBarcodePanel.externalNoMatch,
          candidateBarcode: '5012345678900',
        ),
      );
      expect(find.text('Product data not found'), findsOneWidget);
      expect(
        find.text('Continue with this barcode and create manually'),
        findsOneWidget,
      );
      expect(find.text('Continue'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('S1-R1 manual barcode length selectors', (tester) async {
      await pumpScan(
        tester,
        scan: const ScanBarcodeStepState(
          panel: ScanBarcodePanel.manualEntry,
          candidateBarcode: '123',
        ),
      );
      expect(find.text('Enter Barcode Manually'), findsOneWidget);
      expect(find.text('Validate Barcode'), findsOneWidget);
      expect(find.text('8 digits'), findsOneWidget);
      expect(find.text('12 digits'), findsOneWidget);
      expect(find.text('13 digits'), findsOneWidget);
      expect(find.text('14 digits'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('S1-R2 invalid barcode warning card', (tester) async {
      await pumpScan(
        tester,
        scan: const ScanBarcodeStepState(
          panel: ScanBarcodePanel.invalid,
          candidateBarcode: '12',
          invalidReason: 'Too short',
        ),
      );
      expect(find.text('Invalid Barcode'), findsWidgets);
      expect(find.text('Try Again'), findsOneWidget);
      expect(find.text('Rescan'), findsOneWidget);
      expect(find.text('Create Without Barcode'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('S1-R3 no-barcode reason cards', (tester) async {
      await pumpScan(
        tester,
        scan: const ScanBarcodeStepState(
          panel: ScanBarcodePanel.noBarcode,
        ),
      );
      expect(find.text('Create Product Without Barcode'), findsOneWidget);
      expect(find.text('Own-made Product'), findsOneWidget);
      expect(find.text('Service / Fee'), findsOneWidget);
      expect(find.text('Unlabelled Product'), findsOneWidget);
      expect(find.text('Continue to Basic Details'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('1024x768 Step1 + stepper no overflow', (tester) async {
      tester.view.physicalSize = const Size(1024, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 1024,
                height: 768,
                child: Column(
                  children: [
                    const AddProductStepper(currentStep: 1),
                    Expanded(
                      child: ScanBarcodeStep(
                        state: const AddProductWizardState(),
                        controller: _TestController(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.text('Scan Barcode'), findsWidgets);
      expect(find.text('Scan Product Barcode'), findsOneWidget);
      expect(AddProductStepper.steps.contains('Barcode & SKU'), isFalse);
      expect(tester.takeException(), isNull);
    });
  });
}

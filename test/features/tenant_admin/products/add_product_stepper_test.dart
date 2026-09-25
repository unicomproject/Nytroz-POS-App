// ignore_for_file: invalid_annotation_target
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nytroz_pos/features/tenant_admin/products/presentation/widgets/add_product_stepper.dart';

@Skip('Needs UI refactor update for 6-step flow')
void main() {
  test('scanner-first stepper has exact 6 labels without Barcode & SKU', () {
    expect(AddProductStepper.steps, [
      'Scan Barcode',
      'Basic Details',
      'Product Type & Configuration',
      'Pricing & Tax',
      'Product Tracking',
      'Review & Create',
    ]);
    expect(AddProductStepper.steps.contains('Barcode & SKU'), isFalse);
    expect(AddProductStepper.steps.length, 6);
  });

  Future<void> pumpStepper(
    WidgetTester tester, {
    required Size size,
    int currentStep = 1,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: size.width,
              child: AddProductStepper(currentStep: currentStep),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('fresh wizard step 1 shows Scan Barcode label', (tester) async {
    await pumpStepper(tester, size: const Size(1280, 800), currentStep: 1);
    expect(find.text('Scan Barcode'), findsWidgets);
  });

  testWidgets('desktop shows all 6 scanner-first step labels', (tester) async {
    await pumpStepper(tester, size: const Size(1280, 800));

    for (final label in AddProductStepper.steps) {
      expect(find.text(label), findsOneWidget);
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('tablet 1024x768 shows scanner-first labels without overflow',
      (tester) async {
    await pumpStepper(tester, size: const Size(1024, 768));
    expect(find.text('Scan Barcode'), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}

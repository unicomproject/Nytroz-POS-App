import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nytroz_pos/features/tenant_admin/products/presentation/widgets/add_product_stepper.dart';

void main() {
  Future<void> pumpStepper(
    WidgetTester tester, {
    required Size size,
    int currentStep = 4,
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

  testWidgets('desktop shows all 7 step labels without overflow', (tester) async {
    await pumpStepper(tester, size: const Size(1280, 800));

    for (final label in AddProductStepper.steps) {
      expect(find.text(label), findsOneWidget);
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('tablet layout shows all 7 full step labels',
      (tester) async {
    await pumpStepper(tester, size: const Size(900, 800));

    for (final label in AddProductStepper.steps) {
      expect(find.text(label), findsOneWidget);
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('mobile compact layout shows step X of 7 and current label',
      (tester) async {
    await pumpStepper(tester, size: const Size(390, 800));

    expect(find.text('Step 4 of 7'), findsOneWidget);
    expect(find.text('Product Configuration'), findsOneWidget);
    expect(find.text('Review & Create'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('tablet stepper stays slim in height while spanning full width',
      (tester) async {
    await pumpStepper(tester, size: const Size(1100, 800));

    final cardFinder = find
        .descendant(
          of: find.byType(AddProductStepper),
          matching: find.byType(Container),
        )
        .first;
    final size = tester.getSize(cardFinder);
    expect(size.width, greaterThan(1000));
    expect(size.height, lessThanOrEqualTo(80));
    expect(tester.takeException(), isNull);
  });
}

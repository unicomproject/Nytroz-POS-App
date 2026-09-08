import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nytroz_pos/features/tenant_admin/products/domain/entities/add_product_wizard_state.dart';
import 'package:nytroz_pos/features/tenant_admin/products/domain/entities/step5_barcode_sku_state.dart';
import 'package:nytroz_pos/features/tenant_admin/products/domain/entities/tenant_product_create_options.dart';
import 'package:nytroz_pos/features/tenant_admin/products/domain/repositories/tenant_product_repository.dart';
import 'package:nytroz_pos/features/tenant_admin/products/presentation/controllers/add_product_wizard_controller.dart';
import 'package:nytroz_pos/features/tenant_admin/products/presentation/providers/tenant_product_providers.dart';
import 'package:nytroz_pos/features/tenant_admin/products/presentation/widgets/step_5/step_5_barcode_sku_form.dart';

class _FakeAddProductWizardController extends AddProductWizardController {
  _FakeAddProductWizardController(AddProductWizardState initialState)
      : super(_DummyRepository()) {
    state = initialState.copyWith(
      createOptions: const TenantProductCreateOptions(
        categories: [],
        subCategories: [],
        brands: [],
        units: [],
        taxes: [],
        outlets: [],
        variantOptionTemplates: [],
      ),
    );
  }

  @override
  Future<void> initWizard(
      {String? duplicateFromProductId, String? resumeLocalDraftId, String? resumeProductId}) async {
    // override so it doesn't fetch options
  }
}

class _DummyRepository implements TenantProductRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('Step 5 form renders correctly', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          addProductWizardControllerProvider.overrideWith((ref) {
            return _FakeAddProductWizardController(
              const AddProductWizardState(productStructure: 'SIMPLE'));
          }),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: Step5BarcodeSkuForm(),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify UI components exist
    expect(find.text('Barcode & SKU'), findsOneWidget);
    expect(find.text('Base SKU *'), findsOneWidget);
    expect(find.text('Apply'), findsOneWidget);
    expect(find.text('Parent Product Barcode'), findsOneWidget);
  });

  testWidgets(
      'SIMPLE assignment table matches selected-dot row layout',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          addProductWizardControllerProvider.overrideWith((ref) {
            return _FakeAddProductWizardController(
              const AddProductWizardState(
                productStructure: 'SIMPLE',
                productName: 't-shirt',
                step5State: Step5BarcodeSkuState(
                  baseSku: '220210',
                  parentProductBarcode: '11110001',
                ),
              ),
            );
          }),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 1200,
              height: 800,
              child: Step5BarcodeSkuForm(),
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Barcode & SKU Assignment'), findsOneWidget);
    expect(find.text('t-shirt'), findsWidgets);
    expect(find.byType(Checkbox), findsNothing);
    expect(find.text('Scan'), findsOneWidget);
    expect(find.byIcon(Icons.crop_free), findsOneWidget);
    expect(find.byIcon(Icons.edit_outlined), findsOneWidget);
    expect(find.byIcon(Icons.more_vert), findsNothing);
    expect(find.text('Complete'), findsOneWidget);
  });

  testWidgets(
      'Apply commits SKU and barcode to the table then clears the input fields',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          addProductWizardControllerProvider.overrideWith((ref) {
            return _FakeAddProductWizardController(
              const AddProductWizardState(
                productStructure: 'SIMPLE',
                productName: 't-shirt',
              ),
            );
          }),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 1200,
              height: 800,
              child: Step5BarcodeSkuForm(),
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).at(0), '220210');
    await tester.enterText(find.byType(TextField).at(1), '11110001');
    await tester.tap(find.text('Apply'));
    await tester.pumpAndSettle();

    expect(find.text('Barcode & SKU Assignment'), findsOneWidget);
    expect(find.text('220210'), findsOneWidget);
    expect(find.text('11110001'), findsOneWidget);

    final skuField = tester.widget<TextField>(find.byType(TextField).at(0));
    final barcodeField = tester.widget<TextField>(find.byType(TextField).at(1));
    expect(skuField.controller!.text, isEmpty);
    expect(barcodeField.controller!.text, isEmpty);
  });
}

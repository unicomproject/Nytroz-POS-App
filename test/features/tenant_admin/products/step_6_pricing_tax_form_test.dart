import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nytroz_pos/features/tenant_admin/products/data/models/step5_barcode_dtos.dart';
import 'package:nytroz_pos/features/tenant_admin/products/data/models/step6_pricing_tax_dtos.dart';
import 'package:nytroz_pos/features/tenant_admin/products/domain/entities/add_product_wizard_state.dart';
import 'package:nytroz_pos/features/tenant_admin/products/domain/entities/step4_variant_configuration_state.dart';
import 'package:nytroz_pos/features/tenant_admin/products/domain/entities/step5_barcode_sku_state.dart';
import 'package:nytroz_pos/features/tenant_admin/products/domain/entities/tenant_product_create_options.dart';
import 'package:nytroz_pos/features/tenant_admin/products/domain/repositories/tenant_product_repository.dart';
import 'package:nytroz_pos/features/tenant_admin/products/presentation/controllers/add_product_wizard_controller.dart';
import 'package:nytroz_pos/features/tenant_admin/products/presentation/providers/tenant_product_providers.dart';
import 'package:nytroz_pos/features/tenant_admin/products/presentation/utils/step_6_tax_preview.dart';
import 'package:nytroz_pos/features/tenant_admin/products/presentation/widgets/step_6/step_6_pricing_tax_form.dart';

class _FakeAddProductWizardController extends AddProductWizardController {
  _FakeAddProductWizardController(AddProductWizardState initialState)
      : super(_DummyRepository()) {
    state = initialState.copyWith(
      createOptions: initialState.createOptions ??
          const TenantProductCreateOptions(
            categories: [],
            subCategories: [],
            brands: [],
            units: [],
            taxes: [
              ProductTaxOption(
                id: 'tax-1',
                code: 'STD',
                name: 'Standard Rate',
                taxTreatment: 'TAXABLE',
                currentRate: 15,
              ),
            ],
            outlets: [],
            variantOptionTemplates: [],
            currencyCode: 'LKR',
          ),
    );
  }

  @override
  Future<void> initWizard(
      {String? duplicateFromProductId,
      String? resumeLocalDraftId,
      String? resumeProductId}) async {}
}

class _DummyRepository implements TenantProductRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test('exclusive tax preview matches 750 at 15%', () {
    final preview = computeStep6TaxPreview(
      sellingPrice: 750,
      ratePercent: 15,
      taxExclusive: true,
    );
    expect(preview.netPrice, 750);
    expect(preview.taxAmount, 112.5);
    expect(preview.finalPrice, 862.5);
  });

  test('inclusive tax preview extracts net from 850 at 2%', () {
    final preview = computeStep6TaxPreview(
      sellingPrice: 850,
      ratePercent: 2,
      taxExclusive: false,
    );
    expect(preview.finalPrice, 850);
    expect(preview.netPrice, closeTo(833.33, 0.01));
    expect(preview.taxAmount, closeTo(16.67, 0.01));
  });

  test('inclusive tax preview extracts net from 862.50 at 15%', () {
    final preview = computeStep6TaxPreview(
      sellingPrice: 862.50,
      ratePercent: 15,
      taxExclusive: false,
    );
    expect(preview.finalPrice, 862.50);
    expect(preview.netPrice, closeTo(750, 0.01));
    expect(preview.taxAmount, closeTo(112.5, 0.01));
  });

  testWidgets('SIMPLE Step 6 shows tax class and preview', (tester) async {
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
                standardSellingPrice: 750,
                taxId: 'tax-1',
                taxRate: 15,
                taxExclusive: true,
              ),
            );
          }),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 1200,
              height: 800,
              child: Step6PricingTaxForm(),
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Pricing & Tax'), findsOneWidget);
    expect(
      find.text(
        'Currency is inherited from tenant configuration and cannot be changed.',
      ),
      findsNothing,
    );
    expect(find.text('Standard Selling Price'), findsOneWidget);
    expect(find.text('Tax Class *'), findsOneWidget);
    expect(find.text('Tax Exclusive'), findsOneWidget);
    expect(find.text('Tax Inclusive'), findsOneWidget);
    expect(find.text('Tax Preview (Tax Exclusive)'), findsOneWidget);
    expect(find.text('LKR 862.50'), findsOneWidget);
    expect(find.text('This is the amount customers will pay.'), findsOneWidget);
    expect(find.text('Cost Price *'), findsNothing);
    expect(find.text('Standard Rate (15%)'), findsOneWidget);
    expect(find.text('Effective Tax Rate'), findsNothing);
    expect(find.text('Auto-filled based on selected tax class.'), findsNothing);

    await tester.tap(find.text('Tax Inclusive'));
    await tester.pumpAndSettle();
    expect(find.text('Tax Preview (Tax Inclusive)'), findsOneWidget);
    expect(find.text('LKR 750.00'), findsWidgets);
  });

  testWidgets('SIMPLE Tax Preview stays empty until price and tax class set',
      (tester) async {
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
                standardSellingPrice: 850,
              ),
            );
          }),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 1200,
              height: 800,
              child: Step6PricingTaxForm(),
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('LKR 850.00'), findsNothing);
    expect(
      find.text(
        'Enter selling price, select a tax class, then leave the price field to calculate the balance.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('SIMPLE Tax Preview calculates after price and tax class filled',
      (tester) async {
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
                standardSellingPrice: 850,
                taxId: 'tax-1',
                taxRate: 2,
                taxExclusive: false,
                createOptions: TenantProductCreateOptions(
                  categories: [],
                  subCategories: [],
                  brands: [],
                  units: [],
                  taxes: [
                    ProductTaxOption(
                      id: 'tax-1',
                      code: 'LKJ',
                      name: 'lkjhv',
                      taxTreatment: 'TAXABLE',
                      currentRate: 2,
                    ),
                  ],
                  outlets: [],
                  variantOptionTemplates: [],
                  currencyCode: 'LKR',
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
              child: Step6PricingTaxForm(),
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Tax Preview (Tax Inclusive)'), findsOneWidget);
    expect(find.text('Estimated Tax (2%)'), findsOneWidget);
    expect(find.text('LKR 850.00'), findsOneWidget);
    expect(find.text('LKR 833.33'), findsOneWidget);
    expect(find.text('LKR 16.67'), findsOneWidget);
    expect(find.text('This is the amount customers will pay.'), findsOneWidget);
  });

  testWidgets('SIMPLE Tax Preview does not live-update while typing price',
      (tester) async {
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
                taxId: 'tax-1',
                taxRate: 2,
                taxExclusive: false,
                createOptions: TenantProductCreateOptions(
                  categories: [],
                  subCategories: [],
                  brands: [],
                  units: [],
                  taxes: [
                    ProductTaxOption(
                      id: 'tax-1',
                      code: 'LKJ',
                      name: 'lkjhv',
                      taxTreatment: 'TAXABLE',
                      currentRate: 2,
                    ),
                  ],
                  outlets: [],
                  variantOptionTemplates: [],
                  currencyCode: 'LKR',
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
              child: Step6PricingTaxForm(),
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, '7');
    await tester.pump();
    expect(find.text('LKR 7.00'), findsNothing);

    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(find.text('LKR 7.00'), findsOneWidget);
    expect(find.text('LKR 6.86'), findsOneWidget);
    expect(find.text('LKR 0.14'), findsOneWidget);
  });

  testWidgets('SIMPLE Step 6 starts empty without sample amounts',
      (tester) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          addProductWizardControllerProvider.overrideWith((ref) {
            return _FakeAddProductWizardController(
              const AddProductWizardState(productStructure: 'SIMPLE'),
            );
          }),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 1200,
              height: 800,
              child: Step6PricingTaxForm(),
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('750.00'), findsNothing);
    expect(find.text('LKR 750.00'), findsNothing);
    expect(find.text('LKR 112.50'), findsNothing);
    expect(find.text('LKR 862.50'), findsNothing);
    expect(find.text('Standard Rate (15%)'), findsNothing);
    expect(find.text('15%'), findsNothing);
    expect(find.text('0.00'), findsNothing);
    expect(find.text('Select tax class'), findsOneWidget);
    expect(find.text('—'), findsWidgets);
    expect(find.text('Effective Tax Rate'), findsNothing);
    expect(
      find.text(
        'Enter selling price, select a tax class, then leave the price field to calculate the balance.',
      ),
      findsOneWidget,
    );
  });

  AddProductWizardState variantWizard({
    List<VariantPriceDto> prices = const [],
  }) {
    return AddProductWizardState(
      currentStep: 6,
      productStructure: 'VARIANT',
      productName: 'AquaFlow Classic Water Bottle',
      taxId: 'tax-1',
      taxRate: 15,
      taxName: 'Standard VAT',
      taxExclusive: true,
      variantPrices: prices,
      step4State: Step4VariantConfigurationState(
        generatedVariants: const [
          GeneratedVariantRow(
            clientCombinationKey: 'blue-500',
            combinationLabel: 'Blue / 500ml',
            displayLabel: 'Blue / 500ml',
          ),
          GeneratedVariantRow(
            clientCombinationKey: 'blue-1l',
            combinationLabel: 'Blue / 1L',
            displayLabel: 'Blue / 1L',
          ),
          GeneratedVariantRow(
            clientCombinationKey: 'black-500',
            combinationLabel: 'Black / 500ml',
            displayLabel: 'Black / 500ml',
            isIncluded: false,
          ),
        ],
      ),
      step5State: const Step5BarcodeSkuState(
        assignments: [
          BarcodeSkuAssignmentDto(
            clientCombinationKey: 'blue-500',
            sku: '741853595-500B',
            isAssigned: true,
          ),
          BarcodeSkuAssignmentDto(
            clientCombinationKey: 'blue-1l',
            sku: '741853595-1LB',
            isAssigned: true,
          ),
        ],
      ),
    );
  }

  Future<void> pumpStep6(
    WidgetTester tester,
    AddProductWizardState initial,
  ) async {
    tester.view.physicalSize = const Size(1024, 768);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          addProductWizardControllerProvider.overrideWith((ref) {
            return _FakeAddProductWizardController(initial);
          }),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 1024,
              height: 768,
              child: Step6PricingTaxForm(),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('UI-01 SIMPLE does not render Variant Step 6', (tester) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          addProductWizardControllerProvider.overrideWith((ref) {
            return _FakeAddProductWizardController(
              const AddProductWizardState(productStructure: 'SIMPLE'),
            );
          }),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 1200,
              height: 800,
              child: Step6PricingTaxForm(),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Pricing & Tax — Variant Product'), findsNothing);
    expect(find.text('Set the selling price and tax details for this product.'),
        findsOneWidget);
  });

  testWidgets('UI-02 VARIANT renders Variant Step 6', (tester) async {
    await pumpStep6(tester, variantWizard());
    expect(find.text('Pricing & Tax — Variant Product'), findsOneWidget);
    expect(find.textContaining('Prices are managed at variant level'),
        findsOneWidget);
    expect(find.text('Standard Selling Price'), findsNothing);
  });

  testWidgets('UI-03/04 table shows included variants only', (tester) async {
    await pumpStep6(tester, variantWizard());
    expect(find.text('Blue / 500ml'), findsOneWidget);
    expect(find.text('Blue / 1L'), findsOneWidget);
    expect(find.text('Black / 500ml'), findsNothing);
    expect(find.text('2 Variants'), findsWidgets);
  });

  testWidgets('UI-05 each row shows Step 5 SKU', (tester) async {
    await pumpStep6(tester, variantWizard());
    expect(find.text('741853595-500B'), findsOneWidget);
    expect(find.text('741853595-1LB'), findsOneWidget);
  });

  testWidgets('UI-08 Apply to All populates all rows', (tester) async {
    await pumpStep6(tester, variantWizard());
    expect(find.text('Set Same Price for All Variants'), findsOneWidget);
    expect(find.text('Default Selling Price'), findsNothing);
    expect(find.textContaining('Default Price'), findsNothing);
    await tester.enterText(find.byType(TextField).first, '650');
    await tester.tap(find.widgetWithText(FilledButton, 'Apply to All'));
    await tester.pumpAndSettle();
    expect(find.text('650'), findsWidgets);
    expect(find.text('Priced'), findsNWidgets(2));
  });

  testWidgets('UI-09 Apply to All then override one row', (tester) async {
    await pumpStep6(tester, variantWizard());
    await tester.enterText(find.byType(TextField).first, '650');
    await tester.tap(find.widgetWithText(FilledButton, 'Apply to All'));
    await tester.pumpAndSettle();
    final rowFields = find.byType(TextField);
    await tester.enterText(rowFields.at(1), '750');
    await tester.pumpAndSettle();
    expect(find.text('750'), findsOneWidget);
    expect(find.text('650'), findsWidgets);
  });

  testWidgets('UX-09 overwrite confirmation when rows already priced',
      (tester) async {
    await pumpStep6(
      tester,
      variantWizard(prices: const [
        VariantPriceDto(
          clientCombinationKey: 'blue-500',
          sellingPrice: 750,
        ),
        VariantPriceDto(
          clientCombinationKey: 'blue-1l',
          sellingPrice: 650,
        ),
      ]),
    );
    await tester.enterText(find.byType(TextField).first, '500');
    await tester.tap(find.widgetWithText(FilledButton, 'Apply to All'));
    await tester.pumpAndSettle();
    expect(find.text('Apply price to all variants?'), findsOneWidget);
    expect(
      find.text('This will replace existing variant prices.'),
      findsOneWidget,
    );
    await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
    await tester.pumpAndSettle();
    expect(find.text('750'), findsOneWidget);
    expect(find.text('650'), findsWidgets);

    await tester.tap(find.widgetWithText(FilledButton, 'Apply to All'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Apply to All').last);
    await tester.pumpAndSettle();
    expect(find.text('500'), findsWidgets);
    expect(find.text('750'), findsNothing);
  });

  testWidgets('UI-15/16/17 common tax class; resolved rate; no per-row tax',
      (tester) async {
    await pumpStep6(tester, variantWizard());
    expect(find.text('Tax Class *'), findsOneWidget);
    expect(find.textContaining('15.00%'), findsOneWidget);
    expect(find.text('Tax Exclusive'), findsOneWidget);
    expect(find.text('Tax Inclusive'), findsOneWidget);
  });

  testWidgets('UI-18 Save Draft with pending prices allowed', (tester) async {
    late _FakeAddProductWizardController controller;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          addProductWizardControllerProvider.overrideWith((ref) {
            controller = _FakeAddProductWizardController(variantWizard());
            return controller;
          }),
        ],
        child: const MaterialApp(
          home: Scaffold(body: Step6PricingTaxForm()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final ok = await controller.saveDraft();
    expect(ok, isFalse);
    expect(
      controller.wizardState.fieldErrors['variantPrices'],
      isNull,
    );
  });

  testWidgets('UI-19 pending rows block Continue', (tester) async {
    late _FakeAddProductWizardController controller;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          addProductWizardControllerProvider.overrideWith((ref) {
            controller = _FakeAddProductWizardController(
              variantWizard(prices: const [
                VariantPriceDto(
                  clientCombinationKey: 'blue-500',
                  sellingPrice: 750,
                ),
              ]),
            );
            return controller;
          }),
        ],
        child: const MaterialApp(
          home: Scaffold(body: Step6PricingTaxForm()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final ok = await controller.saveAndContinue();
    expect(ok, isFalse);
    expect(
      controller.wizardState.fieldErrors['variantPrices'],
      contains('all included variants'),
    );
  });

  testWidgets('UI-20 all prices complete allows Continue', (tester) async {
    late _FakeAddProductWizardController controller;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          addProductWizardControllerProvider.overrideWith((ref) {
            controller = _FakeAddProductWizardController(
              variantWizard(prices: const [
                VariantPriceDto(
                  clientCombinationKey: 'blue-500',
                  sellingPrice: 750,
                ),
                VariantPriceDto(
                  clientCombinationKey: 'blue-1l',
                  sellingPrice: 650,
                ),
              ]),
            );
            return controller;
          }),
        ],
        child: const MaterialApp(
          home: Scaffold(body: Step6PricingTaxForm()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final ok = await controller.saveAndContinue();
    expect(ok, isTrue);
    expect(controller.wizardState.currentStep, 7);
  });

  testWidgets('UX-10 SIMPLE Step 6 unchanged — no bulk helper label',
      (tester) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          addProductWizardControllerProvider.overrideWith((ref) {
            return _FakeAddProductWizardController(
              const AddProductWizardState(productStructure: 'SIMPLE'),
            );
          }),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 1200,
              height: 800,
              child: Step6PricingTaxForm(),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Set Same Price for All Variants'), findsNothing);
    expect(find.text('Standard Selling Price'), findsOneWidget);
  });
}

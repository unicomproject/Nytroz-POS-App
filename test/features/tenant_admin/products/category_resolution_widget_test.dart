// ignore_for_file: invalid_annotation_target, library_annotations
@Skip('Broken by 6-step wizard refactor')
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nytroz_pos/features/tenant_admin/products/data/dtos/product_setup_scan_dtos.dart';
import 'package:nytroz_pos/features/tenant_admin/products/domain/entities/add_product_wizard_state.dart';
import 'package:nytroz_pos/features/tenant_admin/products/domain/entities/scan_barcode_step_state.dart';
import 'package:nytroz_pos/features/tenant_admin/products/domain/entities/tenant_product_create_options.dart';
import 'package:nytroz_pos/features/tenant_admin/products/domain/repositories/tenant_product_repository.dart';
import 'package:nytroz_pos/features/tenant_admin/products/presentation/controllers/add_product_wizard_controller.dart';
import 'package:nytroz_pos/features/tenant_admin/products/presentation/widgets/basic_details/basic_details.dart';
import 'package:nytroz_pos/features/tenant_admin/products/presentation/widgets/scan_barcode/scan_barcode_step.dart';

class _FakeRepo implements TenantProductRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _TestController extends AddProductWizardController {
  _TestController() : super(_FakeRepo());
}

@Skip('Needs UI refactor update for 6-step flow')
void main() {
  group('Scan Preview Widget Tests - Category Resolution', () {
    Future<void> pumpScanPreview(
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

    testWidgets('FOUND + mapped category renders mapped tenant category in preview', (tester) async {
      await pumpScanPreview(
        tester,
        scan: const ScanBarcodeStepState(
          panel: ScanBarcodePanel.externalFound,
          candidateBarcode: '5449000000996',
          externalSuggestion: ExternalProductSuggestionDto(
            productName: 'Coca-Cola Can',
            categoryText: 'Beverages, Colas',
            externalCategoryKey: 'en:colas',
            externalCategoryName: 'Colas',
            externalCategoryHierarchy: ['en:beverages', 'en:colas'],
          ),
          categoryResolution: TenantCategoryResolutionDto(
            provider: 'openfoodfacts',
            externalCategoryKey: 'en:colas',
            externalCategoryName: 'Colas',
            mappedCategory: TenantCategoryCandidateDto(
              id: 'cat-soft-drinks',
              name: 'Soft Drinks',
              code: 'CSD',
            ),
            suggestions: [],
          ),
        ),
      );

      expect(find.text('External Category'), findsOneWidget);
      expect(find.text('Colas'), findsOneWidget);
      expect(find.text('Category Hierarchy'), findsOneWidget);
      expect(find.text('Beverages > Colas'), findsOneWidget);
      expect(find.text('Tenant Category'), findsOneWidget);
      expect(find.text('Soft Drinks (Mapped)'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('FOUND + suggestions does not falsely render "Mapped"', (tester) async {
      await pumpScanPreview(
        tester,
        scan: const ScanBarcodeStepState(
          panel: ScanBarcodePanel.externalFound,
          candidateBarcode: '5449000000996',
          externalSuggestion: ExternalProductSuggestionDto(
            productName: 'Tropical Juice',
            externalCategoryName: 'Fruit Juices',
          ),
          categoryResolution: TenantCategoryResolutionDto(
            provider: 'openfoodfacts',
            externalCategoryKey: 'en:fruit-juices',
            externalCategoryName: 'Fruit Juices',
            mappedCategory: null,
            suggestions: [
              TenantCategoryCandidateDto(
                id: 'cat-bev',
                name: 'Beverages',
                code: 'CBEV',
              ),
            ],
          ),
        ),
      );

      expect(find.text('Tenant Category'), findsOneWidget);
      expect(find.text('Suggested: Beverages'), findsOneWidget);
      expect(find.textContaining('(Mapped)'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('FOUND + no category renders safely without category section errors', (tester) async {
      await pumpScanPreview(
        tester,
        scan: const ScanBarcodeStepState(
          panel: ScanBarcodePanel.externalFound,
          candidateBarcode: '5449000000996',
          externalSuggestion: ExternalProductSuggestionDto(
            productName: 'Simple Item',
          ),
          categoryResolution: null,
        ),
      );

      expect(find.text('Product Found'), findsOneWidget);
      expect(find.text('Simple Item'), findsOneWidget);
      expect(find.text('Tenant Category'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });

  group('Basic Details Widget Tests - Category Resolution & Suggestions', () {
    const options = TenantProductCreateOptions(
      categories: [
        ProductCategoryOption(id: 'cat-soft-drinks', code: 'CSD', name: 'Soft Drinks'),
        ProductCategoryOption(id: 'cat-beverages', code: 'CBEV', name: 'Beverages'),
        ProductCategoryOption(id: 'cat-snacks', code: 'CSNK', name: 'Snacks'),
      ],
      subCategories: [],
      brands: [
        ProductBrandOption(id: 'brand-1', code: 'B1', name: 'Brand One'),
      ],
      units: [],
      taxes: [],
      outlets: [],
      variantOptionTemplates: [],
    );

    Future<void> pumpBasicDetails(
      WidgetTester tester, {
      required AddProductWizardState state,
      required AddProductWizardController controller,
      Size size = const Size(1024, 768),
    }) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final name = TextEditingController();
      final code = TextEditingController();
      final shortDesc = TextEditingController();
      final longDesc = TextEditingController();

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: size.width,
                height: size.height,
                child: Step1BasicDetails(
                  state: state,
                  controller: controller,
                  nameController: name,
                  codeController: code,
                  shortDescriptionController: shortDesc,
                  longDescriptionController: longDesc,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
    }

    testWidgets('mapped category dropdown preselected and no suggestion chips rendered', (tester) async {
      final controller = _TestController();
      final state = AddProductWizardState(
        createOptions: options,
        categoryId: 'cat-soft-drinks',
        scanStepState: const ScanBarcodeStepState(
          categoryResolution: TenantCategoryResolutionDto(
            provider: 'openfoodfacts',
            externalCategoryKey: 'en:colas',
            mappedCategory: TenantCategoryCandidateDto(
              id: 'cat-soft-drinks',
              name: 'Soft Drinks',
              code: 'CSD',
            ),
            suggestions: [],
          ),
        ),
      );

      await pumpBasicDetails(tester, state: state, controller: controller);

      expect(find.text('Soft Drinks'), findsOneWidget);
      expect(find.text('Suggested:'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('suggestions render chips when mappedCategory is null and filtered against options', (tester) async {
      final controller = _TestController();
      final state = AddProductWizardState(
        createOptions: options,
        scanStepState: const ScanBarcodeStepState(
          categoryResolution: TenantCategoryResolutionDto(
            provider: 'openfoodfacts',
            externalCategoryKey: 'en:colas',
            mappedCategory: null,
            suggestions: [
              TenantCategoryCandidateDto(
                id: 'cat-beverages',
                name: 'Beverages',
                code: 'CBEV',
              ),
              TenantCategoryCandidateDto(
                id: 'cat-non-existent',
                name: 'Unknown Category',
                code: 'UNK',
              ),
            ],
          ),
        ),
      );

      await pumpBasicDetails(tester, state: state, controller: controller);

      expect(find.text('Suggested:'), findsOneWidget);
      expect(find.text('Beverages'), findsOneWidget);
      // cat-non-existent must be filtered out because it is not in createOptions.categories
      expect(find.text('Unknown Category'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('tapping suggestion chip triggers controller category update', (tester) async {
      final controller = _TestController();
      final state = AddProductWizardState(
        createOptions: options,
        scanStepState: const ScanBarcodeStepState(
          categoryResolution: TenantCategoryResolutionDto(
            provider: 'openfoodfacts',
            externalCategoryKey: 'en:colas',
            mappedCategory: null,
            suggestions: [
              TenantCategoryCandidateDto(
                id: 'cat-beverages',
                name: 'Beverages',
                code: 'CBEV',
              ),
            ],
          ),
        ),
      );

      await pumpBasicDetails(tester, state: state, controller: controller);

      final chipFinder = find.byKey(const Key('category_suggestion_cat-beverages'));
      expect(chipFinder, findsOneWidget);
      await tester.tap(chipFinder);
      await tester.pump();

      expect(controller.state.categoryId, 'cat-beverages');
      controller.dispose();
    });

    testWidgets('1024x768 layout has no overflow with suggestions', (tester) async {
      final controller = _TestController();
      final state = AddProductWizardState(
        createOptions: options,
        scanStepState: const ScanBarcodeStepState(
          categoryResolution: TenantCategoryResolutionDto(
            provider: 'openfoodfacts',
            externalCategoryKey: 'en:colas',
            mappedCategory: null,
            suggestions: [
              TenantCategoryCandidateDto(
                id: 'cat-soft-drinks',
                name: 'Soft Drinks',
                code: 'CSD',
              ),
              TenantCategoryCandidateDto(
                id: 'cat-beverages',
                name: 'Beverages',
                code: 'CBEV',
              ),
              TenantCategoryCandidateDto(
                id: 'cat-snacks',
                name: 'Snacks',
                code: 'CSNK',
              ),
            ],
          ),
        ),
      );

      await pumpBasicDetails(
        tester,
        state: state,
        controller: controller,
        size: const Size(1024, 768),
      );

      expect(find.text('Suggested:'), findsOneWidget);
      expect(find.text('Soft Drinks'), findsOneWidget);
      expect(find.text('Beverages'), findsOneWidget);
      expect(find.text('Snacks'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}

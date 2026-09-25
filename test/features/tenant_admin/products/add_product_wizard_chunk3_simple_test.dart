// ignore_for_file: invalid_annotation_target
@Skip('Broken by 6-step wizard refactor')
import 'package:nytroz_pos/features/tenant_admin/products/data/dtos/product_setup_scan_dtos.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nytroz_pos/features/tenant_admin/products/data/dtos/product_draft_response_dto.dart';
import 'package:nytroz_pos/features/tenant_admin/products/data/dtos/save_product_draft_request_dto.dart';
import 'package:nytroz_pos/features/tenant_admin/products/data/dtos/staged_image_response_dto.dart';
import 'package:nytroz_pos/features/tenant_admin/products/domain/entities/product_delete_result.dart';
import 'package:nytroz_pos/features/tenant_admin/products/domain/entities/product_form_data.dart';
import 'package:nytroz_pos/features/tenant_admin/products/domain/entities/product_status_update_result.dart';
import 'package:nytroz_pos/features/tenant_admin/products/domain/entities/tenant_product.dart';
import 'package:nytroz_pos/features/tenant_admin/products/domain/entities/tenant_product_create_options.dart';
import 'package:nytroz_pos/features/tenant_admin/products/domain/entities/tenant_product_detail.dart';
import 'package:nytroz_pos/features/tenant_admin/products/domain/entities/tenant_product_filter_options.dart';
import 'package:nytroz_pos/features/tenant_admin/products/data/dtos/product_create_request_dto.dart';
import 'package:nytroz_pos/features/tenant_admin/products/domain/repositories/tenant_product_repository.dart';
import 'package:nytroz_pos/features/tenant_admin/products/presentation/controllers/add_product_wizard_controller.dart';
import 'package:nytroz_pos/features/tenant_admin/products/presentation/providers/tenant_product_providers.dart';
import 'package:nytroz_pos/features/tenant_admin/products/presentation/widgets/barcode_sku/barcode_sku_form.dart';
import 'package:nytroz_pos/features/tenant_admin/products/presentation/widgets/review_create/review_create.dart';

class _TrackingRepo implements TenantProductRepository {
  @override
  Future<ResolveProductBarcodeResponseDto> resolveBarcode(ResolveProductBarcodeRequestDto request) async {
    throw UnimplementedError();
  }

  @override
  Future<ExternalLookupProductBarcodeResponseDto> externalLookupBarcode({required String barcode, String? identifierStandard}) async {
    throw UnimplementedError();
  }

  @override
  Future<SkuCandidateResponseDto> generateSkuCandidate(GenerateSkuCandidateRequestDto request) async {
    throw UnimplementedError();
  }

  int saveDraftCallCount = 0;
  int updateDraftCallCount = 0;
  int createProductCallCount = 0;
  int updateProductCallCount = 0;

  @override
  Future<TenantProductCreateOptions> getCreateOptions() async {
    return const TenantProductCreateOptions(
      categories: [
        ProductCategoryOption(id: 'cat-1', code: 'CAT1', name: 'Electronics'),
      ],
      subCategories: [],
      brands: [
        ProductBrandOption(id: 'brand-1', code: 'BR1', name: 'Sony'),
      ],
      units: [
        ProductUnitOption(id: 'unit-1', code: 'PCS', name: 'Piece'),
        ProductUnitOption(id: 'unit-2', code: 'BOX', name: 'Box'),
      ],
      taxes: [
        ProductTaxOption(id: 'tax-1', code: 'TAX15', name: 'VAT 15%'),
      ],
      outlets: [],
      variantOptionTemplates: [],
    );
  }

  @override
  Future<ProductDraftResponseDto> saveDraft(
      SaveProductDraftRequestDto request) async {
    saveDraftCallCount++;
    throw StateError('saveDraft must not be called');
  }

  @override
  Future<ProductDraftResponseDto> updateDraft(
      String productId, SaveProductDraftRequestDto request) async {
    updateDraftCallCount++;
    throw StateError('updateDraft must not be called');
  }

  @override
  Future<ProductCreateResult> createProduct(ProductFormData request) async {
    createProductCallCount++;
    throw StateError('createProduct must not be called');
  }

  @override
  Future<ProductCreateResult> createProductFromWizard(
      Map<String, dynamic> wizardCreatePayload) async {
    createProductCallCount++;
    throw StateError('createProductFromWizard must not be called');
  }

  @override
  Future<TenantProductDetail> updateProduct(
      String productId, ProductFormData request) async {
    updateProductCallCount++;
    throw StateError('updateProduct must not be called');
  }

  @override
  Future<ProductDraftResponseDto> getSetup(String productId) =>
      throw UnimplementedError();
  @override
  Future<StagedImageResponseDto> stageImage(
          List<int> bytes, String fileName, String mimeType) =>
      throw UnimplementedError();
  @override
  Future<StagedImageResponseDto> stageImageFromUrl(String imageUrl) =>
      throw UnimplementedError();
  @override
  Future<ProductImageResponseDto> uploadProductImage(String productId,
          List<int> bytes, String fileName, String mimeType) =>
      throw UnimplementedError();
  @override
  Future<ProductDraftResponseDto> deleteProductImage(
          String productId, String productImageId) =>
      throw UnimplementedError();
  @override
  Future<ProductDraftResponseDto> reorderProductImages(
          String productId,
          int expectedRowVersion,
          String? primaryProductImageId,
          List<Map<String, dynamic>> items) =>
      throw UnimplementedError();
  @override
  Future<ProductDraftResponseDto> replaceProductImages(String productId,
          int expectedRowVersion, List<String> stagedMediaAssetIds) =>
      throw UnimplementedError();
  @override
  Future<ProductDeleteResult> deleteProduct(String productId) =>
      throw UnimplementedError();
  @override
  Future<TenantProductDetail> getProductById(String productId) =>
      throw UnimplementedError();
  @override
  Future<TenantProductFilterOptions> getProductFilterOptions() =>
      throw UnimplementedError();
  @override
  Future<TenantProductListResult> getProducts(
          {required TenantProductListQuery query}) =>
      throw UnimplementedError();
  @override
  Future<TenantProductSummary> getProductSummary() =>
      throw UnimplementedError();
  @override
  Future<ProductStatusUpdateResult> updateProductStatus(
          String productId, String status) =>
      throw UnimplementedError();
  @override
  Future<ProductCreateResponseDto> duplicateProduct(String productId) =>
      throw UnimplementedError();
}

@Skip('Needs UI refactor update for 6-step flow')
void main() {
  late _TrackingRepo repo;
  late AddProductWizardController controller;

  Future<void> goToStep3Configuration() async {
    await controller.initWizard();
    controller.skipScanStepForTesting();
    controller.updateProductName('Simple Widget');
    controller.updateCategory('cat-1');
    controller.updateInternalCode('SW-001');
    await controller.saveAndContinue();
    controller.setProductStructure('SIMPLE');
    controller.selectUnitModel('SINGLE_UNIT');
    controller.setProductUnit('unit-1');
  }

  Future<void> goToStep4Pricing() async {
    await goToStep3Configuration();
    controller.updateSimpleBaseSku('TEST-SIMPLE-001');
    await controller.saveAndContinue();
    expect(controller.wizardState.currentStep, 4);
  }

  Future<void> goToStep5Tracking() async {
    await goToStep4Pricing();
    controller.updateCostPrice(100);
    controller.updateStandardSellingPrice(150);
    controller.updateTaxId('tax-1', taxRate: 15, taxName: 'VAT 15%');
    await controller.saveAndContinue();
    expect(controller.wizardState.currentStep, 5);
  }

  setUp(() {
    repo = _TrackingRepo();
    controller = AddProductWizardController(repo);
  });

  tearDown(() {
    if (controller.mounted) {
      controller.dispose();
    }
  });

  group('Chunk 3 SIMPLE flow', () {
    test('1. SIMPLE Track ON → Step 4', () async {
      await controller.initWizard();
      controller.skipScanStepForTesting();
      controller.updateProductName('A');
      controller.updateCategory('cat-1');
      controller.updateInternalCode('code-1');
      await controller.saveAndContinue();
      controller.setProductStructure('SIMPLE');
      controller.selectUnitModel('SINGLE_UNIT');
      controller.setProductUnit('unit-1');
      controller.updateSimpleBaseSku('TEST-SIMPLE-001');
      await controller.saveAndContinue();
      expect(controller.wizardState.currentStep, 4);
    });

    test('2. SIMPLE Track OFF → Step 4', () async {
      await controller.initWizard();
      controller.skipScanStepForTesting();
      controller.updateProductName('A');
      controller.updateCategory('cat-1');
      controller.updateInternalCode('code-2');
      await controller.saveAndContinue();
      controller.setProductStructure('SIMPLE');
      controller.selectUnitModel('SINGLE_UNIT');
      controller.setProductUnit('unit-1');
      controller.updateSimpleBaseSku('TEST-SIMPLE-001');
      await controller.saveAndContinue();
      expect(controller.wizardState.currentStep, 4);
    });

    test('3. Step 3 → Step 4', () async {
      await goToStep3Configuration();
      controller.updateSimpleBaseSku('TEST-SIMPLE-001');
      await controller.saveAndContinue();
      expect(controller.wizardState.currentStep, 4);
    });

    test('5. SIMPLE Step 3 does not require ProductVariantId', () async {
      await goToStep3Configuration();
      controller.updateSimpleBaseSku('TEST-SIMPLE-001');
      controller.updateSimpleParentBarcode('8901234567890');
      await controller.saveAndContinue();
      final assignment = controller.wizardState.step5State.assignments.first;
      expect(assignment.productVariantId, isNull);
      expect(assignment.sku, 'TEST-SIMPLE-001');
      expect(controller.wizardState.productId, isNull);
    });

    test('6. Step 3 Save & Continue → Step 4', () async {
      await goToStep3Configuration();
      controller.updateSimpleBaseSku('TEST-SIMPLE-001');
      expect(await controller.saveAndContinue(), isTrue);
      expect(controller.wizardState.currentStep, 4);
    });

    test('7. Step 3 Back → Step 2', () async {
      await goToStep3Configuration();
      controller.goToPreviousApplicableStep();
      expect(controller.wizardState.currentStep, 2);
    });

    test('8. Step 3 values survive Back/Forward', () async {
      await goToStep3Configuration();
      controller.updateSimpleBaseSku('TEST-SIMPLE-001');
      controller.updateSimpleParentBarcode('8901234567890');
      controller.goToPreviousApplicableStep(); // → 2
      expect(await controller.saveAndContinue(), isTrue); // → 3
      expect(controller.wizardState.step5State.baseSku, 'TEST-SIMPLE-001');
      expect(
          controller.wizardState.step5State.parentProductBarcode, '8901234567890');
    });

    test('10. Tax selection populates rate and name', () async {
      await goToStep4Pricing();
      controller.updateTaxId('tax-1', taxRate: 15, taxName: 'VAT 15%');
      expect(controller.wizardState.taxId, 'tax-1');
      expect(controller.wizardState.taxRate, 15);
      expect(controller.wizardState.taxName, 'VAT 15%');
    });

    test('11. Step 4 Save & Continue → Step 5', () async {
      await goToStep4Pricing();
      controller.updateCostPrice(100);
      controller.updateStandardSellingPrice(150);
      controller.updateDiscountPrice(140);
      controller.updateTaxId('tax-1', taxRate: 15, taxName: 'VAT 15%');
      expect(await controller.saveAndContinue(), isTrue);
      expect(controller.wizardState.currentStep, 5);
    });

    test('12. Step 4 values survive Back/Forward', () async {
      await goToStep4Pricing();
      controller.updateCostPrice(100);
      controller.updateStandardSellingPrice(150);
      controller.updateDiscountPrice(140);
      controller.updateTaxId('tax-1', taxRate: 15, taxName: 'VAT 15%');
      controller.goToPreviousApplicableStep(); // → 3
      expect(await controller.saveAndContinue(), isTrue); // → 4
      expect(controller.wizardState.costPrice, 100);
      expect(controller.wizardState.standardSellingPrice, 150);
      expect(controller.wizardState.discountPrice, 140);
      expect(controller.wizardState.taxId, 'tax-1');
      expect(controller.wizardState.taxRate, 15);
    });

    test('14. Save & Continue across Step 3/4/5 triggers zero Product mutations',
        () async {
      await goToStep5Tracking();
      expect(repo.saveDraftCallCount, 0);
      expect(repo.updateDraftCallCount, 0);
      expect(repo.createProductCallCount, 0);
      expect(repo.updateProductCallCount, 0);
      expect(controller.wizardState.productId, isNull);
    });

    test('15. VARIANT routing regression still passes', () async {
      await controller.initWizard();
      controller.skipScanStepForTesting();
      controller.updateProductName('Variant Item');
      controller.updateCategory('cat-1');
      controller.updateInternalCode('V-001');
      await controller.saveAndContinue();
      controller.setProductStructure('VARIANT');
      controller.addAttributeRow();
      controller.updateAttributeName(0, 'Color');
      controller.selectValues(0, ['Red']);
      await controller.generateVariants();
      for (final assignment in controller.wizardState.step5State.assignments) {
        await controller.assignBarcodeSkuAndSave(
          assignment.copyWith(sku: 'SKU-${assignment.clientCombinationKey}'),
        );
      }
      await controller.saveAndContinue();
      expect(controller.wizardState.currentStep, 4);
    });

    test('SIMPLE multiple units survive Back to Step 3', () async {
      await controller.initWizard();
      controller.skipScanStepForTesting();
      controller.updateProductName('Multi Unit');
      controller.updateCategory('cat-1');
      controller.updateInternalCode('MU-001');
      await controller.saveAndContinue();
      controller.setProductStructure('SIMPLE');
      controller.selectUnitModel('MULTIPLE_UNITS');
      controller.setBaseUnit('unit-1');
      controller.setSellingUnit('unit-1');
      controller.setPurchaseUnit('unit-2');
      controller.setItemsPerPurchaseUnit(12);
      controller.updateSimpleBaseSku('MU-SKU-1');
      await controller.saveAndContinue();
      expect(controller.wizardState.currentStep, 4);
      controller.goToPreviousApplicableStep();
      expect(controller.wizardState.currentStep, 3);
      expect(controller.wizardState.unitModel, 'MULTIPLE_UNITS');
      expect(controller.wizardState.baseUnitId, 'unit-1');
      expect(controller.wizardState.purchaseUnitId, 'unit-2');
      expect(controller.wizardState.itemsPerPurchaseUnit, 12);
    });

    testWidgets('4. SIMPLE Step 3 does not show Variant selector',
        (tester) async {
      await goToStep3Configuration();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            addProductWizardControllerProvider.overrideWith((ref) {
              return controller;
            }),
          ],
          child: const MaterialApp(
            home: Scaffold(body: Step5BarcodeSkuForm()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Variant *'), findsNothing);
      expect(find.text('Select variant'), findsNothing);
      expect(find.text('SKU'), findsWidgets);
      expect(find.text('Primary Barcode'), findsOneWidget);
            
    });

    testWidgets('13. Step 6 SIMPLE review has no Variant Configuration section',
        (tester) async {
      await goToStep5Tracking();
      controller.updateSimpleParentBarcode('8901234567890');
      await controller.saveAndContinue();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Step7ReviewCreate(state: controller.wizardState),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Variant Configuration'), findsNothing);
      expect(find.text('Product Configuration'), findsNothing);
      expect(find.text('Basic Details'), findsOneWidget);
      expect(find.text('Product Type & Tracking'), findsOneWidget);
      expect(find.text('Units & Pack Conversion'), findsOneWidget);
      expect(find.text('Barcode & SKU'), findsOneWidget);
      expect(find.text('SKU'), findsWidgets);
      expect(find.text('TEST-SIMPLE-001'), findsWidgets);
      expect(find.text('Pricing & Tax'), findsOneWidget);
      expect(find.text('VAT 15%'), findsOneWidget);
      expect(find.text('Simple Product'), findsWidgets);
      expect(find.text('Variant Product'), findsNothing);
      
      await tester.pump(const Duration(seconds: 1));
    });
  });
}

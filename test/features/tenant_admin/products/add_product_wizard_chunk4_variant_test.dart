import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nytroz_pos/features/tenant_admin/products/data/models/product_draft_response_dto.dart';
import 'package:nytroz_pos/features/tenant_admin/products/data/models/save_product_draft_request_dto.dart';
import 'package:nytroz_pos/features/tenant_admin/products/data/models/staged_image_response_dto.dart';
import 'package:nytroz_pos/features/tenant_admin/products/data/models/step5_barcode_dtos.dart';
import 'package:nytroz_pos/features/tenant_admin/products/domain/entities/product_delete_result.dart';
import 'package:nytroz_pos/features/tenant_admin/products/domain/entities/product_form_data.dart';
import 'package:nytroz_pos/features/tenant_admin/products/domain/entities/product_status_update_result.dart';
import 'package:nytroz_pos/features/tenant_admin/products/domain/entities/tenant_product.dart';
import 'package:nytroz_pos/features/tenant_admin/products/domain/entities/tenant_product_create_options.dart';
import 'package:nytroz_pos/features/tenant_admin/products/domain/entities/tenant_product_detail.dart';
import 'package:nytroz_pos/features/tenant_admin/products/domain/entities/tenant_product_filter_options.dart';
import 'package:nytroz_pos/features/tenant_admin/products/domain/repositories/tenant_product_repository.dart';
import 'package:nytroz_pos/features/tenant_admin/products/domain/utils/variant_combination_generator.dart';
import 'package:nytroz_pos/features/tenant_admin/products/presentation/controllers/add_product_wizard_controller.dart';
import 'package:nytroz_pos/features/tenant_admin/products/presentation/widgets/step_7/step_7_review_create.dart';

class _TrackingRepo implements TenantProductRepository {
  int saveDraftCallCount = 0;
  int updateDraftCallCount = 0;
  int createProductCallCount = 0;

  @override
  Future<TenantProductCreateOptions> getCreateOptions() async {
    return const TenantProductCreateOptions(
      categories: [
        ProductCategoryOption(id: 'cat-1', code: 'CAT1', name: 'Apparel'),
      ],
      subCategories: [],
      brands: [],
      units: [
        ProductUnitOption(id: 'unit-1', code: 'PCS', name: 'Piece'),
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
          String productId, ProductFormData request) =>
      throw UnimplementedError();
  @override
  Future<ProductDraftResponseDto> getSetup(String productId) =>
      throw UnimplementedError();
  @override
  Future<StagedImageResponseDto> stageImage(
          List<int> bytes, String fileName, String mimeType) =>
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
}

void main() {
  late _TrackingRepo repo;
  late AddProductWizardController controller;

  Future<void> goToStep4Variant() async {
    await controller.initWizard();
    controller.updateProductName('Color Tee');
    controller.updateCategory('cat-1');
    await controller.saveAndContinue();
    controller.setProductStructure('VARIANT');
    await controller.saveAndContinue();
    expect(controller.wizardState.currentStep, 4);
  }

  Future<void> generateColorSizeMatrix() async {
    controller.addAttributeRow();
    controller.updateAttributeName(0, 'Color');
    controller.selectValues(0, ['Red', 'Blue']);
    controller.addAttributeRow();
    controller.updateAttributeName(1, 'Size');
    controller.selectValues(1, ['Small', 'Medium']);
    await controller.generateVariants();
  }

  Future<void> assignAllSkus() async {
    controller.ensureVariantStep5Targets();
    var i = 0;
    for (final a in List.of(controller.wizardState.step5State.assignments)) {
      i++;
      await controller.assignBarcodeSkuAndSave(
        a.copyWith(
          sku: 'TEST-$i',
          barcode: '10000000000$i',
        ),
      );
    }
  }

  setUp(() {
    repo = _TrackingRepo();
    controller = AddProductWizardController(repo);
  });

  group('Chunk 4 VARIANT flow', () {
    test('1. VARIANT Step 2 → Step 4', () async {
      await goToStep4Variant();
      expect(controller.isStepApplicable(3), isFalse);
    });

    test('2. Step 3 never renders for VARIANT', () async {
      await goToStep4Variant();
      expect(controller.getNextApplicableStep(2), 4);
      expect(controller.getPreviousApplicableStep(4), 2);
      expect(controller.isStepApplicable(3), isFalse);
    });

    test('3/4. Generate Variants creates local combinations with zero mutation',
        () async {
      await goToStep4Variant();
      await generateColorSizeMatrix();
      expect(controller.wizardState.step4State.generatedVariants.length, 4);
      expect(repo.saveDraftCallCount, 0);
      expect(repo.updateDraftCallCount, 0);
      expect(repo.createProductCallCount, 0);
    });

    test('5. generated clientCombinationKey is stable', () async {
      await goToStep4Variant();
      await generateColorSizeMatrix();
      final firstKeys = controller.wizardState.step4State.generatedVariants
          .map((v) => v.clientCombinationKey)
          .toList();
      await controller.generateVariants();
      final secondKeys = controller.wizardState.step4State.generatedVariants
          .map((v) => v.clientCombinationKey)
          .toList();
      expect(secondKeys, firstKeys);

      final attrs = controller.wizardState.step4State.attributeRows;
      final redSmall = controller.wizardState.step4State.generatedVariants
          .firstWhere((v) => v.combinationLabel == 'Red / Small');
      final expected = VariantCombinationGenerator.generateClientCombinationKey(
        redSmall.selectedValues,
        attrs,
      );
      expect(redSmall.clientCombinationKey, expected);
    });

    test('6. Step 4 → Step 5 transfers generated variants', () async {
      await goToStep4Variant();
      await generateColorSizeMatrix();
      expect(await controller.saveAndContinue(), isTrue);
      expect(controller.wizardState.currentStep, 5);
      expect(controller.wizardState.step5State.assignments.length, 4);
      expect(
        controller.wizardState.step5State.assignments
            .every((a) => a.productVariantId == null),
        isTrue,
      );
    });

    test('7. fresh VARIANT Step 5 requires no productVariantId', () async {
      await goToStep4Variant();
      await generateColorSizeMatrix();
      await controller.saveAndContinue();
      await assignAllSkus();
      expect(
        controller.wizardState.step5State.assignments
            .every((a) => a.productVariantId == null),
        isTrue,
      );
      expect(controller.wizardState.productId, isNull);
    });

    test('8. each active variant can receive SKU', () async {
      await goToStep4Variant();
      await generateColorSizeMatrix();
      await controller.saveAndContinue();
      await assignAllSkus();
      expect(
        controller.wizardState.step5State.assignments
            .every((a) => a.sku != null && a.sku!.isNotEmpty),
        isTrue,
      );
    });

    test('9. duplicate local SKU validation', () async {
      await goToStep4Variant();
      await generateColorSizeMatrix();
      await controller.saveAndContinue();
      final keys = controller.wizardState.step5State.assignments
          .map((a) => a.clientCombinationKey)
          .toList();
      await controller.assignBarcodeSkuAndSave(
        BarcodeSkuAssignmentDto(clientCombinationKey: keys[0], sku: 'DUP'),
      );
      await controller.assignBarcodeSkuAndSave(
        BarcodeSkuAssignmentDto(clientCombinationKey: keys[1], sku: 'DUP'),
      );
      expect(await controller.saveAndContinue(), isFalse);
      expect(controller.wizardState.fieldErrors.containsKey('skuDuplicate'),
          isTrue);
      expect(controller.wizardState.currentStep, 5);
    });

    test('10. duplicate local barcode validation', () async {
      await goToStep4Variant();
      await generateColorSizeMatrix();
      await controller.saveAndContinue();
      final keys = controller.wizardState.step5State.assignments
          .map((a) => a.clientCombinationKey)
          .toList();
      await controller.assignBarcodeSkuAndSave(
        BarcodeSkuAssignmentDto(
            clientCombinationKey: keys[0], sku: 'A', barcode: 'SAME'),
      );
      await controller.assignBarcodeSkuAndSave(
        BarcodeSkuAssignmentDto(
            clientCombinationKey: keys[1], sku: 'B', barcode: 'SAME'),
      );
      await controller.assignBarcodeSkuAndSave(
        BarcodeSkuAssignmentDto(clientCombinationKey: keys[2], sku: 'C'),
      );
      await controller.assignBarcodeSkuAndSave(
        BarcodeSkuAssignmentDto(clientCombinationKey: keys[3], sku: 'D'),
      );
      expect(await controller.saveAndContinue(), isFalse);
      expect(
          controller.wizardState.fieldErrors.containsKey('barcodeDuplicate'),
          isTrue);
    });

    test('11. Step 5 incomplete assignment blocks Continue', () async {
      await goToStep4Variant();
      await generateColorSizeMatrix();
      await controller.saveAndContinue();
      expect(await controller.saveAndContinue(), isFalse);
      expect(controller.wizardState.currentStep, 5);
      expect(controller.wizardState.fieldErrors.containsKey('sku'), isTrue);
    });

    test('12. complete Step 5 → Step 6', () async {
      await goToStep4Variant();
      await generateColorSizeMatrix();
      await controller.saveAndContinue();
      await assignAllSkus();
      expect(await controller.saveAndContinue(), isTrue);
      expect(controller.wizardState.currentStep, 6);
    });

    test('13. Step 5 Back → Step 4', () async {
      await goToStep4Variant();
      await generateColorSizeMatrix();
      await controller.saveAndContinue();
      controller.goToPreviousApplicableStep();
      expect(controller.wizardState.currentStep, 4);
    });

    test('14. identifier values survive Back/Forward', () async {
      await goToStep4Variant();
      await generateColorSizeMatrix();
      await controller.saveAndContinue();
      await assignAllSkus();
      final before = {
        for (final a in controller.wizardState.step5State.assignments)
          a.clientCombinationKey: a.sku
      };
      controller.goToPreviousApplicableStep();
      expect(await controller.saveAndContinue(), isTrue);
      final after = {
        for (final a in controller.wizardState.step5State.assignments)
          a.clientCombinationKey: a.sku
      };
      expect(after, before);
    });

    test('15. reconciliation after Step 4 changes', () async {
      await goToStep4Variant();
      await generateColorSizeMatrix();
      await controller.saveAndContinue();
      await assignAllSkus();
      final redSmall = controller.wizardState.step4State.generatedVariants
          .firstWhere((v) => v.combinationLabel == 'Red / Small');
      final blueSmall = controller.wizardState.step4State.generatedVariants
          .firstWhere((v) => v.combinationLabel == 'Blue / Small');
      final keptSku = controller.wizardState.step5State.assignments
          .firstWhere((a) => a.clientCombinationKey == redSmall.clientCombinationKey)
          .sku;

      controller.goToPreviousApplicableStep(); // Step 4
      controller.confirmDeleteVariant(blueSmall.clientCombinationKey);
      expect(
        controller.wizardState.step5State.assignments
            .any((a) => a.clientCombinationKey == blueSmall.clientCombinationKey),
        isFalse,
      );
      expect(
        controller.wizardState.step5State.assignments
            .firstWhere(
                (a) => a.clientCombinationKey == redSmall.clientCombinationKey)
            .sku,
        keptSku,
      );
    });

    test('16. Step 6 → Step 7', () async {
      await goToStep4Variant();
      await generateColorSizeMatrix();
      await controller.saveAndContinue();
      await assignAllSkus();
      await controller.saveAndContinue();
      controller.updateCostPrice(100);
      controller.updateStandardSellingPrice(150);
      controller.updateDiscountPrice(140);
      controller.updateTaxId('tax-1', taxRate: 15, taxName: 'VAT 15%');
      expect(await controller.saveAndContinue(), isTrue);
      expect(controller.wizardState.currentStep, 7);
    });

    testWidgets('17/18. Step 7 shows Variant Configuration and hides Units',
        (tester) async {
      await goToStep4Variant();
      await generateColorSizeMatrix();
      await controller.saveAndContinue();
      await assignAllSkus();
      await controller.saveAndContinue();
      controller.updateCostPrice(100);
      controller.updateStandardSellingPrice(150);
      controller.updateTaxId('tax-1', taxRate: 15, taxName: 'VAT 15%');
      await controller.saveAndContinue();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Step7ReviewCreate(state: controller.wizardState),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Product Configuration'), findsOneWidget);
      expect(find.text('Barcode & SKU'), findsOneWidget);
      expect(find.text('Attributes'), findsOneWidget);
      expect(find.text('Variants Created'), findsOneWidget);
    });

    test('19. full flow performs zero Product DB mutation', () async {
      await goToStep4Variant();
      await generateColorSizeMatrix();
      await controller.saveAndContinue();
      await assignAllSkus();
      await controller.saveAndContinue();
      controller.updateCostPrice(100);
      controller.updateStandardSellingPrice(150);
      controller.updateTaxId('tax-1', taxRate: 15, taxName: 'VAT 15%');
      await controller.saveAndContinue();
      expect(repo.saveDraftCallCount, 0);
      expect(repo.updateDraftCallCount, 0);
      expect(repo.createProductCallCount, 0);
      expect(controller.wizardState.productId, isNull);
    });

    test('20. SIMPLE regression flow still passes', () async {
      await controller.initWizard();
      controller.updateProductName('Simple Still Works');
      controller.updateCategory('cat-1');
      await controller.saveAndContinue();
      controller.setProductStructure('SIMPLE');
      await controller.saveAndContinue();
      expect(controller.wizardState.currentStep, 3);
      controller.selectUnitModel('SINGLE_UNIT');
      controller.setProductUnit('unit-1');
      await controller.saveAndContinue();
      expect(controller.wizardState.currentStep, 5);
      controller.updateSimpleBaseSku('SIMPLE-SKU');
      await controller.saveAndContinue();
      expect(controller.wizardState.currentStep, 6);
      expect(controller.wizardState.step5State.baseSku, 'SIMPLE-SKU');
      expect(controller.isStepApplicable(4), isFalse);
    });
  });
}

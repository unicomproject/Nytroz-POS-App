import 'package:nytroz_pos/features/tenant_admin/products/data/dtos/product_setup_scan_dtos.dart';
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
      brands: [],
      units: [
        ProductUnitOption(id: 'unit-1', code: 'PCS', name: 'PCS'),
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
    throw StateError('saveDraft must not be called during Chunk 2 navigation');
  }

  @override
  Future<ProductDraftResponseDto> updateDraft(
      String productId, SaveProductDraftRequestDto request) async {
    updateDraftCallCount++;
    throw StateError('updateDraft must not be called during Chunk 2 navigation');
  }

  @override
  Future<ProductCreateResult> createProduct(ProductFormData request) async {
    createProductCallCount++;
    throw StateError('createProduct must not be called during Chunk 2');
  }

  @override
  Future<ProductCreateResult> createProductFromWizard(
      Map<String, dynamic> wizardCreatePayload) async {
    createProductCallCount++;
    throw StateError('createProductFromWizard must not be called during Chunk 2');
  }

  @override
  Future<TenantProductDetail> updateProduct(
      String productId, ProductFormData request) async {
    updateProductCallCount++;
    throw StateError('updateProduct must not be called during Chunk 2');
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

  Future<void> completeStep1() async {
    controller.skipScanStepForTesting();
    controller.updateProductName('Nav Product');
    controller.updateCategory('cat-1');
    controller.updateInternalCode('NAV-001');
    expect(await controller.saveAndContinue(), isTrue);
  }

  Future<void> completeStep3Units() async {
    controller.selectUnitModel('SINGLE_UNIT');
    controller.setProductUnit('unit-1');
    expect(await controller.saveAndContinue(), isTrue);
  }

  Future<void> completeStep5SimpleSku() async {
    controller.updateSimpleBaseSku('TEST-SIMPLE-001');
    controller.updateSimpleParentBarcode('8901234567890');
    expect(await controller.saveAndContinue(), isTrue);
  }

  Future<void> completeStep6Pricing() async {
    controller.updateTaxId('tax-1', taxRate: 15, taxName: 'VAT 15%');
    final structure = controller.wizardState.productStructure.toUpperCase();
    if (structure == 'VARIANT') {
      controller.reconcileVariantPricesWithVariants();
      controller.applyDefaultSellingPriceToAllVariants(150);
    } else {
      controller.updateCostPrice(100);
      controller.updateStandardSellingPrice(150);
      controller.updateDiscountPrice(140);
    }
    expect(await controller.saveAndContinue(), isTrue);
  }

  setUp(() {
    repo = _TrackingRepo();
    controller = AddProductWizardController(repo);
  });

  group('Applicable-step navigation', () {
    test('SIMPLE forward (with track inventory): 1 → 3 → 4 → 5 → 6 → 7', () async {
      await controller.initWizard();
      expect(controller.wizardState.currentStep, 1);

      await completeStep1(); // skip scan → fill basic details → step 3
      expect(controller.wizardState.currentStep, 3);

      controller.setProductStructure('SIMPLE');
      controller.setTrackInventory(true);
      expect(await controller.saveAndContinue(), isTrue);
      expect(controller.wizardState.currentStep, 4); // Units & Pack

      await completeStep3Units(); // step 4 → 5
      expect(controller.wizardState.currentStep, 5);

      await completeStep5SimpleSku(); // step 5 → 6
      expect(controller.wizardState.currentStep, 6);

      await completeStep6Pricing(); // step 6 → 7
      expect(controller.wizardState.currentStep, 7);

      expect(repo.saveDraftCallCount, 0);
      expect(repo.updateDraftCallCount, 0);
      expect(repo.createProductCallCount, 0);
    });

    test('SIMPLE backward (with track inventory): 7 → 6 → 5 → 4 → 3 → 2 → 1', () async {
      await controller.initWizard();
      await completeStep1(); // → 3
      controller.setProductStructure('SIMPLE');
      controller.setTrackInventory(true);
      await controller.saveAndContinue(); // → 4
      await completeStep3Units(); // → 5
      await completeStep5SimpleSku(); // → 6
      await completeStep6Pricing(); // → 7
      expect(controller.wizardState.currentStep, 7);

      controller.goToPreviousApplicableStep();
      expect(controller.wizardState.currentStep, 6);
      controller.goToPreviousApplicableStep();
      expect(controller.wizardState.currentStep, 5);
      controller.goToPreviousApplicableStep();
      expect(controller.wizardState.currentStep, 4);
      controller.goToPreviousApplicableStep();
      expect(controller.wizardState.currentStep, 3);
      controller.goToPreviousApplicableStep();
      expect(controller.wizardState.currentStep, 2);
      controller.goToPreviousApplicableStep();
      expect(controller.wizardState.currentStep, 1);

      expect(repo.saveDraftCallCount, 0);
      expect(repo.updateDraftCallCount, 0);
    });

    test('VARIANT forward: 1 → 3 → 5 → 6 → 7 (skips step 4 when trackInventory is off)', () async {
      await controller.initWizard();
      await completeStep1(); // → 3
      controller.setProductStructure('VARIANT');
      // trackInventory defaults to false → step 3 → 5 (skips 4)
      expect(await controller.saveAndContinue(), isTrue);
      expect(controller.wizardState.currentStep, 5);
      expect(controller.isStepApplicable(4), isFalse);

      controller.addAttributeRow();
      controller.updateAttributeName(0, 'Color');
      controller.selectValues(0, ['Red', 'Blue']);
      await controller.generateVariants();
      // Assign SKUs to all variants before saveAndContinue
      for (final assignment in controller.wizardState.step5State.assignments) {
        await controller.assignBarcodeSkuAndSave(
          assignment.copyWith(sku: 'SKU-${assignment.clientCombinationKey}'),
        );
      }
      expect(await controller.saveAndContinue(), isTrue);
      expect(controller.wizardState.currentStep, 6);

      await completeStep6Pricing();
      expect(controller.wizardState.currentStep, 7);

      expect(repo.saveDraftCallCount, 0);
      expect(repo.createProductCallCount, 0);
    });


    test('VARIANT backward: 7 → 6 → 5 → 3 → 2 → 1', () async {
      await controller.initWizard();
      await completeStep1(); // → 3
      controller.setProductStructure('VARIANT');
      await controller.saveAndContinue(); // → 5 (skips 4 because trackInventory=false)
      controller.addAttributeRow();
      controller.updateAttributeName(0, 'Color');
      controller.selectValues(0, ['Red']);
      await controller.generateVariants();
      for (final assignment in controller.wizardState.step5State.assignments) {
        await controller.assignBarcodeSkuAndSave(
          assignment.copyWith(sku: 'SKU-${assignment.clientCombinationKey}'),
        );
      }
      await controller.saveAndContinue(); // → 6
      await completeStep6Pricing(); // → 7
      expect(controller.wizardState.currentStep, 7);

      controller.goToPreviousApplicableStep();
      expect(controller.wizardState.currentStep, 6);
      controller.goToPreviousApplicableStep();
      expect(controller.wizardState.currentStep, 5);
      controller.goToPreviousApplicableStep();
      expect(controller.wizardState.currentStep, 3);
      controller.goToPreviousApplicableStep();
      expect(controller.wizardState.currentStep, 2);
      controller.goToPreviousApplicableStep();
      expect(controller.wizardState.currentStep, 1);
    });


    test('form values retained after Back', () async {
      await controller.initWizard();
      await completeStep1(); // → 3
      controller.setProductStructure('SIMPLE');
      controller.setTrackInventory(true);
      await controller.saveAndContinue(); // → 4

      expect(controller.wizardState.currentStep, 4);
      controller.goToPreviousApplicableStep();
      expect(controller.wizardState.currentStep, 3);
      controller.goToPreviousApplicableStep();
      expect(controller.wizardState.currentStep, 2);
      controller.goToPreviousApplicableStep();
      expect(controller.wizardState.currentStep, 1);

      expect(controller.wizardState.productName, 'Nav Product');
      expect(controller.wizardState.categoryId, 'cat-1');
      expect(controller.wizardState.productStructure, 'SIMPLE');
    });

    test('invalid form stays on same step and does not call repository',
        () async {
      await controller.initWizard();
      controller.skipScanStepForTesting(); // now at step 2
      final success = await controller.saveAndContinue();
      expect(success, isFalse);
      expect(controller.wizardState.currentStep, 2);
      expect(repo.saveDraftCallCount, 0);
      expect(repo.updateDraftCallCount, 0);
      expect(repo.createProductCallCount, 0);
    });

    test('Cancel path does not save product (dirty flag only)', () async {
      await controller.initWizard();
      controller.skipScanStepForTesting();
      controller.updateProductName('Dirty');
      expect(controller.wizardState.isDirty, isTrue);
      expect(repo.saveDraftCallCount, 0);
      expect(repo.updateDraftCallCount, 0);
      expect(repo.createProductCallCount, 0);
    });

    test('Skip on Step 3 without Product Type does not advance', () async {
      await controller.initWizard();
      await completeStep1(); // → step 3
      final skipped = await controller.skip();
      expect(skipped, isFalse);
      expect(controller.wizardState.currentStep, 3);
      expect(repo.saveDraftCallCount, 0);
    });

    test('Skip on Step 3 SIMPLE advances to Step 4 without persistence',
        () async {
      await controller.initWizard();
      await completeStep1(); // → step 3
      controller.setProductStructure('SIMPLE');
      expect(controller.canSkipCurrentStep, isTrue);
      expect(await controller.skip(), isTrue);
      // SIMPLE always requires Step 4 (Product Unit) — backend wizard-create
      // has no Track Inventory exemption for this field, so skip() must land
      // on Step 4, not skip past it.
      expect(controller.wizardState.currentStep, 4);
      expect(controller.wizardState.trackInventory, isFalse);
      expect(repo.saveDraftCallCount, 0);
    });

    test('Skip on Step 3 VARIANT advances to Step 5', () async {
      await controller.initWizard();
      await completeStep1(); // → step 3
      controller.setProductStructure('VARIANT');
      expect(await controller.skip(), isTrue);
      expect(controller.wizardState.currentStep, 5);
    });

    test('Skip on Step 3 BUNDLE advances to Step 5', () async {
      await controller.initWizard();
      await completeStep1(); // → step 3
      controller.setProductStructure('BUNDLE');
      expect(await controller.skip(), isTrue);
      expect(controller.wizardState.currentStep, 5);
      expect(controller.wizardState.trackInventory, isFalse);
    });

    test('Skip on Step 5 (after VARIANT) advances to Step 6 without matrix', () async {
      await controller.initWizard();
      await completeStep1(); // → step 3
      controller.setProductStructure('VARIANT');
      await controller.saveAndContinue(); // → 5 (skips 4)
      expect(controller.wizardState.currentStep, 5);
      expect(await controller.skip(), isTrue);
      expect(controller.wizardState.currentStep, 6);
      expect(repo.saveDraftCallCount, 0);
    });

    test('Skip on Steps 5, 6 advances without validation', () async {
      await controller.initWizard();
      await completeStep1(); // → step 3
      controller.setProductStructure('SIMPLE');
      await controller.saveAndContinue(); // → step 4 (Product Unit)
      expect(controller.wizardState.currentStep, 4);
      expect(await controller.skip(), isTrue); // → step 5 without unit validation
      expect(controller.wizardState.currentStep, 5);

      expect(await controller.skip(), isTrue);
      expect(controller.wizardState.currentStep, 6);

      expect(await controller.skip(), isTrue);
      expect(controller.wizardState.currentStep, 7);
      expect(controller.canSkipCurrentStep, isFalse);
      expect(await controller.skip(), isFalse);
      expect(repo.saveDraftCallCount, 0);
    });
  });
}


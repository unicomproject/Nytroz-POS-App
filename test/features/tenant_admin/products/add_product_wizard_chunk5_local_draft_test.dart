import 'package:flutter_test/flutter_test.dart';
import 'package:nytroz_pos/features/tenant_admin/products/data/datasources/product_wizard_draft_local_datasource.dart';
import 'package:nytroz_pos/features/tenant_admin/products/data/models/product_draft_response_dto.dart';
import 'package:nytroz_pos/features/tenant_admin/products/data/models/save_product_draft_request_dto.dart';
import 'package:nytroz_pos/features/tenant_admin/products/data/models/staged_image_response_dto.dart';
import 'package:nytroz_pos/features/tenant_admin/products/domain/entities/product_delete_result.dart';
import 'package:nytroz_pos/features/tenant_admin/products/domain/entities/product_form_data.dart';
import 'package:nytroz_pos/features/tenant_admin/products/domain/entities/product_status_update_result.dart';
import 'package:nytroz_pos/features/tenant_admin/products/domain/entities/tenant_product.dart';
import 'package:nytroz_pos/features/tenant_admin/products/domain/entities/tenant_product_create_options.dart';
import 'package:nytroz_pos/features/tenant_admin/products/domain/entities/tenant_product_detail.dart';
import 'package:nytroz_pos/features/tenant_admin/products/domain/entities/tenant_product_filter_options.dart';
import 'package:nytroz_pos/features/tenant_admin/products/domain/repositories/product_wizard_draft_local_repository.dart';
import 'package:nytroz_pos/features/tenant_admin/products/domain/repositories/tenant_product_repository.dart';
import 'package:nytroz_pos/features/tenant_admin/products/domain/services/product_list_local_draft_merger.dart';
import 'package:nytroz_pos/features/tenant_admin/products/presentation/controllers/add_product_wizard_controller.dart';

class _TrackingRepo implements TenantProductRepository {
  int saveDraftCallCount = 0;
  int updateDraftCallCount = 0;
  int createProductCallCount = 0;
  int getSetupCallCount = 0;
  int getProductByIdCallCount = 0;
  int deleteProductCallCount = 0;
  int updateProductCallCount = 0;

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
    throw StateError('createProductFromWizard must not be called in Chunk 5');
  }

  @override
  Future<ProductDraftResponseDto> getSetup(String productId) async {
    getSetupCallCount++;
    throw StateError('getSetup must not be called for local drafts');
  }

  @override
  Future<TenantProductDetail> getProductById(String productId) async {
    getProductByIdCallCount++;
    throw StateError('getProductById must not be called for local drafts');
  }

  @override
  Future<ProductDeleteResult> deleteProduct(String productId) async {
    deleteProductCallCount++;
    throw StateError('deleteProduct must not be called for local drafts');
  }

  @override
  Future<TenantProductDetail> updateProduct(
      String productId, ProductFormData request) async {
    updateProductCallCount++;
    throw StateError('updateProduct must not be called');
  }

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
  late InMemoryProductWizardDraftLocalDataSource localStore;
  late ProductWizardDraftLocalRepository draftLocal;
  late AddProductWizardController controller;

  setUp(() {
    repo = _TrackingRepo();
    localStore = InMemoryProductWizardDraftLocalDataSource();
    draftLocal = ProductWizardDraftLocalRepositoryImpl(localStore);
    controller = AddProductWizardController(repo, draftLocal: draftLocal);
  });

  Future<void> fillSimpleThroughStep5() async {
    await controller.initWizard();
    controller.updateProductName('Local Simple Draft');
    controller.updateCategory('cat-1');
    await controller.saveAndContinue();
    controller.setProductStructure('SIMPLE');
    await controller.saveAndContinue();
    controller.selectUnitModel('SINGLE_UNIT');
    controller.setProductUnit('unit-1');
    await controller.saveAndContinue();
    controller.updateSimpleBaseSku('LOCAL-SIMPLE-001');
  }

  group('Chunk 5 local Save Draft', () {
    test('1/2/3. first Save Draft creates localDraftId via local persistence',
        () async {
      await fillSimpleThroughStep5();
      expect(await controller.saveDraft(), isTrue);
      final id = controller.wizardState.localDraftId;
      expect(id, isNotNull);
      expect(id!.startsWith('local-'), isTrue);
      expect(await localStore.getDraft(id), isNotNull);
      expect(repo.saveDraftCallCount, 0);
      expect(repo.updateDraftCallCount, 0);
      expect(repo.createProductCallCount, 0);
      expect(repo.getSetupCallCount, 0);
    });

    test('4/5/6. Product List merge shows DRAFT without fake productId',
        () async {
      await fillSimpleThroughStep5();
      await controller.saveDraft();
      final drafts = await draftLocal.getAllDrafts();
      final backend = TenantProductListResult(
        items: [
          const TenantProduct(
            id: 'backend-1',
            productCode: 'B1',
            name: 'Backend Product',
            sku: 'B-SKU',
            status: 'ACTIVE',
          ),
        ],
        page: 1,
        pageSize: 6,
        totalCount: 1,
        catalogTotalCount: 1,
      );
      final merged = ProductListLocalDraftMerger.merge(
        backend: backend,
        drafts: drafts,
        query: const TenantProductListQuery(pageNumber: 1, pageSize: 6),
      );
      expect(merged.items.length, 2);
      expect(merged.items.first.isLocalDraft, isTrue);
      expect(merged.items.first.status, 'DRAFT');
      expect(merged.items.first.id, controller.wizardState.localDraftId);
      expect(merged.items.first.id.startsWith('local-'), isTrue);
      expect(merged.totalCount, 1); // backend count unchanged
      expect(merged.items.last.id, 'backend-1');
      expect(merged.items.last.isLocalDraft, isFalse);
    });

    test('7/8/9/10. reopen SIMPLE Draft restores step and state', () async {
      await fillSimpleThroughStep5();
      await controller.saveDraft();
      final id = controller.wizardState.localDraftId!;

      final resumed = AddProductWizardController(repo, draftLocal: draftLocal);
      await resumed.initWizard(resumeLocalDraftId: id);

      expect(resumed.wizardState.localDraftId, id);
      expect(resumed.wizardState.currentStep, 5);
      expect(resumed.wizardState.productName, 'Local Simple Draft');
      expect(resumed.wizardState.productStructure, 'SIMPLE');
      expect(resumed.wizardState.productUnitId, 'unit-1');
      expect(resumed.wizardState.step5State.baseSku, 'LOCAL-SIMPLE-001');
      expect(resumed.wizardState.productId, isNull);
      expect(repo.getSetupCallCount, 0);
      expect(repo.getProductByIdCallCount, 0);
    });

    test('11. Step 6 pricing/tax restores', () async {
      await fillSimpleThroughStep5();
      await controller.saveAndContinue(); // → 6
      controller.updateCostPrice(100);
      controller.updateStandardSellingPrice(150);
      controller.updateDiscountPrice(140);
      controller.updateTaxId('tax-1', taxRate: 15, taxName: 'VAT 15%');
      await controller.saveDraft();
      final id = controller.wizardState.localDraftId!;

      final resumed = AddProductWizardController(repo, draftLocal: draftLocal);
      await resumed.initWizard(resumeLocalDraftId: id);
      expect(resumed.wizardState.currentStep, 6);
      expect(resumed.wizardState.costPrice, 100);
      expect(resumed.wizardState.standardSellingPrice, 150);
      expect(resumed.wizardState.discountPrice, 140);
      expect(resumed.wizardState.taxId, 'tax-1');
      expect(resumed.wizardState.taxName, 'VAT 15%');
      expect(resumed.wizardState.taxRate, 15);
      expect(resumed.wizardState.taxExclusive, isTrue);
    });

    test('12/13. second Save Draft updates same localDraftId (no duplicate)',
        () async {
      await fillSimpleThroughStep5();
      await controller.saveDraft();
      final id = controller.wizardState.localDraftId!;
      controller.updateSimpleBaseSku('LOCAL-SIMPLE-002');
      await controller.saveDraft();
      expect(controller.wizardState.localDraftId, id);
      final all = await draftLocal.getAllDrafts();
      expect(all.length, 1);
      expect(all.first.localDraftId, id);
      expect(all.first.wizardState.step5State.baseSku, 'LOCAL-SIMPLE-002');
    });

    test(
        '14/15/16/17/18. VARIANT draft restore + clientCombinationKey stability',
        () async {
      await controller.initWizard();
      controller.updateProductName('Variant Draft');
      controller.updateCategory('cat-1');
      await controller.saveAndContinue();
      controller.setProductStructure('VARIANT');
      await controller.saveAndContinue();
      expect(controller.wizardState.currentStep, 4);

      controller.addAttributeRow();
      controller.updateAttributeName(0, 'Color');
      controller.selectValues(0, ['Red', 'Blue']);
      controller.addAttributeRow();
      controller.updateAttributeName(1, 'Size');
      controller.selectValues(1, ['Small', 'Medium']);
      await controller.generateVariants();
      expect(controller.wizardState.step4State.generatedVariants.length, 4);

      final keysBefore = controller.wizardState.step4State.generatedVariants
          .map((v) => v.clientCombinationKey)
          .toList();
      await controller.saveAndContinue();
      var i = 0;
      for (final a in List.of(controller.wizardState.step5State.assignments)) {
        i++;
        await controller.assignBarcodeSkuAndSave(
          a.copyWith(sku: 'TEST-$i', barcode: 'BC-$i'),
        );
      }
      final skuByKey = {
        for (final a in controller.wizardState.step5State.assignments)
          a.clientCombinationKey: a.sku
      };
      await controller.saveDraft();
      final id = controller.wizardState.localDraftId!;

      final resumed = AddProductWizardController(repo, draftLocal: draftLocal);
      await resumed.initWizard(resumeLocalDraftId: id);
      expect(resumed.wizardState.currentStep, 5);
      expect(resumed.isStepApplicable(3), isFalse);
      expect(resumed.wizardState.currentStep, isNot(3));
      expect(resumed.wizardState.step4State.generatedVariants.length, 4);
      final keysAfter = resumed.wizardState.step4State.generatedVariants
          .map((v) => v.clientCombinationKey)
          .toList();
      expect(keysAfter, keysBefore);
      for (final entry in skuByKey.entries) {
        final match = resumed.wizardState.step5State.assignments
            .firstWhere((a) => a.clientCombinationKey == entry.key);
        expect(match.sku, entry.value);
        expect(match.productVariantId, isNull);
      }
    });

    test('19. Cancel does not delete stored Draft', () async {
      await fillSimpleThroughStep5();
      await controller.saveDraft();
      final id = controller.wizardState.localDraftId!;
      expect(await localStore.getDraft(id), isNotNull);
      // Cancel only navigates — does not call deleteDraft.
      expect(await draftLocal.getAllDrafts(), hasLength(1));
    });

    test('20. local Draft never invokes backend Product detail/delete/update',
        () async {
      await fillSimpleThroughStep5();
      await controller.saveDraft();
      final id = controller.wizardState.localDraftId!;
      final resumed = AddProductWizardController(repo, draftLocal: draftLocal);
      await resumed.initWizard(resumeLocalDraftId: id);
      await draftLocal.deleteDraft(id);
      expect(repo.getSetupCallCount, 0);
      expect(repo.getProductByIdCallCount, 0);
      expect(repo.deleteProductCallCount, 0);
      expect(repo.updateProductCallCount, 0);
      expect(repo.saveDraftCallCount, 0);
    });

    test('21. backend real Product row remains distinguishable', () async {
      await fillSimpleThroughStep5();
      await controller.saveDraft();
      final draft = (await draftLocal.getAllDrafts()).first;
      final draftRow = ProductListLocalDraftMerger.toListRow(draft);
      const backend = TenantProduct(
        id: 'guid-product',
        productCode: 'P1',
        name: 'Real',
        sku: 'SKU',
        status: 'ACTIVE',
      );
      expect(backend.isLocalDraft, isFalse);
      expect(draftRow.isLocalDraft, isTrue);
      expect(draftRow.status, 'DRAFT');
      expect(draftRow.id, draft.localDraftId);
    });

    test('22. SIMPLE navigation regression', () async {
      await controller.initWizard();
      controller.updateProductName('Simple Still');
      controller.updateCategory('cat-1');
      await controller.saveAndContinue();
      controller.setProductStructure('SIMPLE');
      await controller.saveAndContinue();
      expect(controller.wizardState.currentStep, 3);
      controller.selectUnitModel('SINGLE_UNIT');
      controller.setProductUnit('unit-1');
      await controller.saveAndContinue();
      expect(controller.wizardState.currentStep, 5);
    });

    test('23. VARIANT navigation regression', () async {
      await controller.initWizard();
      controller.updateProductName('Variant Still');
      controller.updateCategory('cat-1');
      await controller.saveAndContinue();
      controller.setProductStructure('VARIANT');
      await controller.saveAndContinue();
      expect(controller.wizardState.currentStep, 4);
      expect(controller.isStepApplicable(3), isFalse);
    });

    test('24. Save & Continue remains zero Product persistence', () async {
      await fillSimpleThroughStep5();
      await controller.saveAndContinue();
      controller.updateCostPrice(10);
      controller.updateStandardSellingPrice(20);
      controller.updateTaxId('tax-1', taxRate: 15, taxName: 'VAT 15%');
      await controller.saveAndContinue();
      expect(controller.wizardState.currentStep, 7);
      expect(repo.saveDraftCallCount, 0);
      expect(repo.createProductCallCount, 0);
    });

    test('early-step Save Draft does not require full Product validation',
        () async {
      await controller.initWizard();
      controller.updateProductName('Early Draft');
      // No category — Save & Continue would fail; Save Draft must succeed.
      expect(await controller.saveDraft(), isTrue);
      expect(controller.wizardState.currentStep, 1);
      final draft =
          await localStore.getDraft(controller.wizardState.localDraftId!);
      expect(draft!.productName, 'Early Draft');
    });

    test('stale tax identity is preserved on restore', () async {
      await fillSimpleThroughStep5();
      await controller.saveAndContinue();
      controller.updateTaxId('deleted-tax', taxRate: 9, taxName: 'Gone Tax');
      await controller.saveDraft();
      final id = controller.wizardState.localDraftId!;
      final resumed = AddProductWizardController(repo, draftLocal: draftLocal);
      await resumed.initWizard(resumeLocalDraftId: id);
      expect(resumed.wizardState.taxId, 'deleted-tax');
      expect(resumed.wizardState.taxName, 'Gone Tax');
      expect(resumed.wizardState.taxRate, 9);
    });
  });
}

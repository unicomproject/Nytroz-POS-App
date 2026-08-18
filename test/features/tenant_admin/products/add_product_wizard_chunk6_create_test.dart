import 'package:flutter_test/flutter_test.dart';
import 'package:nytroz_pos/features/tenant_admin/products/data/datasources/product_wizard_draft_local_datasource.dart';
import 'package:nytroz_pos/features/tenant_admin/products/data/mappers/wizard_product_create_mapper.dart';
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
import 'package:nytroz_pos/features/tenant_admin/products/presentation/controllers/add_product_wizard_controller.dart';

class _CreateTrackingRepo implements TenantProductRepository {
  int createProductCallCount = 0;
  int createFromWizardCallCount = 0;
  int saveDraftCallCount = 0;
  int updateDraftCallCount = 0;
  Map<String, dynamic>? lastWizardPayload;
  bool failNextCreate = false;
  String? failMessage;

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
  Future<ProductCreateResult> createProduct(ProductFormData request) async {
    createProductCallCount++;
    throw StateError('legacy createProduct must not be used by wizard');
  }

  @override
  Future<ProductCreateResult> createProductFromWizard(
      Map<String, dynamic> wizardCreatePayload) async {
    createFromWizardCallCount++;
    lastWizardPayload = wizardCreatePayload;
    if (failNextCreate) {
      throw StateError(failMessage ?? 'create failed');
    }
    return ProductCreateResult(
      id: 'prod-$createFromWizardCallCount',
      productName: wizardCreatePayload['productName']?.toString() ?? '',
      sku: 'SKU',
      status: 'ACTIVE',
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
  late _CreateTrackingRepo repo;
  late InMemoryProductWizardDraftLocalDataSource localStore;
  late ProductWizardDraftLocalRepository draftLocal;
  late AddProductWizardController controller;

  setUp(() {
    repo = _CreateTrackingRepo();
    localStore = InMemoryProductWizardDraftLocalDataSource();
    draftLocal = ProductWizardDraftLocalRepositoryImpl(localStore);
    controller = AddProductWizardController(repo, draftLocal: draftLocal);
  });

  Future<void> fillSimpleToStep7() async {
    await controller.initWizard();
    controller.updateProductName('Create Simple Product');
    controller.updateCategory('cat-1');
    await controller.saveAndContinue();
    controller.setProductStructure('SIMPLE');
    await controller.saveAndContinue();
    controller.selectUnitModel('SINGLE_UNIT');
    controller.setProductUnit('unit-1');
    await controller.saveAndContinue();
    controller.updateSimpleBaseSku('CREATE-SIMPLE-001');
    await controller.saveAndContinue();
    controller.updateCostPrice(100);
    controller.updateStandardSellingPrice(150);
    controller.updateDiscountPrice(140);
    controller.updateTaxId('tax-1', taxRate: 15, taxName: 'VAT 15%');
    await controller.saveAndContinue();
    expect(controller.wizardState.currentStep, 7);
  }

  group('Chunk 6 Create Product', () {
    test('1/4/5/6. Create uses wizard state; SIMPLE payload shape', () async {
      await fillSimpleToStep7();
      final payload = WizardProductCreateMapper.toWizardCreateJson(
        controller.wizardState,
        idempotencyKey: 'idem-1',
      );
      expect(payload['productStructure'], 'SIMPLE');
      expect(payload['unitModel'], 'SINGLE_UNIT');
      expect(payload.containsKey('variantConfiguration'), isFalse);
      final barcode = payload['barcodeSkuConfiguration'] as Map;
      final assignments = barcode['assignments'] as List;
      expect(assignments, isNotEmpty);
      expect(
        (assignments.first as Map)['clientCombinationKey'],
        'SIMPLE_DEFAULT',
      );
      expect((assignments.first as Map)['productVariantId'], isNull);
      expect(payload['pricingTax'], isA<Map>());
      expect((payload['pricingTax'] as Map)['taxClassId'], 'tax-1');
    });

    test('2/3. double submit ignored while submitting; one create call',
        () async {
      await fillSimpleToStep7();
      final first = controller.createProductFromWizard();
      final second = controller.createProductFromWizard();
      expect(await first, isTrue);
      expect(await second, isFalse);
      expect(repo.createFromWizardCallCount, 1);
      expect(repo.createProductCallCount, 0);
      expect(repo.saveDraftCallCount, 0);
      expect(repo.updateDraftCallCount, 0);
    });

    test('7/8/9. VARIANT payload has variants + clientCombinationKeys',
        () async {
      await controller.initWizard();
      controller.updateProductName('Create Variant Product');
      controller.updateCategory('cat-1');
      await controller.saveAndContinue();
      controller.setProductStructure('VARIANT');
      await controller.saveAndContinue();
      controller.addAttributeRow();
      controller.updateAttributeName(0, 'Color');
      controller.selectValues(0, ['Red', 'Blue']);
      await controller.generateVariants();
      await controller.saveAndContinue();
      for (final a in List.of(controller.wizardState.step5State.assignments)) {
        await controller.assignBarcodeSkuAndSave(
          a.copyWith(sku: 'V-${a.clientCombinationKey.hashCode.abs()}'),
        );
      }
      await controller.saveAndContinue();
      controller.updateCostPrice(10);
      controller.updateStandardSellingPrice(20);
      controller.updateTaxId('tax-1', taxRate: 15, taxName: 'VAT 15%');
      await controller.saveAndContinue();

      final payload = WizardProductCreateMapper.toWizardCreateJson(
        controller.wizardState,
      );
      expect(payload['productStructure'], 'VARIANT');
      expect(payload.containsKey('unitModel'), isFalse);
      final vc = payload['variantConfiguration'] as Map;
      final variants = vc['variants'] as List;
      expect(variants.length, 2);
      for (final v in variants) {
        expect((v as Map)['clientCombinationKey'], isNotEmpty);
        expect(v['included'], isTrue);
      }
      final assignments =
          (payload['barcodeSkuConfiguration'] as Map)['assignments'] as List;
      expect(assignments.length, 2);
      for (final a in assignments) {
        expect((a as Map)['clientCombinationKey'], isNotEmpty);
        expect(a['productVariantId'], isNull);
        expect(a['sku'], isNotEmpty);
      }
    });

    test('10/11/12. successful Create deletes local Draft', () async {
      await fillSimpleToStep7();
      await controller.saveDraft();
      final draftId = controller.wizardState.localDraftId!;
      expect(await localStore.getDraft(draftId), isNotNull);

      expect(await controller.createProductFromWizard(), isTrue);
      expect(await localStore.getDraft(draftId), isNull);
      expect(controller.wizardState.productId, isNotNull);
      expect(controller.wizardState.localDraftId, isNull);
      expect(repo.createFromWizardCallCount, 1);
    });

    test('13/14/15. failed Create preserves draft and wizard state', () async {
      await fillSimpleToStep7();
      await controller.saveDraft();
      final draftId = controller.wizardState.localDraftId!;
      repo.failNextCreate = true;
      repo.failMessage = 'duplicate sku';

      expect(await controller.createProductFromWizard(), isFalse);
      expect(controller.wizardState.currentStep, 7);
      expect(controller.wizardState.productName, 'Create Simple Product');
      expect(await localStore.getDraft(draftId), isNotNull);
      expect(controller.wizardState.pageError, contains('duplicate sku'));
    });

    test('16. no old backend draft APIs called on create', () async {
      await fillSimpleToStep7();
      await controller.createProductFromWizard();
      expect(repo.saveDraftCallCount, 0);
      expect(repo.updateDraftCallCount, 0);
      expect(repo.createProductCallCount, 0);
      expect(repo.createFromWizardCallCount, 1);
    });

    test('17. SIMPLE navigation regression still reaches Step 7', () async {
      await fillSimpleToStep7();
      expect(controller.wizardState.currentStep, 7);
      expect(controller.isStepApplicable(4), isFalse);
    });

    test('18. VARIANT navigation regression still reaches Step 7', () async {
      await controller.initWizard();
      controller.updateProductName('Variant Nav');
      controller.updateCategory('cat-1');
      await controller.saveAndContinue();
      controller.setProductStructure('VARIANT');
      await controller.saveAndContinue();
      expect(controller.wizardState.currentStep, 4);
      expect(controller.isStepApplicable(3), isFalse);
    });
  });
}

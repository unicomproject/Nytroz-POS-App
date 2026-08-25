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
import 'package:nytroz_pos/features/tenant_admin/products/presentation/controllers/add_product_wizard_controller.dart';

class FakeTenantProductRepository implements TenantProductRepository {
  SaveProductDraftRequestDto? lastDraftRequest;
  int saveDraftCallCount = 0;
  int updateDraftCallCount = 0;
  int createProductCallCount = 0;
  int updateProductCallCount = 0;

  ProductDraftResponseDto storedDraft = const ProductDraftResponseDto(
    productId: 'prod-123',
    productName: 'Existing Headset',
    productCode: 'SKU-001',
    status: 'DRAFT',
    currentSetupStep: 1,
    rowVersion: 2,
    categoryId: 'cat-1',
    brandId: 'brand-1',
    posSellable: true,
    trackInventory: true,
    allowOnlineSale: true,
    images: [],
  );

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
    lastDraftRequest = request;
    storedDraft = ProductDraftResponseDto(
      productId: 'prod-123',
      productName: request.productName ?? 'Untitled Product',
      productCode: request.productCode,
      status: 'DRAFT',
      currentSetupStep: request.advanceStep
          ? request.currentSetupStep + 1
          : request.currentSetupStep,
      rowVersion: 1,
      categoryId: request.categoryId,
      brandId: request.brandId,
      shortDescription: request.shortDescription,
      longDescription: request.longDescription,
      posSellable: request.posSellable,
      trackInventory: request.trackInventory,
      allowOnlineSale: request.allowOnlineSale,
      images: const [],
    );
    return storedDraft;
  }

  @override
  Future<ProductDraftResponseDto> updateDraft(
      String productId, SaveProductDraftRequestDto request) async {
    updateDraftCallCount++;
    lastDraftRequest = request;
    storedDraft = ProductDraftResponseDto(
      productId: productId,
      productName: request.productName ?? 'Untitled Product',
      productCode: request.productCode,
      status: 'DRAFT',
      currentSetupStep: request.advanceStep
          ? request.currentSetupStep + 1
          : request.currentSetupStep,
      rowVersion: (request.expectedRowVersion ?? 0) + 1,
      categoryId: request.categoryId,
      brandId: request.brandId,
      shortDescription: request.shortDescription,
      longDescription: request.longDescription,
      posSellable: request.posSellable,
      trackInventory: request.trackInventory,
      allowOnlineSale: request.allowOnlineSale,
      images: const [],
    );
    return storedDraft;
  }

  @override
  Future<ProductDraftResponseDto> getSetup(String productId) async {
    return storedDraft;
  }

  @override
  Future<StagedImageResponseDto> stageImage(
      List<int> bytes, String fileName, String mimeType) async {
    return StagedImageResponseDto(
      mediaAssetId: 'asset-${DateTime.now().millisecondsSinceEpoch}',
      publicUrl: 'https://cdn.example.com/$fileName',
      fileName: fileName,
      mimeType: mimeType,
      fileSizeBytes: bytes.length,
      createdAt: DateTime.now(),
      status: 'STAGED',
    );
  }

  @override
  Future<ProductImageResponseDto> uploadProductImage(String productId,
      List<int> bytes, String fileName, String mimeType) async {
    return const ProductImageResponseDto(
      productImageId: 'img-1',
      imageUrl: 'https://cdn.example.com/photo.png',
      imagePurpose: 'GALLERY',
      sortOrder: 1,
      isPrimaryImage: true,
    );
  }

  @override
  Future<ProductDraftResponseDto> deleteProductImage(
      String productId, String productImageId) async {
    return const ProductDraftResponseDto(
      productId: 'prod-123',
      productName: 'Existing Headset',
      status: 'DRAFT',
      currentSetupStep: 1,
      rowVersion: 3,
      posSellable: true,
      trackInventory: true,
      allowOnlineSale: true,
      images: [],
    );
  }

  @override
  Future<ProductDraftResponseDto> reorderProductImages(
      String productId,
      int expectedRowVersion,
      String? primaryProductImageId,
      List<Map<String, dynamic>> items) async {
    return ProductDraftResponseDto(
      productId: productId,
      productName: 'Existing Headset',
      status: 'DRAFT',
      currentSetupStep: 1,
      rowVersion: expectedRowVersion + 1,
      posSellable: true,
      trackInventory: true,
      allowOnlineSale: true,
      images: const [],
    );
  }

  @override
  Future<ProductDraftResponseDto> replaceProductImages(String productId,
      int expectedRowVersion, List<String> stagedMediaAssetIds) async {
    return ProductDraftResponseDto(
      productId: productId,
      productName: 'Existing Headset',
      status: 'DRAFT',
      currentSetupStep: 1,
      rowVersion: expectedRowVersion + 1,
      posSellable: true,
      trackInventory: true,
      allowOnlineSale: true,
      images: const [],
    );
  }

  @override
  Future<ProductCreateResult> createProduct(ProductFormData request) {
    createProductCallCount++;
    throw UnimplementedError();
  }

  @override
  Future<ProductCreateResult> createProductFromWizard(
      Map<String, dynamic> wizardCreatePayload) {
    createProductCallCount++;
    throw UnimplementedError();
  }

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
  Future<TenantProductDetail> updateProduct(
      String productId, ProductFormData request) {
    updateProductCallCount++;
    throw UnimplementedError();
  }
  @override
  Future<ProductStatusUpdateResult> updateProductStatus(
          String productId, String status) =>
      throw UnimplementedError();
}

void main() {
  group('AddProductWizardController Tests', () {
    late FakeTenantProductRepository repo;
    late AddProductWizardController controller;

    setUp(() {
      repo = FakeTenantProductRepository();
      controller = AddProductWizardController(
        repo,
        draftLocal: ProductWizardDraftLocalRepositoryImpl(
          InMemoryProductWizardDraftLocalDataSource(),
        ),
      );
    });

    test('initWizard loads create options', () async {
      await controller.initWizard();
      expect(controller.wizardState.createOptions, isNotNull);
      expect(controller.wizardState.createOptions!.categories.length, 1);
    });

    test('Save Draft is frontend-local and does not call draft APIs', () async {
      await controller.initWizard();
      controller.updateProductName('Local Draft');
      final success = await controller.saveDraft();

      expect(success, true);
      expect(controller.wizardState.localDraftId, isNotNull);
      expect(controller.wizardState.productId, isNull);
      expect(repo.saveDraftCallCount, 0);
      expect(repo.updateDraftCallCount, 0);
      expect(repo.lastDraftRequest, isNull);
    });

    test('Save & Continue rejects missing Product Name or Category', () async {
      await controller.initWizard();
      controller.updateProductName('');
      controller.updateCategory(null);

      final success = await controller.saveAndContinue();

      expect(success, false);
      expect(
          controller.wizardState.fieldErrors.containsKey('productName'), true);
      expect(
          controller.wizardState.fieldErrors.containsKey('categoryId'), true);
      expect(controller.wizardState.currentStep, 1);
      expect(repo.saveDraftCallCount, 0);
    });

    test(
        'Save & Continue succeeds with Product Name and Category (Brand optional)',
        () async {
      await controller.initWizard();
      controller.updateProductName('Gaming Mouse');
      controller.updateCategory('cat-1');
      controller.updateBrand(null); // Optional

      final success = await controller.saveAndContinue();

      expect(success, true);
      expect(controller.wizardState.currentStep, 2);
      expect(repo.saveDraftCallCount, 0);
      expect(repo.updateDraftCallCount, 0);
      expect(repo.lastDraftRequest, isNull);
    });

    test('Staging image enforces 10 count & 5MB limit & format check',
        () async {
      await controller.initWizard();

      // Test format validation failure
      final invalidFormatSuccess = await controller.stageOrUploadImage(
        [1, 2, 3],
        'file.pdf',
        'application/pdf',
      );
      expect(invalidFormatSuccess, false);
      expect(controller.wizardState.pageError,
          contains('Unsupported image format'));

      // Test 5MB size limit failure
      final oversizedBytes = List<int>.filled(5242881, 0);
      final oversizedSuccess = await controller.stageOrUploadImage(
        oversizedBytes,
        'image.png',
        'image/png',
      );
      expect(oversizedSuccess, false);
      expect(controller.wizardState.pageError, contains('5MB'));

      // Valid image staging
      final validSuccess = await controller.stageOrUploadImage(
        [1, 2, 3, 4],
        'photo.png',
        'image/png',
      );
      expect(validSuccess, true);
      expect(controller.wizardState.stagedMediaAssets.length, 1);
      expect(controller.wizardState.stagedMediaAssets.first.isPrimary, true);
    });

    test(
        'Step 2 tracking toggle logic enforces canonical dependencies & mutual exclusivity',
        () {
      controller.setTrackInventory(true);
      expect(controller.wizardState.trackInventory, true);

      controller.setBatchTracking(true);
      expect(controller.wizardState.batchTracking, true);

      controller.setExpiryTracking(true);
      expect(controller.wizardState.expiryTracking, true);

      // Enabling serial tracking forces batch and expiry to false
      controller.setSerialTracking(true);
      expect(controller.wizardState.serialTracking, true);
      expect(controller.wizardState.batchTracking, false);
      expect(controller.wizardState.expiryTracking, false);

      // Toggling track inventory OFF clears all sub-tracking flags
      controller.setTrackInventory(false);
      expect(controller.wizardState.trackInventory, false);
      expect(controller.wizardState.batchTracking, false);
      expect(controller.wizardState.expiryTracking, false);
      expect(controller.wizardState.serialTracking, false);
    });

    test('Bundle structure forces all inventory tracking flags to false', () {
      controller.setProductStructure('BUNDLE');
      expect(controller.wizardState.productStructure, 'BUNDLE');
      expect(controller.wizardState.productStructureConfirmed, true);
      expect(controller.wizardState.trackInventory, false);
      expect(controller.wizardState.batchTracking, false);
      expect(controller.wizardState.expiryTracking, false);
      expect(controller.wizardState.serialTracking, false);
    });

    test(
        'Save & Continue on Step 2 VARIANT advances to Step 4 without draft API',
        () async {
      await controller.initWizard();
      controller.updateProductName('Wireless Headphones');
      controller.updateCategory('cat-1');
      await controller.saveAndContinue(); // Move to Step 2

      expect(controller.wizardState.currentStep, 2);

      controller.setProductStructure('VARIANT');
      controller.setTrackInventory(true);
      controller.setBatchTracking(true);

      final success = await controller.saveAndContinue();
      expect(success, true);
      expect(controller.wizardState.currentStep, 4);
      expect(repo.saveDraftCallCount, 0);
      expect(repo.updateDraftCallCount, 0);
    });

    test('loadExistingDraft hydrates draft and restores currentSetupStep',
        () async {
      repo.storedDraft = const ProductDraftResponseDto(
        productId: 'prod-123',
        productName: 'Existing Headset',
        status: 'DRAFT',
        currentSetupStep: 4,
        rowVersion: 2,
        categoryId: 'cat-1',
        posSellable: true,
        trackInventory: true,
        allowOnlineSale: true,
        images: [],
      );
      await controller.loadExistingDraft('prod-123');

      expect(controller.wizardState.productId, 'prod-123');
      expect(controller.wizardState.currentStep, 4);
    });

    test(
        'initWizard preserves active session step state when resumeProductId matches',
        () async {
      repo.storedDraft = const ProductDraftResponseDto(
        productId: 'prod-123',
        productName: 'Existing Headset',
        status: 'DRAFT',
        currentSetupStep: 3,
        rowVersion: 2,
        categoryId: 'cat-1',
        posSellable: true,
        trackInventory: true,
        allowOnlineSale: true,
        images: [],
      );
      await controller.loadExistingDraft('prod-123');
      expect(controller.wizardState.currentStep, 3);

      // Subsequent initWizard call should preserve step 3 instead of resetting to 1
      await controller.initWizard(resumeProductId: 'prod-123');
      expect(controller.wizardState.currentStep, 3);
    });

    test('Save Draft keeps staged media in local wizard state', () async {
      await controller.initWizard();
      controller.updateProductName('Test Product');
      controller.updateCategory('cat-1');

      await controller.stageOrUploadImage([1, 2, 3], 'test.png', 'image/png');
      expect(controller.wizardState.stagedMediaAssets.length, 1);

      final success = await controller.saveDraft();
      expect(success, true);
      expect(controller.wizardState.stagedMediaAssets.length, 1);
      expect(repo.saveDraftCallCount, 0);
    });
  });
}

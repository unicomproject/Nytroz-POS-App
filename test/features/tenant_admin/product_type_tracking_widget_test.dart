// ignore_for_file: invalid_annotation_target
import 'package:nytroz_pos/features/tenant_admin/products/data/dtos/product_setup_scan_dtos.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nytroz_pos/features/tenant_admin/products/data/dtos/product_draft_response_dto.dart';
import 'package:nytroz_pos/features/tenant_admin/products/data/dtos/save_product_draft_request_dto.dart';
import 'package:nytroz_pos/features/tenant_admin/products/data/dtos/staged_image_response_dto.dart';
import 'package:nytroz_pos/features/tenant_admin/products/domain/entities/add_product_wizard_state.dart';
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
import 'package:nytroz_pos/features/tenant_admin/products/presentation/widgets/product_type_tracking/product_type_tracking.dart';

class WidgetTestFakeRepository implements TenantProductRepository {
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
    return SkuCandidateResponseDto(candidate: 'AUTO-000001', reserved: false);
  }

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
    return ProductDraftResponseDto(
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
      posSellable: request.posSellable,
      trackInventory: request.trackInventory,
      allowOnlineSale: request.allowOnlineSale,
      productStructure: request.productStructure ?? 'SIMPLE',
      batchTracking: request.batchTracking ?? false,
      expiryTracking: request.expiryTracking ?? false,
      serialTracking: request.serialTracking ?? false,
      images: const [],
    );
  }

  @override
  Future<ProductDraftResponseDto> updateDraft(
      String productId, SaveProductDraftRequestDto request) async {
    return saveDraft(request);
  }

  @override
  Future<ProductDraftResponseDto> getSetup(String productId) async {
    return const ProductDraftResponseDto(
      productId: 'prod-123',
      productName: 'Existing Headset',
      productCode: 'SKU-001',
      status: 'DRAFT',
      currentSetupStep: 2,
      rowVersion: 2,
      categoryId: 'cat-1',
      brandId: 'brand-1',
      posSellable: true,
      trackInventory: true,
      allowOnlineSale: true,
      productStructure: 'SIMPLE',
      batchTracking: false,
      expiryTracking: false,
      serialTracking: false,
      images: [],
    );
  }

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
          int rowVersion,
          String? primaryImageId,
          List<Map<String, dynamic>> items) =>
      throw UnimplementedError();
  @override
  Future<ProductDraftResponseDto> replaceProductImages(String productId,
          int expectedRowVersion, List<String> stagedMediaAssetIds) =>
      throw UnimplementedError();
  @override
  Future<TenantProductSummary> getProductSummary() =>
      throw UnimplementedError();
  @override
  Future<TenantProductListResult> getProducts({
    required TenantProductListQuery query,
  }) =>
      throw UnimplementedError();
  @override
  Future<TenantProductFilterOptions> getProductFilterOptions() =>
      throw UnimplementedError();
  @override
  Future<TenantProductDetail> getProductById(String productId) =>
      throw UnimplementedError();
  @override
  Future<ProductStatusUpdateResult> updateProductStatus(
          String productId, String status) =>
      throw UnimplementedError();
  @override
  Future<ProductCreateResponseDto> duplicateProduct(String productId) =>
      throw UnimplementedError();
  @override
  Future<ProductDeleteResult> deleteProduct(String productId) =>
      throw UnimplementedError();
  @override
  Future<ProductCreateResult> createProduct(ProductFormData request) =>
      throw UnimplementedError();
  @override
  Future<ProductCreateResult> createProductFromWizard(
          Map<String, dynamic> wizardCreatePayload) =>
      throw UnimplementedError();
  @override
  Future<TenantProductDetail> updateProduct(
          String productId, ProductFormData request) =>
      throw UnimplementedError();
}

@Skip('Needs UI refactor update for 6-step flow')
void main() {
  late WidgetTestFakeRepository repository;
  late AddProductWizardController controller;

  setUp(() {
    repository = WidgetTestFakeRepository();
    controller = AddProductWizardController(repository);
  });

  tearDown(() {
    if (controller.mounted) controller.dispose();
  });

  Widget buildTestWidget(AddProductWizardState state) {
    return MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: ProductTypeTracking(
            state: state,
            controller: controller,
          ),
        ),
      ),
    );
  }

  group('ProductTypeTracking Widget Tests', () {
    testWidgets('renders exactly 3 tracking cards and no duplicate skip UI', (tester) async {
      await tester.pumpWidget(buildTestWidget(const AddProductWizardState(
        productStructureConfirmed: true,
        trackingInternalStep: 1,
      )));

      expect(find.text('Quantity'), findsOneWidget);
      expect(find.text('Batch / Lot'), findsOneWidget);
      expect(find.text('Batch + Expiry'), findsOneWidget);

      expect(find.text('No Tracking'), findsNothing);
      expect(find.text('Skip for Now'), findsNothing);
    });

    testWidgets('tracking card selection updates controller state',
        (tester) async {
      await tester.pumpWidget(buildTestWidget(const AddProductWizardState(
        productStructureConfirmed: true,
        trackingInternalStep: 1,
      )));

      // Initially no tracking method is selected in empty state
      // (The UI might default to something, but let's test tapping)
      await tester.tap(find.text('Batch / Lot'));
      await tester.pumpAndSettle();

      expect(controller.wizardState.trackingMethod, 'BATCH');
      
      await tester.tap(find.text('Quantity'));
      await tester.pumpAndSettle();

      expect(controller.wizardState.trackingMethod, 'QUANTITY');

      await tester.tap(find.text('Batch + Expiry'));
      await tester.pumpAndSettle();

      expect(controller.wizardState.trackingMethod, 'BATCH_EXPIRY');

      // flush timer
      await tester.pump(const Duration(seconds: 1));
    });
  });
}

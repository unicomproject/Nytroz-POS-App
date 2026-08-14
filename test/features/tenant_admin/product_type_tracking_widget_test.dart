import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nytroz_pos/features/tenant_admin/products/data/models/product_draft_response_dto.dart';
import 'package:nytroz_pos/features/tenant_admin/products/data/models/save_product_draft_request_dto.dart';
import 'package:nytroz_pos/features/tenant_admin/products/data/models/staged_image_response_dto.dart';
import 'package:nytroz_pos/features/tenant_admin/products/domain/entities/add_product_wizard_state.dart';
import 'package:nytroz_pos/features/tenant_admin/products/domain/entities/product_delete_result.dart';
import 'package:nytroz_pos/features/tenant_admin/products/domain/entities/product_form_data.dart';
import 'package:nytroz_pos/features/tenant_admin/products/domain/entities/product_status_update_result.dart';
import 'package:nytroz_pos/features/tenant_admin/products/domain/entities/tenant_product.dart';
import 'package:nytroz_pos/features/tenant_admin/products/domain/entities/tenant_product_create_options.dart';
import 'package:nytroz_pos/features/tenant_admin/products/domain/entities/tenant_product_detail.dart';
import 'package:nytroz_pos/features/tenant_admin/products/domain/entities/tenant_product_filter_options.dart';
import 'package:nytroz_pos/features/tenant_admin/products/domain/repositories/tenant_product_repository.dart';
import 'package:nytroz_pos/features/tenant_admin/products/presentation/controllers/add_product_wizard_controller.dart';
import 'package:nytroz_pos/features/tenant_admin/products/presentation/widgets/product_type_tracking.dart';

class WidgetTestFakeRepository implements TenantProductRepository {
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
  Future<ProductDeleteResult> deleteProduct(String productId) =>
      throw UnimplementedError();
  @override
  Future<ProductCreateResult> createProduct(ProductFormData request) =>
      throw UnimplementedError();
  @override
  Future<TenantProductDetail> updateProduct(
          String productId, ProductFormData request) =>
      throw UnimplementedError();
}

void main() {
  late WidgetTestFakeRepository repository;
  late AddProductWizardController controller;

  setUp(() {
    repository = WidgetTestFakeRepository();
    controller = AddProductWizardController(repository);
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
    testWidgets('renders common header and structure cards', (tester) async {
      await tester.pumpWidget(buildTestWidget(const AddProductWizardState()));

      expect(find.text('Product Type & Tracking Setup'), findsOneWidget);
      expect(find.text('Select Product Type'), findsOneWidget);
      expect(find.text('Simple Product'), findsOneWidget);
      expect(find.text('Variant Product'), findsOneWidget);
      expect(find.text('Bundle / Kit'), findsOneWidget);
    });

    testWidgets('renders SIMPLE content when SIMPLE structure selected',
        (tester) async {
      await tester.pumpWidget(buildTestWidget(const AddProductWizardState(
        productStructure: 'SIMPLE',
      )));

      expect(find.text('Tracking & Stock Rules'), findsOneWidget);
      expect(find.text('Track Inventory'), findsOneWidget);
      expect(find.text('Batch / Lot Tracking'), findsOneWidget);
      expect(find.text('Expiry Tracking'), findsOneWidget);
      expect(find.text('Serial Number Tracking'), findsOneWidget);
      expect(
          find.text(
              'Units & Pack Conversion will be configured in the next stage.'),
          findsOneWidget);
    });

    testWidgets('renders VARIANT content when VARIANT structure selected',
        (tester) async {
      await tester.pumpWidget(buildTestWidget(const AddProductWizardState(
        productStructure: 'VARIANT',
      )));

      expect(find.text('Tracking Settings'), findsOneWidget);
      expect(
          find.text(
              'When ON, stock will be tracked for each variant at outlet level.'),
          findsOneWidget);
      expect(
          find.text(
              'Variant options such as size and color will be configured in Product Configuration.'),
          findsOneWidget);
    });

    testWidgets('renders BUNDLE content when BUNDLE structure selected',
        (tester) async {
      await tester.pumpWidget(buildTestWidget(const AddProductWizardState(
        productStructure: 'BUNDLE',
      )));

      expect(find.text('Bundle Inventory Behaviour'), findsOneWidget);
      expect(find.text('Component-based Inventory'), findsOneWidget);
      expect(find.text('Component Stock Deduction'), findsOneWidget);
      expect(find.text('Component Tracking Rules'), findsOneWidget);
      expect(
          find.text(
              'Bundle components will be configured in Product Configuration.'),
          findsOneWidget);
    });

    testWidgets('structure card selection updates controller state',
        (tester) async {
      await tester.pumpWidget(buildTestWidget(const AddProductWizardState(
        productStructure: 'SIMPLE',
      )));

      await tester.tap(find.text('Variant Product'));
      await tester.pump();

      expect(controller.wizardState.productStructure, 'VARIANT');
    });

    testWidgets('toggling serial tracking disables batch and expiry in SIMPLE',
        (tester) async {
      controller.setTrackInventory(true);
      controller.setBatchTracking(true);
      controller.setExpiryTracking(true);

      expect(controller.wizardState.batchTracking, true);
      expect(controller.wizardState.expiryTracking, true);

      controller.setSerialTracking(true);

      expect(controller.wizardState.serialTracking, true);
      expect(controller.wizardState.batchTracking, false);
      expect(controller.wizardState.expiryTracking, false);
    });
  });
}

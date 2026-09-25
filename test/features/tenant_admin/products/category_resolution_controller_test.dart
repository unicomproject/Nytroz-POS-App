import 'package:flutter_test/flutter_test.dart';
import 'package:nytroz_pos/features/tenant_admin/products/data/dtos/product_setup_scan_dtos.dart';
import 'package:nytroz_pos/features/tenant_admin/products/domain/entities/scan_barcode_step_state.dart';
import 'package:nytroz_pos/features/tenant_admin/products/domain/entities/tenant_product_create_options.dart';
import 'package:nytroz_pos/features/tenant_admin/products/domain/repositories/tenant_product_repository.dart';
import 'package:nytroz_pos/features/tenant_admin/products/presentation/controllers/add_product_wizard_controller.dart';

class _FakeProductRepo implements TenantProductRepository {
  ExternalLookupProductBarcodeResponseDto? nextExternalLookupResponse;

  @override
  Future<ResolveProductBarcodeResponseDto> resolveBarcode(
      ResolveProductBarcodeRequestDto request) async {
    return const ResolveProductBarcodeResponseDto(
      outcome: 'VALID_NO_LOCAL_MATCH',
      normalizedBarcode: '5449000000996',
      barcodeType: 'EAN-13',
    );
  }

  @override
  Future<ExternalLookupProductBarcodeResponseDto> externalLookupBarcode({
    required String barcode,
    String? identifierStandard,
  }) async {
    if (nextExternalLookupResponse != null) {
      return nextExternalLookupResponse!;
    }
    return const ExternalLookupProductBarcodeResponseDto(
      status: 'NO_MATCH',
      retryAllowed: false,
    );
  }

  @override
  Future<TenantProductCreateOptions> getCreateOptions() async {
    return const TenantProductCreateOptions(
      categories: [
        ProductCategoryOption(id: 'cat-soft-drinks', code: 'CSD', name: 'Soft Drinks'),
        ProductCategoryOption(id: 'cat-beverages', code: 'CBEV', name: 'Beverages'),
        ProductCategoryOption(id: 'cat-snacks', code: 'CSNK', name: 'Snacks'),
      ],
      subCategories: [],
      brands: [
        ProductBrandOption(id: 'brand-coke', code: 'COKE', name: 'Coca-Cola'),
      ],
      units: [
        ProductUnitOption(id: 'unit-can', code: 'CAN', name: 'Can'),
      ],
      taxes: [],
      outlets: [],
      variantOptionTemplates: [],
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late _FakeProductRepo repo;
  late AddProductWizardController controller;

  setUp(() async {
    repo = _FakeProductRepo();
    controller = AddProductWizardController(repo);
    await controller.initWizard();
  });

  tearDown(() {
    controller.dispose();
  });

  group('AddProductWizardController - Category Resolution', () {
    test('FOUND + mapped category stores categoryResolution and preselects categoryId on continueUseThisProduct', () async {
      repo.nextExternalLookupResponse = const ExternalLookupProductBarcodeResponseDto(
        status: 'FOUND',
        retryAllowed: false,
        suggestion: ExternalProductSuggestionDto(
          productName: 'Coca-Cola Can 330ml',
          brandText: 'Coca-Cola',
          categoryText: 'Beverages, Carbonated drinks, Colas',
          externalCategoryKey: 'en:colas',
          externalCategoryName: 'Colas',
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
          suggestions: [
            TenantCategoryCandidateDto(
              id: 'cat-beverages',
              name: 'Beverages',
              code: 'CBEV',
              matchType: 'SIMILARITY',
            ),
          ],
        ),
      );

      await controller.submitScanCandidate('5449000000996');
      await controller.runExternalLookup();

      // Verify categoryResolution is stored in scanStepState
      expect(controller.state.scanStepState.panel, ScanBarcodePanel.externalFound);
      expect(controller.state.scanStepState.categoryResolution, isNotNull);
      expect(
        controller.state.scanStepState.categoryResolution!.mappedCategory?.id,
        'cat-soft-drinks',
      );

      // Advance via Use This Product
      await controller.continueUseThisProduct();

      // Verify categoryId is preselected to mappedCategory.id
      expect(controller.state.currentStep, 2);
      expect(controller.state.categoryId, 'cat-soft-drinks');
    });

    test('FOUND + mapped category missing from current options does NOT preselect invalid categoryId', () async {
      repo.nextExternalLookupResponse = const ExternalLookupProductBarcodeResponseDto(
        status: 'FOUND',
        retryAllowed: false,
        suggestion: ExternalProductSuggestionDto(
          productName: 'Specialty Item',
          categoryText: 'Special',
          externalCategoryKey: 'en:special',
        ),
        categoryResolution: TenantCategoryResolutionDto(
          provider: 'openfoodfacts',
          externalCategoryKey: 'en:special',
          externalCategoryName: 'Special',
          mappedCategory: TenantCategoryCandidateDto(
            id: 'cat-non-existent-999',
            name: 'Non Existent Category',
            code: 'CNE',
          ),
          suggestions: [],
        ),
      );

      await controller.submitScanCandidate('5449000000996');
      await controller.runExternalLookup();
      await controller.continueUseThisProduct();

      // Since cat-non-existent-999 is not in createOptions.categories, categoryId must NOT be set
      expect(controller.state.categoryId, isNull);
    });

    test('FOUND + suggestions stores suggestions and does NOT auto-select categoryId', () async {
      repo.nextExternalLookupResponse = const ExternalLookupProductBarcodeResponseDto(
        status: 'FOUND',
        retryAllowed: false,
        suggestion: ExternalProductSuggestionDto(
          productName: 'Unmapped Juice',
          categoryText: 'Juices',
          externalCategoryKey: 'en:fruit-juices',
          externalCategoryName: 'Fruit Juices',
        ),
        categoryResolution: TenantCategoryResolutionDto(
          provider: 'openfoodfacts',
          externalCategoryKey: 'en:fruit-juices',
          externalCategoryName: 'Fruit Juices',
          mappedCategory: null,
          suggestions: [
            TenantCategoryCandidateDto(
              id: 'cat-beverages',
              name: 'Beverages',
              code: 'CBEV',
              matchType: 'SIMILARITY',
            ),
          ],
        ),
      );

      await controller.submitScanCandidate('5449000000996');
      await controller.runExternalLookup();
      expect(controller.state.scanStepState.categoryResolution?.mappedCategory, isNull);
      expect(controller.state.scanStepState.categoryResolution?.suggestions.length, 1);

      await controller.continueUseThisProduct();

      // categoryId must remain null because there is no saved mappedCategory
      expect(controller.state.categoryId, isNull);
    });

    test('Suggestion tap updates categoryId to chosen candidate', () async {
      repo.nextExternalLookupResponse = const ExternalLookupProductBarcodeResponseDto(
        status: 'FOUND',
        retryAllowed: false,
        suggestion: ExternalProductSuggestionDto(
          productName: 'Unmapped Juice',
        ),
        categoryResolution: TenantCategoryResolutionDto(
          provider: 'openfoodfacts',
          externalCategoryKey: 'en:fruit-juices',
          suggestions: [
            TenantCategoryCandidateDto(
              id: 'cat-beverages',
              name: 'Beverages',
              code: 'CBEV',
            ),
          ],
        ),
      );

      await controller.submitScanCandidate('5449000000996');
      await controller.runExternalLookup();
      await controller.continueUseThisProduct();

      // Simulate user tapping suggestion chip
      controller.updateCategory('cat-beverages');
      expect(controller.state.categoryId, 'cat-beverages');
    });

    test('User override: user selects another category and it remains selected', () async {
      repo.nextExternalLookupResponse = const ExternalLookupProductBarcodeResponseDto(
        status: 'FOUND',
        retryAllowed: false,
        suggestion: ExternalProductSuggestionDto(
          productName: 'Coca-Cola',
        ),
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
      );

      await controller.submitScanCandidate('5449000000996');
      await controller.runExternalLookup();
      await controller.continueUseThisProduct();

      expect(controller.state.categoryId, 'cat-soft-drinks');

      // User overrides with Beverages
      controller.updateCategory('cat-beverages');
      expect(controller.state.categoryId, 'cat-beverages');
    });

    test('No category resolution preserves existing wizard flow unchanged', () async {
      repo.nextExternalLookupResponse = const ExternalLookupProductBarcodeResponseDto(
        status: 'FOUND',
        retryAllowed: false,
        suggestion: ExternalProductSuggestionDto(
          productName: 'Plain Item',
        ),
        categoryResolution: null,
      );

      await controller.submitScanCandidate('5449000000996');
      await controller.runExternalLookup();
      expect(controller.state.scanStepState.categoryResolution, isNull);

      await controller.continueUseThisProduct();
      expect(controller.state.productName, 'Plain Item');
      expect(controller.state.categoryId, isNull);
    });

    test('Stale state: Product A resolution is cleared on new scan for Product B', () async {
      // Step 1: Scan Product A with resolution
      repo.nextExternalLookupResponse = const ExternalLookupProductBarcodeResponseDto(
        status: 'FOUND',
        retryAllowed: false,
        suggestion: ExternalProductSuggestionDto(productName: 'Product A'),
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
      );

      await controller.submitScanCandidate('5449000000996');
      await controller.runExternalLookup();
      expect(controller.state.scanStepState.categoryResolution, isNotNull);

      // Step 2: New scan for Product B starts
      await controller.submitScanCandidate('5012345678900');
      // Resolution from Product A must be immediately cleared
      expect(controller.state.scanStepState.categoryResolution, isNull);

      // Product B returns NO_MATCH
      repo.nextExternalLookupResponse = const ExternalLookupProductBarcodeResponseDto(
        status: 'NO_MATCH',
        retryAllowed: false,
      );
      await controller.runExternalLookup();
      expect(controller.state.scanStepState.categoryResolution, isNull);
    });
  });
}

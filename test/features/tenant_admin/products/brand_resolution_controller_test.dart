import 'package:flutter_test/flutter_test.dart';
import 'package:nytroz_pos/features/tenant_admin/products/data/dtos/product_setup_scan_dtos.dart';
import 'package:nytroz_pos/features/tenant_admin/products/domain/entities/scan_barcode_step_state.dart';
import 'package:nytroz_pos/features/tenant_admin/products/domain/entities/tenant_product_create_options.dart';
import 'package:nytroz_pos/features/tenant_admin/products/domain/repositories/tenant_product_repository.dart';
import 'package:nytroz_pos/features/tenant_admin/products/presentation/controllers/add_product_wizard_controller.dart';

class _FakeProductRepo implements TenantProductRepository {
  ExternalLookupProductBarcodeResponseDto? nextExternalLookupResponse;
  TenantProductCreateOptions? refreshedOptions;
  int getCreateOptionsCallCount = 0;

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
    getCreateOptionsCallCount++;
    if (refreshedOptions != null) {
      return refreshedOptions!;
    }
    return const TenantProductCreateOptions(
      categories: [
        ProductCategoryOption(id: 'cat-soft-drinks', code: 'CSD', name: 'Soft Drinks'),
      ],
      subCategories: [],
      brands: [
        ProductBrandOption(id: 'brand-coke', code: 'COKE', name: 'Coca Cola'),
        ProductBrandOption(id: 'brand-coke-zero', code: 'COKE_ZERO', name: 'Coca Cola Zero'),
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

  group('AddProductWizardController - Brand Resolution', () {
    test('FOUND + mapped brand stores brandResolution and preselects brandId on continueUseThisProduct', () async {
      repo.nextExternalLookupResponse = const ExternalLookupProductBarcodeResponseDto(
        status: 'FOUND',
        retryAllowed: false,
        suggestion: ExternalProductSuggestionDto(
          productName: 'Coca-Cola Can 330ml',
          brandText: 'Coca-Cola',
        ),
        brandResolution: TenantBrandResolutionDto(
          provider: 'openfoodfacts',
          externalBrandKey: 'coca cola',
          externalBrandName: 'Coca-Cola',
          mappedBrand: TenantBrandCandidateDto(
            id: 'brand-coke',
            name: 'Coca Cola',
            code: 'COKE',
          ),
          suggestions: [],
        ),
      );

      await controller.submitScanCandidate('5449000000996');
      await controller.runExternalLookup();

      expect(controller.state.scanStepState.panel, ScanBarcodePanel.externalFound);
      expect(controller.state.scanStepState.brandResolution, isNotNull);
      expect(
        controller.state.scanStepState.brandResolution!.mappedBrand?.id,
        'brand-coke',
      );

      await controller.continueUseThisProduct();

      expect(controller.state.currentStep, 2);
      expect(controller.state.brandId, 'brand-coke');
    });

    test('FOUND + mapped brand missing from current options does NOT preselect invalid brandId', () async {
      repo.nextExternalLookupResponse = const ExternalLookupProductBarcodeResponseDto(
        status: 'FOUND',
        retryAllowed: false,
        suggestion: ExternalProductSuggestionDto(
          productName: 'Specialty Item',
          brandText: 'GhostBrand',
        ),
        brandResolution: TenantBrandResolutionDto(
          provider: 'openfoodfacts',
          externalBrandKey: 'ghostbrand',
          externalBrandName: 'GhostBrand',
          mappedBrand: TenantBrandCandidateDto(
            id: 'brand-non-existent-999',
            name: 'Ghost Brand',
            code: 'GHOST',
          ),
          suggestions: [],
        ),
      );

      await controller.submitScanCandidate('5449000000996');
      await controller.runExternalLookup();
      await controller.continueUseThisProduct();

      expect(controller.state.brandId, isNull);
    });

    test('FOUND + suggestions stores suggestions and does NOT auto-select brandId', () async {
      repo.nextExternalLookupResponse = const ExternalLookupProductBarcodeResponseDto(
        status: 'FOUND',
        retryAllowed: false,
        suggestion: ExternalProductSuggestionDto(
          productName: 'Unmapped Cola',
          brandText: 'Coca-Cola Zero',
        ),
        brandResolution: TenantBrandResolutionDto(
          provider: 'openfoodfacts',
          externalBrandKey: 'coca cola zero',
          externalBrandName: 'Coca-Cola Zero',
          mappedBrand: null,
          suggestions: [
            TenantBrandCandidateDto(
              id: 'brand-coke-zero',
              name: 'Coca Cola Zero',
              code: 'COKE_ZERO',
              matchType: 'EXACT',
            ),
          ],
        ),
      );

      await controller.submitScanCandidate('5449000000996');
      await controller.runExternalLookup();
      expect(controller.state.scanStepState.brandResolution?.mappedBrand, isNull);
      expect(controller.state.scanStepState.brandResolution?.suggestions.length, 1);

      await controller.continueUseThisProduct();

      expect(controller.state.brandId, isNull);
    });

    test('Suggestion tap updates brandId to chosen candidate', () async {
      repo.nextExternalLookupResponse = const ExternalLookupProductBarcodeResponseDto(
        status: 'FOUND',
        retryAllowed: false,
        suggestion: ExternalProductSuggestionDto(productName: 'Unmapped Cola'),
        brandResolution: TenantBrandResolutionDto(
          provider: 'openfoodfacts',
          externalBrandKey: 'coca cola zero',
          suggestions: [
            TenantBrandCandidateDto(
              id: 'brand-coke-zero',
              name: 'Coca Cola Zero',
              code: 'COKE_ZERO',
            ),
          ],
        ),
      );

      await controller.submitScanCandidate('5449000000996');
      await controller.runExternalLookup();
      await controller.continueUseThisProduct();

      controller.updateBrand('brand-coke-zero');
      expect(controller.state.brandId, 'brand-coke-zero');
    });

    test('User override: user selects another brand and it remains selected', () async {
      repo.nextExternalLookupResponse = const ExternalLookupProductBarcodeResponseDto(
        status: 'FOUND',
        retryAllowed: false,
        suggestion: ExternalProductSuggestionDto(productName: 'Coca-Cola'),
        brandResolution: TenantBrandResolutionDto(
          provider: 'openfoodfacts',
          externalBrandKey: 'coca cola',
          mappedBrand: TenantBrandCandidateDto(
            id: 'brand-coke',
            name: 'Coca Cola',
            code: 'COKE',
          ),
          suggestions: [],
        ),
      );

      await controller.submitScanCandidate('5449000000996');
      await controller.runExternalLookup();
      await controller.continueUseThisProduct();

      expect(controller.state.brandId, 'brand-coke');

      controller.updateBrand('brand-coke-zero');
      expect(controller.state.brandId, 'brand-coke-zero');
    });

    test('No brand resolution preserves existing wizard flow unchanged', () async {
      repo.nextExternalLookupResponse = const ExternalLookupProductBarcodeResponseDto(
        status: 'FOUND',
        retryAllowed: false,
        suggestion: ExternalProductSuggestionDto(productName: 'Plain Item'),
        brandResolution: null,
      );

      await controller.submitScanCandidate('5449000000996');
      await controller.runExternalLookup();
      expect(controller.state.scanStepState.brandResolution, isNull);

      await controller.continueUseThisProduct();
      expect(controller.state.productName, 'Plain Item');
      expect(controller.state.brandId, isNull);
    });

    test('Stale state: Product A brand resolution is cleared on new scan for Product B', () async {
      repo.nextExternalLookupResponse = const ExternalLookupProductBarcodeResponseDto(
        status: 'FOUND',
        retryAllowed: false,
        suggestion: ExternalProductSuggestionDto(productName: 'Product A'),
        brandResolution: TenantBrandResolutionDto(
          provider: 'openfoodfacts',
          externalBrandKey: 'coca cola',
          mappedBrand: TenantBrandCandidateDto(
            id: 'brand-coke',
            name: 'Coca Cola',
            code: 'COKE',
          ),
          suggestions: [],
        ),
      );

      await controller.submitScanCandidate('5449000000996');
      await controller.runExternalLookup();
      expect(controller.state.scanStepState.brandResolution, isNotNull);

      await controller.submitScanCandidate('5012345678900');
      expect(controller.state.scanStepState.brandResolution, isNull);

      repo.nextExternalLookupResponse = const ExternalLookupProductBarcodeResponseDto(
        status: 'NO_MATCH',
        retryAllowed: false,
      );
      await controller.runExternalLookup();
      expect(controller.state.scanStepState.brandResolution, isNull);
    });

    test('Category and brand resolution are independent and both preselect together', () async {
      repo.nextExternalLookupResponse = const ExternalLookupProductBarcodeResponseDto(
        status: 'FOUND',
        retryAllowed: false,
        suggestion: ExternalProductSuggestionDto(
          productName: 'Coca-Cola Can 330ml',
          brandText: 'Coca-Cola',
          externalCategoryKey: 'en:colas',
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
        brandResolution: TenantBrandResolutionDto(
          provider: 'openfoodfacts',
          externalBrandKey: 'coca cola',
          mappedBrand: TenantBrandCandidateDto(
            id: 'brand-coke',
            name: 'Coca Cola',
            code: 'COKE',
          ),
          suggestions: [],
        ),
      );

      await controller.submitScanCandidate('5449000000996');
      await controller.runExternalLookup();
      await controller.continueUseThisProduct();

      expect(controller.state.categoryId, 'cat-soft-drinks');
      expect(controller.state.brandId, 'brand-coke');
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:nytroz_pos/features/tenant_admin/products/data/dtos/product_setup_scan_dtos.dart';
import 'package:nytroz_pos/features/tenant_admin/products/data/mappers/wizard_product_create_mapper.dart';
import 'package:nytroz_pos/features/tenant_admin/products/domain/entities/add_product_wizard_state.dart';
import 'package:nytroz_pos/features/tenant_admin/products/domain/entities/scan_barcode_step_state.dart';

void main() {
  group('WizardProductCreateMapper - External Category Mapping Context', () {
    test('includes mapping context when categoryResolution has provider and key', () {
      const state = AddProductWizardState(
        productName: 'Coca-Cola 330ml',
        categoryId: 'cat-soft-drinks',
        productStructure: 'SIMPLE',
        scanStepState: ScanBarcodeStepState(
          candidateBarcode: '5449000000996',
          categoryResolution: TenantCategoryResolutionDto(
            provider: 'openfoodfacts',
            externalCategoryKey: 'en:colas',
            externalCategoryName: 'Colas',
            mappedCategory: TenantCategoryCandidateDto(
              id: 'cat-soft-drinks',
              name: 'Soft Drinks',
              code: 'SD',
              matchType: 'SAVED_MAPPING',
            ),
            suggestions: [],
          ),
        ),
      );

      final json = WizardProductCreateMapper.toWizardCreateJson(state);

      expect(json['productName'], 'Coca-Cola 330ml');
      expect(json['categoryId'], 'cat-soft-drinks');
      expect(json.containsKey('tenantId'), isFalse);

      final mapping = json['externalCategoryMappingContext'] as Map<String, dynamic>?;
      expect(mapping, isNotNull);
      expect(mapping!['provider'], 'openfoodfacts');
      expect(mapping['externalCategoryKey'], 'en:colas');
      expect(mapping['externalCategoryName'], 'Colas');
    });

    test('user override preserves user categoryId while retaining external category key in mapping context', () {
      // Backend mapped to 'cat-soft-drinks', but user changed category dropdown to 'cat-beverages'
      const state = AddProductWizardState(
        productName: 'Coca-Cola 330ml',
        categoryId: 'cat-beverages', // User override!
        productStructure: 'SIMPLE',
        scanStepState: ScanBarcodeStepState(
          candidateBarcode: '5449000000996',
          categoryResolution: TenantCategoryResolutionDto(
            provider: 'openfoodfacts',
            externalCategoryKey: 'en:colas',
            externalCategoryName: 'Colas',
            mappedCategory: TenantCategoryCandidateDto(
              id: 'cat-soft-drinks', // Different from state.categoryId
              name: 'Soft Drinks',
              code: 'SD',
              matchType: 'SAVED_MAPPING',
            ),
            suggestions: [],
          ),
        ),
      );

      final json = WizardProductCreateMapper.toWizardCreateJson(state);

      // CategoryId must be the final user choice (state.categoryId)
      expect(json['categoryId'], 'cat-beverages');
      expect(json.containsKey('tenantId'), isFalse);

      // Mapping context preserves the provider and external category key so backend can update mapping
      final mapping = json['externalCategoryMappingContext'] as Map<String, dynamic>?;
      expect(mapping, isNotNull);
      expect(mapping!['provider'], 'openfoodfacts');
      expect(mapping['externalCategoryKey'], 'en:colas');
      expect(mapping['externalCategoryName'], 'Colas');
    });

    test('omits mapping context when categoryResolution is null (e.g. local product flow)', () {
      const state = AddProductWizardState(
        productName: 'Custom Handcrafted Mug',
        categoryId: 'cat-home',
        productStructure: 'SIMPLE',
        scanStepState: ScanBarcodeStepState(
          candidateBarcode: '1234567890',
          categoryResolution: null,
        ),
      );

      final json = WizardProductCreateMapper.toWizardCreateJson(state);

      expect(json['productName'], 'Custom Handcrafted Mug');
      expect(json['categoryId'], 'cat-home');
      expect(json.containsKey('externalCategoryMappingContext'), isFalse);
      expect(json.containsKey('tenantId'), isFalse);
    });

    test('omits mapping context when external category key is empty', () {
      const state = AddProductWizardState(
        productName: 'Mystery Product',
        categoryId: 'cat-misc',
        productStructure: 'SIMPLE',
        scanStepState: ScanBarcodeStepState(
          candidateBarcode: '9999999999',
          categoryResolution: TenantCategoryResolutionDto(
            provider: 'openfoodfacts',
            externalCategoryKey: '',
            externalCategoryName: null,
            mappedCategory: null,
            suggestions: [],
          ),
        ),
      );

      final json = WizardProductCreateMapper.toWizardCreateJson(state);

      expect(json.containsKey('externalCategoryMappingContext'), isFalse);
      expect(json.containsKey('tenantId'), isFalse);
    });
  });

  group('WizardProductCreateMapper - External Brand Mapping Context', () {
    test('includes brand mapping context when brandResolution has provider and key', () {
      const state = AddProductWizardState(
        productName: 'Coca-Cola 330ml',
        categoryId: 'cat-soft-drinks',
        brandId: 'brand-coke',
        productStructure: 'SIMPLE',
        scanStepState: ScanBarcodeStepState(
          candidateBarcode: '5449000000996',
          brandResolution: TenantBrandResolutionDto(
            provider: 'openfoodfacts',
            externalBrandKey: 'coca cola',
            externalBrandName: 'Coca-Cola',
            mappedBrand: TenantBrandCandidateDto(
              id: 'brand-coke',
              name: 'Coca Cola',
              code: 'COKE',
              matchType: 'SAVED_MAPPING',
            ),
            suggestions: [],
          ),
        ),
      );

      final json = WizardProductCreateMapper.toWizardCreateJson(state);

      expect(json['brandId'], 'brand-coke');
      expect(json.containsKey('tenantId'), isFalse);

      final mapping = json['externalBrandMappingContext'] as Map<String, dynamic>?;
      expect(mapping, isNotNull);
      expect(mapping!['provider'], 'openfoodfacts');
      expect(mapping['externalBrandKey'], 'coca cola');
      expect(mapping['externalBrandName'], 'Coca-Cola');
    });

    test('user override preserves user brandId while retaining external brand key in mapping context', () {
      // Backend mapped to 'brand-coke', but user changed brand dropdown to 'brand-coke-zero'
      const state = AddProductWizardState(
        productName: 'Coca-Cola 330ml',
        categoryId: 'cat-soft-drinks',
        brandId: 'brand-coke-zero', // User override!
        productStructure: 'SIMPLE',
        scanStepState: ScanBarcodeStepState(
          candidateBarcode: '5449000000996',
          brandResolution: TenantBrandResolutionDto(
            provider: 'openfoodfacts',
            externalBrandKey: 'coca cola',
            externalBrandName: 'Coca-Cola',
            mappedBrand: TenantBrandCandidateDto(
              id: 'brand-coke', // Different from state.brandId
              name: 'Coca Cola',
              code: 'COKE',
              matchType: 'SAVED_MAPPING',
            ),
            suggestions: [],
          ),
        ),
      );

      final json = WizardProductCreateMapper.toWizardCreateJson(state);

      // brandId must be the final user choice (state.brandId)
      expect(json['brandId'], 'brand-coke-zero');
      expect(json.containsKey('tenantId'), isFalse);

      // Mapping context preserves the provider and external brand key so backend can update mapping
      final mapping = json['externalBrandMappingContext'] as Map<String, dynamic>?;
      expect(mapping, isNotNull);
      expect(mapping!['provider'], 'openfoodfacts');
      expect(mapping['externalBrandKey'], 'coca cola');
      expect(mapping['externalBrandName'], 'Coca-Cola');
    });

    test('omits brand mapping context when brandResolution is null (e.g. local product flow)', () {
      const state = AddProductWizardState(
        productName: 'Custom Handcrafted Mug',
        categoryId: 'cat-home',
        productStructure: 'SIMPLE',
        scanStepState: ScanBarcodeStepState(
          candidateBarcode: '1234567890',
          brandResolution: null,
        ),
      );

      final json = WizardProductCreateMapper.toWizardCreateJson(state);

      expect(json['productName'], 'Custom Handcrafted Mug');
      expect(json.containsKey('externalBrandMappingContext'), isFalse);
      expect(json.containsKey('brandId'), isFalse);
    });

    test('omits brand mapping context when external brand key is empty', () {
      const state = AddProductWizardState(
        productName: 'Mystery Product',
        categoryId: 'cat-misc',
        productStructure: 'SIMPLE',
        scanStepState: ScanBarcodeStepState(
          candidateBarcode: '9999999999',
          brandResolution: TenantBrandResolutionDto(
            provider: 'openfoodfacts',
            externalBrandKey: '',
            externalBrandName: null,
            mappedBrand: null,
            suggestions: [],
          ),
        ),
      );

      final json = WizardProductCreateMapper.toWizardCreateJson(state);

      expect(json.containsKey('externalBrandMappingContext'), isFalse);
    });

    test('category and brand mapping contexts are independent and both included together', () {
      const state = AddProductWizardState(
        productName: 'Coca-Cola 330ml',
        categoryId: 'cat-soft-drinks',
        brandId: 'brand-coke',
        productStructure: 'SIMPLE',
        scanStepState: ScanBarcodeStepState(
          candidateBarcode: '5449000000996',
          categoryResolution: TenantCategoryResolutionDto(
            provider: 'openfoodfacts',
            externalCategoryKey: 'en:colas',
            externalCategoryName: 'Colas',
            suggestions: [],
          ),
          brandResolution: TenantBrandResolutionDto(
            provider: 'openfoodfacts',
            externalBrandKey: 'coca cola',
            externalBrandName: 'Coca-Cola',
            suggestions: [],
          ),
        ),
      );

      final json = WizardProductCreateMapper.toWizardCreateJson(state);

      final categoryMapping = json['externalCategoryMappingContext'] as Map<String, dynamic>?;
      final brandMapping = json['externalBrandMappingContext'] as Map<String, dynamic>?;
      expect(categoryMapping, isNotNull);
      expect(brandMapping, isNotNull);
      expect(categoryMapping!['externalCategoryKey'], 'en:colas');
      expect(brandMapping!['externalBrandKey'], 'coca cola');
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:nytroz_pos/features/tenant_admin/products/data/dtos/product_setup_scan_dtos.dart';

void main() {
  group('Category Resolution DTO tests', () {
    test('TenantCategoryCandidateDto fromJson & toJson with matchType', () {
      final json = {
        'id': 'cat-123',
        'name': 'Soft Drinks',
        'code': 'CAT-SOFT',
        'matchType': 'EXACT',
      };

      final candidate = TenantCategoryCandidateDto.fromJson(json);
      expect(candidate.id, 'cat-123');
      expect(candidate.name, 'Soft Drinks');
      expect(candidate.code, 'CAT-SOFT');
      expect(candidate.matchType, 'EXACT');

      final serialized = candidate.toJson();
      expect(serialized['id'], 'cat-123');
      expect(serialized['name'], 'Soft Drinks');
      expect(serialized['code'], 'CAT-SOFT');
      expect(serialized['matchType'], 'EXACT');
    });

    test('TenantCategoryCandidateDto fromJson without matchType', () {
      final json = {
        'id': 'cat-456',
        'name': 'Beverages',
        'code': 'CAT-BEV',
      };

      final candidate = TenantCategoryCandidateDto.fromJson(json);
      expect(candidate.id, 'cat-456');
      expect(candidate.name, 'Beverages');
      expect(candidate.code, 'CAT-BEV');
      expect(candidate.matchType, isNull);
    });

    test('TenantCategoryResolutionDto fromJson with mappedCategory and suggestions', () {
      final json = {
        'provider': 'openfoodfacts',
        'externalCategoryKey': 'en:colas',
        'externalCategoryName': 'Colas',
        'mappedCategory': {
          'id': 'cat-1',
          'name': 'Soft Drinks',
          'code': 'CAT-SOFT-DRINKS',
          'matchType': 'SAVED_MAPPING',
        },
        'suggestions': [
          {
            'id': 'cat-2',
            'name': 'Beverages',
            'code': 'CAT-BEVERAGES',
            'matchType': 'SIMILARITY',
          },
        ],
      };

      final resolution = TenantCategoryResolutionDto.fromJson(json);
      expect(resolution.provider, 'openfoodfacts');
      expect(resolution.externalCategoryKey, 'en:colas');
      expect(resolution.externalCategoryName, 'Colas');
      expect(resolution.mappedCategory, isNotNull);
      expect(resolution.mappedCategory!.name, 'Soft Drinks');
      expect(resolution.suggestions.length, 1);
      expect(resolution.suggestions.first.name, 'Beverages');

      final serialized = resolution.toJson();
      expect(serialized['provider'], 'openfoodfacts');
      expect((serialized['mappedCategory'] as Map)['name'], 'Soft Drinks');
      expect((serialized['suggestions'] as List).length, 1);
    });

    test('TenantCategoryResolutionDto fromJson with null mappedCategory and empty suggestions', () {
      final json = {
        'provider': 'openfoodfacts',
        'externalCategoryKey': 'en:snack',
        'externalCategoryName': 'Snacks',
        'mappedCategory': null,
        'suggestions': <dynamic>[],
      };

      final resolution = TenantCategoryResolutionDto.fromJson(json);
      expect(resolution.provider, 'openfoodfacts');
      expect(resolution.mappedCategory, isNull);
      expect(resolution.suggestions, isEmpty);
    });

    test('ExternalLookupProductBarcodeResponseDto fromJson with categoryResolution', () {
      final json = {
        'status': 'FOUND',
        'suggestion': {
          'productName': 'Coca-Cola Original Taste',
          'categoryText': 'Beverages, Carbonated drinks, Colas',
          'externalCategoryKey': 'en:colas',
          'externalCategoryName': 'Colas',
          'externalCategoryHierarchy': [
            'en:beverages',
            'en:carbonated-drinks',
            'en:colas',
          ],
        },
        'categoryResolution': {
          'provider': 'openfoodfacts',
          'externalCategoryKey': 'en:colas',
          'externalCategoryName': 'Colas',
          'mappedCategory': {
            'id': 'cat-sd',
            'name': 'Soft Drinks',
            'code': 'CAT-SOFT-DRINKS',
          },
          'suggestions': [
            {
              'id': 'cat-bev',
              'name': 'Beverages',
              'code': 'CAT-BEVERAGES',
              'matchType': 'SIMILARITY',
            },
          ],
        },
      };

      final response = ExternalLookupProductBarcodeResponseDto.fromJson(json);
      expect(response.status, 'FOUND');
      expect(response.suggestion, isNotNull);
      expect(response.suggestion!.externalCategoryKey, 'en:colas');
      expect(response.suggestion!.externalCategoryName, 'Colas');
      expect(response.suggestion!.externalCategoryHierarchy, [
        'en:beverages',
        'en:carbonated-drinks',
        'en:colas',
      ]);
      expect(response.categoryResolution, isNotNull);
      expect(response.categoryResolution!.provider, 'openfoodfacts');
      expect(response.categoryResolution!.mappedCategory?.name, 'Soft Drinks');
      expect(response.categoryResolution!.suggestions.length, 1);
    });

    test('ExternalLookupProductBarcodeResponseDto backward compatible with old payload without new fields', () {
      final json = {
        'status': 'FOUND',
        'suggestion': {
          'productName': 'Classic Biscuit',
          'categoryText': 'Snacks',
        },
      };

      final response = ExternalLookupProductBarcodeResponseDto.fromJson(json);
      expect(response.status, 'FOUND');
      expect(response.suggestion, isNotNull);
      expect(response.suggestion!.productName, 'Classic Biscuit');
      expect(response.suggestion!.externalCategoryKey, isNull);
      expect(response.suggestion!.externalCategoryName, isNull);
      expect(response.suggestion!.externalCategoryHierarchy, isNull);
      expect(response.categoryResolution, isNull);
    });

    test('ExternalLookupProductBarcodeResponseDto with NO_MATCH has null categoryResolution', () {
      final json = {
        'status': 'NO_MATCH',
        'suggestion': null,
      };

      final response = ExternalLookupProductBarcodeResponseDto.fromJson(json);
      expect(response.status, 'NO_MATCH');
      expect(response.suggestion, isNull);
      expect(response.categoryResolution, isNull);
    });
  });
}

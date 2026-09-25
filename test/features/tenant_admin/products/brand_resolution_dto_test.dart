import 'package:flutter_test/flutter_test.dart';
import 'package:nytroz_pos/features/tenant_admin/products/data/dtos/product_setup_scan_dtos.dart';

void main() {
  group('Brand Resolution DTO tests', () {
    test('TenantBrandCandidateDto fromJson & toJson with matchType', () {
      final json = {
        'id': 'brand-123',
        'name': 'Coca Cola',
        'code': 'COCA_COLA',
        'matchType': 'EXACT',
      };

      final candidate = TenantBrandCandidateDto.fromJson(json);
      expect(candidate.id, 'brand-123');
      expect(candidate.name, 'Coca Cola');
      expect(candidate.code, 'COCA_COLA');
      expect(candidate.matchType, 'EXACT');

      final serialized = candidate.toJson();
      expect(serialized['id'], 'brand-123');
      expect(serialized['name'], 'Coca Cola');
      expect(serialized['code'], 'COCA_COLA');
      expect(serialized['matchType'], 'EXACT');
    });

    test('TenantBrandCandidateDto fromJson without matchType', () {
      final json = {
        'id': 'brand-456',
        'name': 'Nestle',
        'code': 'NESTLE',
      };

      final candidate = TenantBrandCandidateDto.fromJson(json);
      expect(candidate.id, 'brand-456');
      expect(candidate.name, 'Nestle');
      expect(candidate.code, 'NESTLE');
      expect(candidate.matchType, isNull);
    });

    test('TenantBrandResolutionDto fromJson with mappedBrand and suggestions', () {
      final json = {
        'provider': 'openfoodfacts',
        'externalBrandKey': 'coca cola',
        'externalBrandName': 'Coca-Cola',
        'mappedBrand': {
          'id': 'brand-1',
          'name': 'Coca Cola',
          'code': 'COCA_COLA',
        },
        'suggestions': [
          {
            'id': 'brand-2',
            'name': 'Coca Cola Zero',
            'code': 'COCA_COLA_ZERO',
            'matchType': 'SIMILARITY',
          },
        ],
      };

      final resolution = TenantBrandResolutionDto.fromJson(json);
      expect(resolution.provider, 'openfoodfacts');
      expect(resolution.externalBrandKey, 'coca cola');
      expect(resolution.externalBrandName, 'Coca-Cola');
      expect(resolution.mappedBrand, isNotNull);
      expect(resolution.mappedBrand!.name, 'Coca Cola');
      expect(resolution.suggestions.length, 1);
      expect(resolution.suggestions.first.name, 'Coca Cola Zero');

      final serialized = resolution.toJson();
      expect(serialized['provider'], 'openfoodfacts');
      expect((serialized['mappedBrand'] as Map)['name'], 'Coca Cola');
      expect((serialized['suggestions'] as List).length, 1);
    });

    test('TenantBrandResolutionDto fromJson with null mappedBrand and empty suggestions', () {
      final json = {
        'provider': 'openfoodfacts',
        'externalBrandKey': 'unknown brand',
        'externalBrandName': 'Unknown Brand',
        'mappedBrand': null,
        'suggestions': <dynamic>[],
      };

      final resolution = TenantBrandResolutionDto.fromJson(json);
      expect(resolution.provider, 'openfoodfacts');
      expect(resolution.mappedBrand, isNull);
      expect(resolution.suggestions, isEmpty);
    });

    test('ExternalLookupProductBarcodeResponseDto fromJson with brandResolution', () {
      final json = {
        'status': 'FOUND',
        'suggestion': {
          'productName': 'Coca-Cola Original Taste',
          'brandText': 'Coca-Cola',
        },
        'brandResolution': {
          'provider': 'openfoodfacts',
          'externalBrandKey': 'coca cola',
          'externalBrandName': 'Coca-Cola',
          'mappedBrand': {
            'id': 'brand-cc',
            'name': 'Coca Cola',
            'code': 'COCA_COLA',
          },
          'suggestions': [
            {
              'id': 'brand-ccz',
              'name': 'Coca Cola Zero',
              'code': 'COCA_COLA_ZERO',
              'matchType': 'SIMILARITY',
            },
          ],
        },
      };

      final response = ExternalLookupProductBarcodeResponseDto.fromJson(json);
      expect(response.status, 'FOUND');
      expect(response.suggestion, isNotNull);
      expect(response.suggestion!.brandText, 'Coca-Cola');
      expect(response.brandResolution, isNotNull);
      expect(response.brandResolution!.provider, 'openfoodfacts');
      expect(response.brandResolution!.mappedBrand?.name, 'Coca Cola');
      expect(response.brandResolution!.suggestions.length, 1);
    });

    test('ExternalLookupProductBarcodeResponseDto backward compatible with old payload without brandResolution', () {
      final json = {
        'status': 'FOUND',
        'suggestion': {
          'productName': 'Classic Biscuit',
          'brandText': 'GenericCo',
        },
      };

      final response = ExternalLookupProductBarcodeResponseDto.fromJson(json);
      expect(response.status, 'FOUND');
      expect(response.suggestion, isNotNull);
      expect(response.suggestion!.brandText, 'GenericCo');
      expect(response.brandResolution, isNull);
    });

    test('ExternalLookupProductBarcodeResponseDto with NO_MATCH has null brandResolution', () {
      final json = {
        'status': 'NO_MATCH',
        'suggestion': null,
      };

      final response = ExternalLookupProductBarcodeResponseDto.fromJson(json);
      expect(response.status, 'NO_MATCH');
      expect(response.suggestion, isNull);
      expect(response.brandResolution, isNull);
    });

    test('ExternalLookupProductBarcodeResponseDto with both categoryResolution and brandResolution present', () {
      final json = {
        'status': 'FOUND',
        'suggestion': {
          'productName': 'Coca-Cola Original Taste',
          'brandText': 'Coca-Cola',
          'categoryText': 'Beverages, Colas',
        },
        'categoryResolution': {
          'provider': 'openfoodfacts',
          'externalCategoryKey': 'en:colas',
          'externalCategoryName': 'Colas',
          'suggestions': <dynamic>[],
        },
        'brandResolution': {
          'provider': 'openfoodfacts',
          'externalBrandKey': 'coca cola',
          'externalBrandName': 'Coca-Cola',
          'suggestions': <dynamic>[],
        },
      };

      final response = ExternalLookupProductBarcodeResponseDto.fromJson(json);
      expect(response.categoryResolution, isNotNull);
      expect(response.brandResolution, isNotNull);
      expect(response.categoryResolution!.externalCategoryKey, 'en:colas');
      expect(response.brandResolution!.externalBrandKey, 'coca cola');
    });
  });
}

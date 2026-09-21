import 'package:flutter_test/flutter_test.dart';
import 'package:nytroz_pos/features/tenant_admin/products/data/dtos/product_create_request_dto.dart';

void main() {
  group('ProductCreateRequestDto', () {
    test('toJson includes externalCategoryMappingContext when present', () {
      const dto = ProductCreateRequestDto(
        productName: 'Cola 500ml',
        productCode: 'COLA-500',
        sku: 'SKU-COLA-500',
        categoryId: 'cat-beverages',
        unitType: 'PCS',
        sellingPrice: 2.50,
        trackInventory: true,
        status: 'ACTIVE',
        externalCategoryMappingContext: ExternalCategoryMappingContextDto(
          provider: 'openfoodfacts',
          externalCategoryKey: 'en:colas',
          externalCategoryName: 'Colas',
        ),
      );

      final json = dto.toJson();

      expect(json['productName'], 'Cola 500ml');
      expect(json['categoryId'], 'cat-beverages');
      expect(json['externalCategoryMappingContext'], isNotNull);
      final mapping = json['externalCategoryMappingContext'] as Map<String, dynamic>;
      expect(mapping['provider'], 'openfoodfacts');
      expect(mapping['externalCategoryKey'], 'en:colas');
      expect(mapping['externalCategoryName'], 'Colas');

      // Crucial: TenantId must NEVER be sent in client request
      expect(json.containsKey('tenantId'), isFalse);
    });

    test('toJson omits externalCategoryMappingContext when null', () {
      const dto = ProductCreateRequestDto(
        productName: 'Standard T-Shirt',
        productCode: 'TSH-001',
        sku: 'SKU-TSH-001',
        categoryId: 'cat-apparel',
        unitType: 'PCS',
        sellingPrice: 15.00,
        trackInventory: false,
        status: 'ACTIVE',
        externalCategoryMappingContext: null,
      );

      final json = dto.toJson();

      expect(json['productName'], 'Standard T-Shirt');
      expect(json['categoryId'], 'cat-apparel');
      expect(json.containsKey('externalCategoryMappingContext'), isFalse);
      expect(json.containsKey('tenantId'), isFalse);
    });

    test('ExternalCategoryMappingContextDto omits externalCategoryName when null', () {
      const context = ExternalCategoryMappingContextDto(
        provider: 'openfoodfacts',
        externalCategoryKey: 'en:colas',
        externalCategoryName: null,
      );

      final json = context.toJson();

      expect(json['provider'], 'openfoodfacts');
      expect(json['externalCategoryKey'], 'en:colas');
      expect(json.containsKey('externalCategoryName'), isFalse);
    });

    test('ExternalCategoryMappingContextDto fromJson parses correctly', () {
      final json = {
        'provider': 'openfoodfacts',
        'externalCategoryKey': 'en:carbonated-drinks',
        'externalCategoryName': 'Carbonated Drinks',
      };

      final context = ExternalCategoryMappingContextDto.fromJson(json);

      expect(context.provider, 'openfoodfacts');
      expect(context.externalCategoryKey, 'en:carbonated-drinks');
      expect(context.externalCategoryName, 'Carbonated Drinks');
    });
  });
}

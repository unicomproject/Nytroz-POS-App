import 'package:flutter_test/flutter_test.dart';
import 'package:nytroz_pos/features/tenant_admin/products/data/models/tenant_product_create_options_dto.dart';

void main() {
  group('TenantProductCreateOptionsDto', () {
    test('parses create options response', () {
      final dto = TenantProductCreateOptionsDto.fromJson({
        'categories': [
          {
            'categoryId': '11111111-1111-1111-1111-111111111111',
            'categoryName': 'Beverages',
            'categoryCode': 'BEV',
          },
        ],
        'subCategories': [
          {
            'subCategoryId': '22222222-2222-2222-2222-222222222222',
            'subCategoryName': 'Coffee',
            'subCategoryCode': 'COF',
            'parentCategoryId': '11111111-1111-1111-1111-111111111111',
          },
        ],
        'brands': [
          {
            'brandId': '33333333-3333-3333-3333-333333333333',
            'brandName': 'House Brand',
            'brandCode': 'HB',
          },
        ],
        'units': [
          {
            'unitId': '44444444-4444-4444-4444-444444444444',
            'unitCode': 'EA',
            'unitName': 'Each',
          },
        ],
        'taxes': [
          {
            'taxId': '55555555-5555-5555-5555-555555555555',
            'taxCode': 'VAT18',
            'taxName': 'VAT 18%',
          },
        ],
        'outlets': [
          {
            'outletId': '66666666-6666-6666-6666-666666666666',
            'outletName': 'Main Branch',
            'outletCode': 'MAIN',
          },
        ],
        'variantOptionTemplates': [
          {
            'templateId': '77777777-7777-7777-7777-777777777777',
            'templateCode': 'SIZE',
            'templateName': 'Size',
            'optionType': 'SIZE',
          },
        ],
      });

      expect(dto.categories, hasLength(1));
      expect(dto.categories.first.name, 'Beverages');
      expect(dto.subCategories.first.parentCategoryId,
          '11111111-1111-1111-1111-111111111111');
      expect(dto.brands.first.code, 'HB');
      expect(dto.units.first.code, 'EA');
      expect(dto.taxes.first.name, 'VAT 18%');
      expect(dto.outlets.first.name, 'Main Branch');
      expect(dto.variantOptionTemplates.first.optionType, 'SIZE');
    });

    test('parses empty lists', () {
      final dto = TenantProductCreateOptionsDto.fromJson({
        'categories': [],
        'subCategories': [],
        'brands': [],
        'units': [],
        'taxes': [],
        'outlets': [],
        'variantOptionTemplates': [],
      });

      expect(dto.categories, isEmpty);
      expect(dto.variantOptionTemplates, isEmpty);
    });
  });
}

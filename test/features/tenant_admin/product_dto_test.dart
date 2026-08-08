import 'package:flutter_test/flutter_test.dart';
import 'package:nytroz_pos/features/tenant_admin/products/data/models/tenant_product_dto.dart';

void main() {
  group('TenantProductListResultDto', () {
    test('parses frontend contract fields', () {
      final dto = TenantProductListResultDto.fromJson({
        'items': [
          {
            'id': '11111111-1111-1111-1111-111111111111',
            'productCode': 'PCODE-001',
            'name': 'Espresso Beans',
            'sku': 'ESP-001',
            'primaryBarcode': '1234567890',
            'categoryName': 'Coffee',
            'categoryId': '55555555-5555-5555-5555-555555555555',
            'brandId': '77777777-7777-7777-7777-777777777777',
            'brandName': 'CoffeeCorp',
            'variantCount': 3,
            'priceFrom': 1200.0,
            'priceTo': 1300.0,
            'currencyCode': 'LKR',
            'stockQuantity': 42,
            'stockStatus': 'IN_STOCK',
            'productStatus': 'Active',
            'imageUrl': 'https://example.com/product.png',
            'rowVersion': 2,
          },
        ],
        'pageNumber': 2,
        'pageSize': 10,
        'totalCount': 25,
        'catalogTotalCount': 128,
        'totalPages': 3,
      });

      expect(dto.items, hasLength(1));
      expect(dto.items.first.id, '11111111-1111-1111-1111-111111111111');
      expect(dto.items.first.productCode, 'PCODE-001');
      expect(dto.items.first.name, 'Espresso Beans');
      expect(dto.items.first.sku, 'ESP-001');
      expect(dto.items.first.variantCount, 3);
      expect(dto.items.first.priceFrom, 1200.0);
      expect(dto.items.first.priceTo, 1300.0);
      expect(dto.items.first.stockQuantity, 42);
      expect(dto.items.first.stockStatus, 'IN_STOCK');
      expect(dto.items.first.rowVersion, 2);
      expect(dto.page, 2);
      expect(dto.pageSize, 10);
      expect(dto.totalCount, 25);
      expect(dto.catalogTotalCount, 128);
    });

    test('parses backend list item shape', () {
      final dto = TenantProductListResultDto.fromJson({
        'items': [
          {
            'id': '22222222-2222-2222-2222-222222222222',
            'productCode': 'TEA-CODE',
            'name': 'Green Tea',
            'categoryName': 'Tea',
            'sku': 'TEA-001',
            'primaryBarcode': null,
            'priceFrom': 500,
            'priceTo': 500,
            'status': 'ACTIVE',
          },
        ],
        'pageNumber': 1,
        'pageSize': 10,
        'totalCount': 1,
      });

      expect(dto.items.first.id, '22222222-2222-2222-2222-222222222222');
      expect(dto.items.first.name, 'Green Tea');
      expect(dto.totalCount, 1);
    });
  });

  group('TenantProductSummaryDto', () {
    test('parses summary response fields', () {
      final dto = TenantProductSummaryDto.fromJson({
        'totalProducts': 12,
        'activeProducts': 9,
        'inactiveProducts': 3,
        'categoryCount': 4,
      });

      expect(dto.totalProducts, 12);
      expect(dto.activeProducts, 9);
      expect(dto.inactiveProducts, 3);
      expect(dto.categoryCount, 4);
    });

    test('falls back to productCategories field', () {
      final dto = TenantProductSummaryDto.fromJson({
        'totalProducts': 5,
        'activeProducts': 4,
        'inactiveProducts': 1,
        'productCategories': 2,
      });

      expect(dto.categoryCount, 2);
    });
  });
}

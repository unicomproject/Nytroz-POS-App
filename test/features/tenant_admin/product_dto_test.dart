import 'package:flutter_test/flutter_test.dart';
import 'package:nytroz_pos/features/tenant_admin/products/data/models/tenant_product_dto.dart';

void main() {
  group('TenantProductListResultDto', () {
    test('parses frontend contract fields', () {
      final dto = TenantProductListResultDto.fromJson({
        'items': [
          {
            'productId': '11111111-1111-1111-1111-111111111111',
            'productName': 'Espresso Beans',
            'sku': 'ESP-001',
            'barcode': '1234567890',
            'categoryName': 'Coffee',
            'sellingPrice': 1250.5,
            'currencyCode': 'LKR',
            'stockQuantity': 42,
            'status': 'Active',
            'imageUrl': 'https://example.com/product.png',
          },
        ],
        'page': 2,
        'pageSize': 10,
        'totalItems': 25,
        'totalPages': 3,
      });

      expect(dto.items, hasLength(1));
      expect(dto.items.first.id, '11111111-1111-1111-1111-111111111111');
      expect(dto.items.first.name, 'Espresso Beans');
      expect(dto.items.first.sku, 'ESP-001');
      expect(dto.items.first.sellingPrice, 1250.5);
      expect(dto.items.first.stockQuantity, 42);
      expect(dto.page, 2);
      expect(dto.pageSize, 10);
      expect(dto.totalCount, 25);
    });

    test('parses backend list item shape', () {
      final dto = TenantProductListResultDto.fromJson({
        'summary': {
          'totalProducts': 1,
          'activeProducts': 1,
          'inactiveProducts': 0,
          'productCategories': 1,
        },
        'items': [
          {
            'id': '22222222-2222-2222-2222-222222222222',
            'name': 'Green Tea',
            'categoryName': 'Tea',
            'sku': 'TEA-001',
            'barcode': null,
            'sellingPrice': 500,
            'status': 'ACTIVE',
            'outletCount': 0,
          },
        ],
        'page': 1,
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

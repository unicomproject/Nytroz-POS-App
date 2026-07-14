import 'package:flutter_test/flutter_test.dart';
import 'package:nytroz_pos/features/tenant_admin/products/data/models/tenant_product_detail_dto.dart';

void main() {
  group('TenantProductDetailDto', () {
    test('parses backend product detail response', () {
      final dto = TenantProductDetailDto.fromJson({
        'productId': '11111111-1111-1111-1111-111111111111',
        'productName': 'Espresso Beans',
        'sku': 'ESP-001',
        'barcode': '1234567890',
        'categoryId': '22222222-2222-2222-2222-222222222222',
        'categoryName': 'Coffee',
        'subCategoryId': '33333333-3333-3333-3333-333333333333',
        'brandId': '44444444-4444-4444-4444-444444444444',
        'unitType': 'KG',
        'shortDescription': 'Fresh roast',
        'imageUrl': 'https://example.com/product.png',
        'costPrice': 900,
        'sellingPrice': 1250.5,
        'discountPrice': 1100,
        'taxId': '55555555-5555-5555-5555-555555555555',
        'taxName': 'VAT 8%',
        'status': 'ACTIVE',
        'trackInventory': true,
        'stock': {
          'openingStockQuantity': 10,
          'minimumStockAlertQuantity': 2,
          'maximumStockQuantity': 100,
          'stockUnit': 'KG',
          'onHandQuantity': 42,
          'availableQuantity': 40,
        },
        'outlets': [
          {
            'outletId': '66666666-6666-6666-6666-666666666666',
            'outletName': 'Main Outlet',
            'outletCode': 'OUT-01',
            'onHandQuantity': 20,
            'availableQuantity': 18,
          },
        ],
        'variants': [
          {
            'variantId': '77777777-7777-7777-7777-777777777777',
            'variantName': '250g Pack',
            'sku': 'ESP-001-250',
            'barcode': '9876543210',
            'sellingPrice': 650,
            'discountPrice': 600,
            'status': 'ACTIVE',
          },
        ],
        'batchDetails': {
          'batchNumber': 'BATCH-001',
          'manufactureDate': '2026-01-15',
          'expiryDate': '2026-12-31',
          'expiryAlertDays': 30,
        },
        'createdAt': '2026-03-01T10:00:00Z',
        'updatedAt': '2026-03-02T12:30:00Z',
      });

      expect(dto.productId, '11111111-1111-1111-1111-111111111111');
      expect(dto.productName, 'Espresso Beans');
      expect(dto.sku, 'ESP-001');
      expect(dto.categoryName, 'Coffee');
      expect(dto.unitType, 'KG');
      expect(dto.sellingPrice, 1250.5);
      expect(dto.trackInventory, isTrue);
      expect(dto.stock?.onHandQuantity, 42);
      expect(dto.outlets, hasLength(1));
      expect(dto.outlets.first.outletName, 'Main Outlet');
      expect(dto.variants, hasLength(1));
      expect(dto.variants.first.variantName, '250g Pack');
      expect(dto.batchDetails?.batchNumber, 'BATCH-001');
    });
  });
}

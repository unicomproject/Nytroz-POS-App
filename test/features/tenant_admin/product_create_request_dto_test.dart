import 'package:flutter_test/flutter_test.dart';
import 'package:nytroz_pos/features/tenant_admin/products/data/models/product_create_request_dto.dart';

void main() {
  group('ProductCreateRequestDto', () {
    test('maps create request to backend payload', () {
      const dto = ProductCreateRequestDto(
        productName: 'Espresso Beans',
        sku: 'ESP-001',
        barcode: '1234567890',
        categoryId: '11111111-1111-1111-1111-111111111111',
        subCategoryId: '22222222-2222-2222-2222-222222222222',
        brandId: '33333333-3333-3333-3333-333333333333',
        unitType: 'EA',
        shortDescription: 'Fresh roast',
        sellingPrice: 1250,
        taxId: '44444444-4444-4444-4444-444444444444',
        trackInventory: true,
        openingStockQuantity: 10,
        minimumStockAlertQuantity: 2,
        stockUnit: 'EA',
        outletIds: ['55555555-5555-5555-5555-555555555555'],
        status: 'ACTIVE',
      );

      expect(dto.toJson(), {
        'productName': 'Espresso Beans',
        'sku': 'ESP-001',
        'barcode': '1234567890',
        'categoryId': '11111111-1111-1111-1111-111111111111',
        'subCategoryId': '22222222-2222-2222-2222-222222222222',
        'brandId': '33333333-3333-3333-3333-333333333333',
        'unitType': 'EA',
        'shortDescription': 'Fresh roast',
        'sellingPrice': 1250,
        'taxId': '44444444-4444-4444-4444-444444444444',
        'trackInventory': true,
        'openingStockQuantity': 10,
        'minimumStockAlertQuantity': 2,
        'stockUnit': 'EA',
        'outletIds': ['55555555-5555-5555-5555-555555555555'],
        'hasVariants': false,
        'hasExpiryDate': false,
        'status': 'ACTIVE',
        'saveAsDraft': false,
      });
    });
  });
}

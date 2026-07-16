// ignore_for_file: prefer_const_constructors
import 'package:flutter_test/flutter_test.dart';
import 'package:nytroz_pos/features/tenant_admin/products/data/models/product_create_request_dto.dart';

void main() {
  group('ProductCreateRequestDto update payload', () {
    test('maps update request with optional pricing and variants', () {
      const dto = ProductCreateRequestDto(
        productName: 'Espresso Beans',
        sku: 'ESP-001',
        categoryId: '11111111-1111-1111-1111-111111111111',
        unitType: 'EA',
        costPrice: 900,
        sellingPrice: 1250,
        discountPrice: 1100,
        trackInventory: true,
        openingStockQuantity: 10,
        minimumStockAlertQuantity: 2,
        maximumStockQuantity: 100,
        stockUnit: 'EA',
        outletIds: ['55555555-5555-5555-5555-555555555555'],
        hasVariants: true,
        variants: [
          ProductVariantRequestDto(
            variantName: '250g Pack',
            sku: 'ESP-001-250',
            sellingPrice: 650,
            status: 'ACTIVE',
          ),
        ],
        hasExpiryDate: true,
        batchNumber: 'BATCH-001',
        manufactureDate: '2026-01-15',
        expiryDate: '2026-12-31',
        expiryAlertDays: 30,
        status: 'ACTIVE',
      );

      expect(dto.toJson(), {
        'productName': 'Espresso Beans',
        'sku': 'ESP-001',
        'categoryId': '11111111-1111-1111-1111-111111111111',
        'unitType': 'EA',
        'costPrice': 900,
        'sellingPrice': 1250,
        'discountPrice': 1100,
        'trackInventory': true,
        'openingStockQuantity': 10,
        'minimumStockAlertQuantity': 2,
        'maximumStockQuantity': 100,
        'stockUnit': 'EA',
        'outletIds': ['55555555-5555-5555-5555-555555555555'],
        'hasVariants': true,
        'variants': [
          {
            'variantName': '250g Pack',
            'sku': 'ESP-001-250',
            'sellingPrice': 650,
            'status': 'ACTIVE',
          },
        ],
        'hasExpiryDate': true,
        'batchNumber': 'BATCH-001',
        'manufactureDate': '2026-01-15',
        'expiryDate': '2026-12-31',
        'expiryAlertDays': 30,
        'status': 'ACTIVE',
        'saveAsDraft': false,
      });
    });
  });
}

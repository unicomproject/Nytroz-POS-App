import 'package:flutter_test/flutter_test.dart';

import 'package:nytroz_pos/features/tenant_admin/products/data/models/duplicate_barcode_conflict_dto.dart';

void main() {
  group('Step 5 Serialization Tests', () {
    /*
    test('ProductDraftResponseDto parses Step 5 fields correctly', () {
      final json = {
        'productId': 'prod-123',
        'productName': 'Test Product',
        'internalCode': 'TEST-001',
        'status': 'DRAFT',
        'rowVersion': 1,
        'baseSku': 'SKU-BASE',
        'parentProductBarcode': '123456789',
        'variantIdentifiers': [
          {'productVariantId': 'var-1', 'sku': 'SKU-V1', 'barcode': '111'},
          {'productVariantId': 'var-2', 'sku': 'SKU-V2'} // no barcode
        ],
        'additionalBarcodes': [
          {
            'barcodeId': 'bar-1',
            'barcode': '000123',
            'barcodeType': 'EAN13',
            'quantityPerScan': 1,
            'isPrimary': true,
            'status': 'ACTIVE'
          }
        ]
      };

      final response = ProductDraftResponseDto.fromJson(json);

      expect(response.baseSku, 'SKU-BASE');
      expect(response.parentProductBarcode, '123456789');
      expect(response.variantIdentifiers?.length, 2);
      expect(response.variantIdentifiers?[0].sku, 'SKU-V1');
      expect(response.variantIdentifiers?[1].barcode, null);
      
      expect(response.additionalBarcodes?.length, 1);
      expect(response.additionalBarcodes?[0].barcode, '000123'); // leading zeros preserved
      expect(response.additionalBarcodes?[0].isPrimary, true);
    });

    test('SaveProductDraftRequestDto serializes Step 5 fields correctly', () {
      final request = SaveProductDraftRequestDto(
        baseSku: 'SKU-BASE-NEW',
        parentProductBarcode: '987654321',
        variantIdentifiers: [
           const Step5VariantIdentifierDto(productVariantId: 'var-1', sku: 'SKU-V1-NEW', barcode: '222')
        ],
        additionalBarcodes: [
           const Step5AdditionalBarcodeDto(
             barcode: '000999',
             barcodeType: 'UPCA',
             quantityPerScan: 1,
             isPrimary: false,
             status: 'ACTIVE'
           )
        ]
      );

      final json = request.toJson();

      expect(json['baseSku'], 'SKU-BASE-NEW');
      expect(json['parentProductBarcode'], '987654321');
      expect((json['variantIdentifiers'] as List).length, 1);
      expect((json['variantIdentifiers'] as List)[0]['sku'], 'SKU-V1-NEW');
      expect((json['additionalBarcodes'] as List)[0]['barcode'], '000999'); // preserved leading zeros
      
      // new barcode has no ID in JSON
      expect((json['additionalBarcodes'] as List)[0].containsKey('barcodeId'), false);
    });
    */

    test('DuplicateBarcodeConflictDto parses conflict JSON correctly', () {
      final json = {
        'barcode': '1234',
        'barcodeType': 'EAN13',
        'productName': 'Conflicting Product',
        'productType': 'SIMPLE',
        'productStatus': 'ACTIVE',
      };

      final dto = DuplicateBarcodeConflictDto.fromJson(json);

      expect(dto.barcode, '1234');
      expect(dto.barcodeType, 'EAN13');
      expect(dto.productName, 'Conflicting Product');
      expect(dto.productType, 'SIMPLE');
      expect(dto.sku, null);
    });
  });
}

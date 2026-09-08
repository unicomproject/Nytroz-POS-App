import 'package:flutter_test/flutter_test.dart';

import 'package:nytroz_pos/features/tenant_admin/products/data/models/duplicate_barcode_conflict_dto.dart';
import 'package:nytroz_pos/features/tenant_admin/products/data/models/step5_barcode_dtos.dart';

void main() {
  group('Step 5 Serialization Tests', () {
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

    test('BarcodeSkuAssignmentDto round-trips barcodeType and leading-zero barcode', () {
      final dto = BarcodeSkuAssignmentDto(
        clientCombinationKey: 'color:blue|size:500ml',
        productVariantId: '11111111-1111-1111-1111-111111111111',
        displayName: 'AquaFlow — Blue / 500ml',
        sku: 'AQF-BLU-500',
        barcode: '0200001111001',
        barcodeType: 'EAN13',
        isAssigned: true,
      );

      final json = dto.toJson();
      expect(json['barcode'], '0200001111001');
      expect(json['barcodeType'], 'EAN13');
      expect(json.containsKey('status'), isFalse);

      final fromString = BarcodeSkuAssignmentDto.fromJson({
        ...json,
        'barcode': '0200001111001',
      });
      expect(fromString.barcode, '0200001111001');
      expect(fromString.barcodeType, 'EAN13');
      // Never treat barcode as numeric in API contract — string parse preserves zeros.
      expect(fromString.barcode!.startsWith('0'), isTrue);
    });

    test('BarcodeSkuConfigurationDto parses assignment barcodeType', () {
      final config = BarcodeSkuConfigurationDto.fromJson({
        'assignments': [
          {
            'clientCombinationKey': 'k1',
            'productVariantId': 'v1',
            'sku': 'SKU-1',
            'barcode': '4006381333931',
            'barcodeType': 'EAN13',
            'status': 'COMPLETE',
          }
        ],
      });

      expect(config.assignments, isNotNull);
      expect(config.assignments!.single.barcodeType, 'EAN13');
      expect(config.assignments!.single.barcode, '4006381333931');
    });
  });
}

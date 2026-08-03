import 'package:flutter_test/flutter_test.dart';
import 'package:nytroz_pos/features/cart/domain/entities/pos_barcode_lookup_result.dart';

void main() {
  group('PosBarcodeLookupResult parsing & mapping tests', () {
    test('successfully parses imageUrl from json and maps to resolved sale item', () {
      final json = {
        'productId': 'prod-123',
        'variantId': 'var-456',
        'barcode': '123456789',
        'barcodeType': 'EAN13',
        'productName': 'Running Shoes',
        'variantName': 'Red - 10',
        'sku': 'RUN-RED-10',
        'quantityPerScan': 1,
        'price': 9900,
        'availableQuantity': 15.0,
        'stockStatus': 'InStock',
        'imageUrl': 'https://example.com/shoes.png',
      };

      final result = PosBarcodeLookupResult.fromJson(json);

      expect(result.productId, 'prod-123');
      expect(result.variantId, 'var-456');
      expect(result.imageUrl, 'https://example.com/shoes.png');

      final saleItem = result.toResolvedSaleItem();
      expect(saleItem.imageUrl, 'https://example.com/shoes.png');
    });

    test('successfully parses imageStorageKey as fallback from json and maps to resolved sale item', () {
      final json = {
        'productId': 'prod-123',
        'variantId': 'var-456',
        'barcode': '123456789',
        'barcodeType': 'EAN13',
        'productName': 'Running Shoes',
        'variantName': 'Red - 10',
        'sku': 'RUN-RED-10',
        'quantityPerScan': 1,
        'price': 9900,
        'availableQuantity': 15.0,
        'stockStatus': 'InStock',
        'imageStorageKey': 'storage/shoes.png',
      };

      final result = PosBarcodeLookupResult.fromJson(json);

      expect(result.productId, 'prod-123');
      expect(result.variantId, 'var-456');
      expect(result.imageUrl, 'storage/shoes.png');

      final saleItem = result.toResolvedSaleItem();
      expect(saleItem.imageUrl, 'storage/shoes.png');
    });
  });
}

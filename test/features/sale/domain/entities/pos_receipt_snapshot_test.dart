import 'package:flutter_test/flutter_test.dart';
import 'package:nytroz_pos/features/sale/domain/entities/pos_receipt_snapshot.dart';

void main() {
  group('PosReceiptSnapshot', () {
    test('parses full json payload correctly', () {
      const jsonStr = '''
      {
        "contractVersion": "1.0",
        "templateVersionId": "tv_123",
        "branding": {
          "merchantName": "Test Merchant"
        },
        "receiptIdentity": {
          "receiptId": "r_123",
          "receiptNumber": "R-100",
          "issuedAt": "2026-08-05T12:00:00Z"
        },
        "operator": {
          "cashierName": "Alice"
        },
        "items": [
          {
            "productName": "Apple",
            "quantity": 2,
            "unitPrice": 100,
            "discount": 0,
            "tax": 0,
            "lineTotal": 200
          }
        ],
        "totals": {
          "subtotal": 200,
          "discount": 0,
          "tax": 0,
          "charges": 0,
          "rounding": 0,
          "total": 200,
          "paid": 200,
          "cashReceived": 200,
          "changeDue": 0
        },
        "tenders": [
          {
            "paymentMethod": "Cash",
            "amount": 200
          }
        ],
        "presentation": {
          "barcodeVisibility": true,
          "qrVisibility": false
        },
        "copyPolicy": {
          "printMerchantCopy": false,
          "printCustomerCopy": true
        }
      }
      ''';

      final snapshot = PosReceiptSnapshot.parse(jsonStr);

      expect(snapshot, isNotNull);
      expect(snapshot!.contractVersion, '1.0');
      expect(snapshot.templateVersionId, 'tv_123');
      expect(snapshot.branding.merchantName, 'Test Merchant');
      expect(snapshot.receiptIdentity.receiptId, 'r_123');
      expect(snapshot.receiptIdentity.issuedAt.year, 2026);
      expect(snapshot.operatorDetails.cashierName, 'Alice');
      expect(snapshot.items.length, 1);
      expect(snapshot.items.first.productName, 'Apple');
      expect(snapshot.totals.total, 200);
      expect(snapshot.tenders.first.paymentMethod, 'Cash');
      expect(snapshot.presentation.barcodeVisibility, isTrue);
      expect(snapshot.copyPolicy.printCustomerCopy, isTrue);
    });

    test('handles missing optional fields gracefully', () {
      const jsonStr = '''
      {
        "contractVersion": "1.0",
        "branding": {},
        "receiptIdentity": {
          "receiptId": "r_123",
          "receiptNumber": "R-100",
          "issuedAt": "2026-08-05T12:00:00Z"
        },
        "operator": {},
        "items": [],
        "totals": {
          "subtotal": 0,
          "discount": 0,
          "tax": 0,
          "charges": 0,
          "rounding": 0,
          "total": 0,
          "paid": 0,
          "cashReceived": 0,
          "changeDue": 0
        },
        "tenders": [],
        "presentation": {
          "barcodeVisibility": false,
          "qrVisibility": false
        },
        "copyPolicy": {
          "printMerchantCopy": false,
          "printCustomerCopy": true
        }
      }
      ''';

      final snapshot = PosReceiptSnapshot.parse(jsonStr);

      expect(snapshot, isNotNull);
      expect(snapshot!.templateVersionId, isNull);
      expect(snapshot.branding.merchantName, isNull);
      expect(snapshot.items, isEmpty);
      expect(snapshot.tenders, isEmpty);
    });

    test('returns null for invalid json string', () {
      final snapshot = PosReceiptSnapshot.parse('invalid json');
      expect(snapshot, isNull);
    });

    test('returns null for empty json string', () {
      final snapshot = PosReceiptSnapshot.parse('');
      expect(snapshot, isNull);
    });
  });
}

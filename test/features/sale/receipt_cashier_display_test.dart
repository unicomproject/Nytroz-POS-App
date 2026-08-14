import 'package:flutter_test/flutter_test.dart';
import 'package:nytroz_pos/features/sale/presentation/utils/receipt_cashier_display.dart';

void main() {
  group('resolveReceiptCashierDisplayName', () {
    test('prefers snapshot cashier name over session email', () {
      const receiptJson = '''
      {
        "contractVersion": "1.0",
        "receiptIdentity": {
          "receiptId": "r1",
          "receiptNumber": "RCP-1",
          "issuedAt": "2026-08-14T07:21:00.000Z"
        },
        "operator": {
          "cashierName": "Kavin"
        },
        "items": [],
        "totals": {
          "subtotal": 0,
          "discountTotal": 0,
          "taxTotal": 0,
          "grandTotal": 0
        },
        "tenders": [],
        "presentation": {},
        "copyPolicy": {}
      }
      ''';

      expect(
        resolveReceiptCashierDisplayName(
          receiptDataJson: receiptJson,
          paymentCashierName: 'cashier001@gmail.com',
          sessionDisplayName: 'cashier001@gmail.com',
        ),
        'Kavin',
      );
    });

    test('falls back to payment cashier name when not email-like', () {
      expect(
        resolveReceiptCashierDisplayName(
          paymentCashierName: 'Kavin',
          sessionDisplayName: 'cashier001@gmail.com',
        ),
        'Kavin',
      );
    });

    test('uses session display name when only email-like values exist', () {
      expect(
        resolveReceiptCashierDisplayName(
          sessionDisplayName: 'cashier001@gmail.com',
        ),
        'cashier001@gmail.com',
      );
    });
  });
}

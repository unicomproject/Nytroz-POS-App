import 'package:flutter_test/flutter_test.dart';
import 'package:nytroz_pos/features/receipts/domain/historical_return_receipt_mapper.dart';
import 'package:nytroz_pos/features/receipts/domain/receipt_history_models.dart';

void main() {
  test('maps authoritative exchange snapshot without financial recalculation',
      () {
    final detail = ReceiptDetail.fromJson({
      'receiptId': 'receipt-1',
      'saleId': 'sale-1',
      'receiptNumber': 'EX-100',
      'saleNumber': 'SALE-100',
      'receiptType': 'EXCHANGE',
      'receiptStatus': 'ISSUED',
      'issuedAt': '2026-07-29T10:00:00Z',
      'cashierName': 'Cashier',
      'cashierUserId': 'user-1',
      'tillName': 'Till 01',
      'tillId': 'till-1',
      'outletName': 'Main outlet',
      'outletId': 'outlet-1',
      'paymentMethod': 'No settlement',
      'currencyCode': 'LKR',
      'subtotalAmount': 1500,
      'discountAmount': 0,
      'taxAmount': 0,
      'totalAmount': 1500,
      'paidAmount': 0,
      'changeAmount': 0,
      'items': const [],
      'reprintCount': 0,
      'historicalSnapshot': {
        'returnId': 'return-1',
        'returnNumber': 'RET-100',
        'exchangeId': 'exchange-1',
        'exchangeNumber': 'EX-100',
        'returnValue': 1250,
        'replacementValue': 1500,
        'difference': 250,
        'differenceDirection': 'CUSTOMER_PAYS',
        'settlementMethodCode': 'CASH_PAYMENT',
        'returnedItems': [
          {
            'name': 'Old product',
            'quantity': 1,
            'unitPrice': 1250,
            'total': 1250,
          }
        ],
        'replacementItems': [
          {
            'name': 'New product',
            'quantity': 1,
            'unitPrice': 1500,
            'total': 1500,
          }
        ],
      },
    });

    final receipt = mapHistoricalNonSaleReceipt(detail);

    expect(receipt.isExchange, isTrue);
    expect(receipt.returnItemValue, 1250);
    expect(receipt.replacementItemValue, 1500);
    expect(receipt.differenceAmount, 250);
    expect(receipt.amountPaidByCustomer, 250);
    expect(receipt.returnedItems.single.total, 1250);
    expect(receipt.replacementItems.single.total, 1500);
  });
}

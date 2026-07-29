import 'package:flutter_test/flutter_test.dart';
import 'package:nytroz_pos/features/hardware/receipt_printer/models/completed_sale_receipt.dart';
import 'package:nytroz_pos/features/hardware/receipt_printer/recovery/print_operation.dart';

void main() {
  test('durable operation preserves receipt identity and unknown state', () {
    final now = DateTime.utc(2026, 7, 28);
    final operation = PrintOperation(
      operationId: 'operation-1',
      receipt: CompletedSaleReceipt(
        receiptId: 'receipt-1',
        saleId: 'sale-1',
        receiptNumber: 'R-1',
        completedAt: now,
        merchantName: 'OneVerz',
        outletName: 'Main',
        tillId: 'till-1',
        tillName: 'Till 1',
        cashierId: 'cashier-1',
        cashierName: 'Cashier',
        deviceId: 'device-1',
        currency: 'LKR',
        items: const [],
        subtotal: 100,
        discountTotal: 0,
        taxTotal: 0,
        total: 100,
        paymentMethods: const ['CASH'],
        amountTendered: 100,
        change: 0,
      ),
      printRequestId: 'request-1',
      operatorUserId: 'cashier-1',
      deviceId: 'device-1',
      createdAt: now,
      updatedAt: now,
      state: PrintOperationState.printOutcomeUnknown,
      physicalAttemptCount: 1,
    );

    final restored = PrintOperation.fromJson(operation.toJson());

    expect(restored.state, PrintOperationState.printOutcomeUnknown);
    expect(restored.printRequestId, 'request-1');
    expect(restored.receipt.receiptId, 'receipt-1');
    expect(restored.physicalAttemptCount, 1);
  });
}

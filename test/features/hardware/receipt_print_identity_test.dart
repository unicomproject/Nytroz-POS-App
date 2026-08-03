import 'package:flutter_test/flutter_test.dart';
import 'package:nytroz_pos/features/hardware/receipt_printer/receipt_print_identity.dart';

void main() {
  group('ReceiptPrintIdentity Tests', () {
    test('Same input produces the identical deterministic identity string', () {
      final id1 = ReceiptPrintIdentity.forCopy(
        operationId: 'op-123',
        receiptPurpose: 'cashSale',
        copyType: 'CUSTOMER',
        copyIndex: 1,
      );

      final id2 = ReceiptPrintIdentity.forCopy(
        operationId: 'op-123',
        receiptPurpose: 'cashSale',
        copyType: 'CUSTOMER',
        copyIndex: 1,
      );

      expect(id1, id2);
      expect(
          id1,
          matches(RegExp(
              r'^[a-f0-9]{8}-[a-f0-9]{4}-4[a-f0-9]{3}-[a-f0-9]{4}-[a-f0-9]{12}$')));
    });

    test('Different inputs produce different identities (no collision)', () {
      final base = ReceiptPrintIdentity.forCopy(
        operationId: 'op-123',
        receiptPurpose: 'cashSale',
        copyType: 'CUSTOMER',
        copyIndex: 1,
      );

      // Change operation ID
      final diffOp = ReceiptPrintIdentity.forCopy(
        operationId: 'op-124',
        receiptPurpose: 'cashSale',
        copyType: 'CUSTOMER',
        copyIndex: 1,
      );

      // Change purpose
      final diffPurpose = ReceiptPrintIdentity.forCopy(
        operationId: 'op-123',
        receiptPurpose: 'refund',
        copyType: 'CUSTOMER',
        copyIndex: 1,
      );

      // Change copy type
      final diffCopyType = ReceiptPrintIdentity.forCopy(
        operationId: 'op-123',
        receiptPurpose: 'cashSale',
        copyType: 'MERCHANT',
        copyIndex: 1,
      );

      // Change copy index
      final diffIndex = ReceiptPrintIdentity.forCopy(
        operationId: 'op-123',
        receiptPurpose: 'cashSale',
        copyType: 'CUSTOMER',
        copyIndex: 2,
      );

      expect(base, isNot(diffOp));
      expect(base, isNot(diffPurpose));
      expect(base, isNot(diffCopyType));
      expect(base, isNot(diffIndex));
    });

    test(
        'ReceiptPrintIdentity.generate produces stable deterministic UUID format',
        () {
      final uuid1 = ReceiptPrintIdentity.generate('test-data-string-1');
      final uuid2 = ReceiptPrintIdentity.generate('test-data-string-1');
      final uuid3 = ReceiptPrintIdentity.generate('test-data-string-2');

      expect(uuid1, uuid2);
      expect(uuid1, isNot(uuid3));
      expect(
          uuid1,
          matches(RegExp(
              r'^[a-f0-9]{8}-[a-f0-9]{4}-4[a-f0-9]{3}-[a-f0-9]{4}-[a-f0-9]{12}$')));
    });
  });
}

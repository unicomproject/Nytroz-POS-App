import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nytroz_pos/features/sale/domain/entities/pos_checkout_summary.dart';
import 'package:nytroz_pos/features/sale/domain/entities/pos_receipt_snapshot.dart';
import 'package:nytroz_pos/features/sale/presentation/providers/pos_cash_payment_success_provider.dart';

void main() {
  group('cash checkout values', () {
    test('receipt snapshot reads backend PascalCase Cash tender fields', () {
      final snapshot = PosReceiptSnapshot.fromJson(const {
        'tenders': [
          {'MethodName': 'Cash', 'Amount': 2800},
        ],
      });

      expect(snapshot.tenders.single.paymentMethod, 'Cash');
      expect(snapshot.tenders.single.amount, 2800);
    });

    test('checkout payload parser reads cashReceived and changeDue', () {
      final payload = PosCheckoutStartPaymentPayload.fromJson(const {
        'checkoutSessionId': 'sale-1',
        'saleId': 'sale-1',
        'saleNumber': 'S-001',
        'paymentMethod': 'cash',
        'grandTotal': 19250,
        'currency': 'LKR',
        'saleStatus': 'completed',
        'nextAction': 'completed',
        'receiptNumber': 'R-001',
        'barcodeValue': 'R-001',
        'subtotal': 19250,
        'discountTotal': 0,
        'taxTotal': 0,
        'cashReceived': 20000,
        'changeDue': 750,
        'items': [],
      });

      expect(payload.cashReceived, 20000);
      expect(payload.changeDue, 750);
    });

    test('payment success state keeps backend cashReceived and changeDue', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final payload = PosCheckoutStartPaymentPayload.fromJson(const {
        'checkoutSessionId': 'sale-1',
        'saleId': 'sale-1',
        'saleNumber': 'S-001',
        'paymentMethod': 'cash',
        'grandTotal': 19250,
        'currency': 'LKR',
        'saleStatus': 'completed',
        'nextAction': 'completed',
        'receiptNumber': 'R-001',
        'barcodeValue': 'R-001',
        'subtotal': 19250,
        'discountTotal': 0,
        'taxTotal': 0,
        'cashReceived': 20000,
        'changeDue': 750,
        'items': [],
      });

      container
          .read(posCashPaymentSuccessProvider.notifier)
          .recordCheckoutPayment(payload);
      final successData = container.read(posCashPaymentSuccessProvider);

      expect(successData?.cashReceived, 20000);
      expect(successData?.changeDue, 750);
    });
  });
}

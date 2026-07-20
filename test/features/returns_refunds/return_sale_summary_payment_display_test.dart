import 'package:flutter_test/flutter_test.dart';
import 'package:nytroz_pos/features/returns_refunds/domain/entities/return_sale_summary.dart';

void main() {
  group('ReturnSaleSummary.paymentDisplay', () {
    test('renders backend masked reference for Step 1', () {
      final sale = ReturnSaleSummary.fromJson({
        'saleId': '11111111-1111-4111-8111-111111111111',
        'invoiceNo': 'RCP-1',
        'customerName': 'Ada',
        'phone': '0770000000',
        'paymentMethod': 'Visa',
        'maskedCard': '•••• 4242',
        'total': 1000,
        'itemCount': 1,
        'currency': 'LKR',
      });

      expect(sale.paymentDisplay, 'Visa •••• 4242');
    });

    test('does not fabricate mask when backend omits maskedCard', () {
      final sale = ReturnSaleSummary.fromJson({
        'saleId': '11111111-1111-4111-8111-111111111111',
        'invoiceNo': 'RCP-1',
        'customerName': 'Ada',
        'phone': '0770000000',
        'paymentMethod': 'Visa',
        'maskedCard': '',
        'total': 1000,
        'itemCount': 1,
        'currency': 'LKR',
      });

      expect(sale.paymentDisplay, 'Visa');
      expect(sale.paymentDisplay.contains('••••'), isFalse);
    });

    test('cash shows method only without fake digits', () {
      final sale = ReturnSaleSummary.fromJson({
        'saleId': '11111111-1111-4111-8111-111111111111',
        'invoiceNo': 'RCP-1',
        'customerName': 'Ada',
        'phone': '0770000000',
        'paymentMethod': 'Cash',
        'maskedCard': '',
        'total': 1000,
        'itemCount': 1,
        'currency': 'LKR',
      });

      expect(sale.paymentDisplay, 'Cash');
      expect(sale.paymentDisplay.contains(RegExp(r'\d{4}')), isFalse);
    });
  });
}

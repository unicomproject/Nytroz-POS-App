import 'package:flutter_test/flutter_test.dart';
import 'package:nytroz_pos/features/returns_refunds/domain/entities/return_sale_eligibility.dart';

void main() {
  group('ReturnSaleEligibility', () {
    test('fromJson parses eligibility check summary fields', () {
      final result = ReturnSaleEligibility.fromJson({
        'saleId': 'e06a0d4b-8e7a-4f50-a026-da0e6fea6441',
        'invoiceNo': 'RCP-000036',
        'customerName': 'John Perera',
        'paymentMethod': 'Cash',
        'maskedCard': '',
        'currency': 'LKR',
        'overallStatus': 'ELIGIBLE_WITH_WARNINGS',
        'canContinue': true,
        'eligibleItemCount': 2,
        'selectedItemCount': 3,
        'overallMessage': 'Eligible with review required.',
        'policyNote': 'Final approval will be confirmed during inspection.',
        'items': [
          {
            'saleLineId': '1306a674-82af-4d1e-a481-ee03b8999e1a',
            'variantId': 'cccc0005-0003-4000-8000-000000000001',
            'name': 'Match Shorts - Small',
            'sku': 'MER-003-S',
            'soldQty': 1,
            'returnedQty': 0,
            'availableReturnQty': 1,
            'unitPrice': 2800,
            'lineTotal': 2800,
            'isReturnable': true,
            'eligibilityStatus': 'ELIGIBLE',
            'requestedReturnQty': 1,
            'eligibleReturnQty': 1,
          },
        ],
        'policyChecks': [
          {
            'label': 'Return Window',
            'value': 'Within 30 days of purchase',
            'passed': true,
            'code': 'RETURN_WINDOW',
            'description': 'Within 30 days of purchase',
            'status': 'PASSED',
            'severity': 'INFO',
            'requiresReview': false,
          },
          {
            'label': 'Manager Approval Requirement',
            'value': 'Manager approval required by return policy',
            'passed': false,
            'code': 'MANAGER_APPROVAL_REQUIRED',
            'description': 'Preliminary policy flag only',
            'status': 'REQUIRES_REVIEW',
            'severity': 'WARNING',
            'reason':
                'Manager approval will be required before return completion.',
            'requiresReview': true,
          },
        ],
      });

      expect(result.overallStatus, 'ELIGIBLE_WITH_WARNINGS');
      expect(result.canContinue, isTrue);
      expect(result.eligibleItemCount, 2);
      expect(result.selectedItemCount, 3);
      expect(result.policyNote, isNotNull);
      expect(result.policyChecks, hasLength(2));
      expect(result.policyChecks.first.code, 'RETURN_WINDOW');
      expect(result.policyChecks.last.displayStatus, 'REQUIRES_REVIEW');
      expect(result.items.single.requestedReturnQty, 1);
      expect(result.statusDisplayLabel, 'Eligible to Continue');
      expect(result.hasWarnings, isTrue);
    });

    test('paymentDisplay uses backend maskedCard without fabricating digits',
        () {
      final withMask = ReturnSaleEligibility.fromJson({
        'saleId': 'e06a0d4b-8e7a-4f50-a026-da0e6fea6441',
        'invoiceNo': 'RCP-000036',
        'customerName': 'John Perera',
        'paymentMethod': 'Visa',
        'maskedCard': '•••• 4242',
        'currency': 'LKR',
        'overallStatus': 'ELIGIBLE',
        'canContinue': true,
        'eligibleItemCount': 1,
        'selectedItemCount': 1,
        'overallMessage': 'Eligible',
        'items': <Map<String, dynamic>>[],
        'policyChecks': <Map<String, dynamic>>[],
      });
      expect(withMask.paymentDisplay, 'Visa •••• 4242');

      final cash = ReturnSaleEligibility.fromJson({
        'saleId': 'e06a0d4b-8e7a-4f50-a026-da0e6fea6441',
        'invoiceNo': 'RCP-000036',
        'customerName': 'John Perera',
        'paymentMethod': 'Cash',
        'maskedCard': '',
        'currency': 'LKR',
        'overallStatus': 'ELIGIBLE',
        'canContinue': true,
        'eligibleItemCount': 1,
        'selectedItemCount': 1,
        'overallMessage': 'Eligible',
        'items': <Map<String, dynamic>>[],
        'policyChecks': <Map<String, dynamic>>[],
      });
      expect(cash.paymentDisplay, 'Cash');
      expect(cash.paymentDisplay.contains('••••'), isFalse);
      expect(cash.paymentDisplay.contains(RegExp(r'\d{4}')), isFalse);

      final cardWithoutMask = ReturnSaleEligibility.fromJson({
        'saleId': 'e06a0d4b-8e7a-4f50-a026-da0e6fea6441',
        'invoiceNo': 'RCP-000036',
        'customerName': 'John Perera',
        'paymentMethod': 'Visa',
        'maskedCard': '',
        'currency': 'LKR',
        'overallStatus': 'ELIGIBLE',
        'canContinue': true,
        'eligibleItemCount': 1,
        'selectedItemCount': 1,
        'overallMessage': 'Eligible',
        'items': <Map<String, dynamic>>[],
        'policyChecks': <Map<String, dynamic>>[],
      });
      expect(cardWithoutMask.paymentDisplay, 'Visa');
      expect(cardWithoutMask.paymentDisplay.contains('••••'), isFalse);
    });
  });
}

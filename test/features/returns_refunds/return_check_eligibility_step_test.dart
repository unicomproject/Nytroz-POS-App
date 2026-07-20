import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nytroz_pos/features/returns_refunds/domain/entities/return_sale_eligibility.dart';
import 'package:nytroz_pos/features/returns_refunds/presentation/widgets/eligibility_check/eligibility_check_item.dart';
import 'package:nytroz_pos/features/returns_refunds/presentation/widgets/eligibility_check/eligibility_checklist_card.dart';
import 'package:nytroz_pos/features/returns_refunds/presentation/widgets/eligibility_check/eligibility_summary_card.dart';

ReturnSaleEligibility _result({
  required List<ReturnPolicyCheck> checks,
  bool canContinue = true,
  String overallStatus = 'ELIGIBLE',
  String? policyNote,
  bool requiresInspection = false,
  bool requiresManagerApproval = false,
}) {
  return ReturnSaleEligibility(
    saleId: 'sale-1',
    invoiceNo: 'RCP-100',
    customerName: 'Ada Lovelace',
    paymentMethod: 'Cash',
    maskedCard: '',
    currency: 'LKR',
    items: const [],
    policyChecks: checks,
    overallStatus: overallStatus,
    canContinue: canContinue,
    eligibleItemCount: canContinue ? 1 : 0,
    selectedItemCount: 1,
    overallMessage: 'Backend overall message',
    policyNote: policyNote,
    requiresInspection: requiresInspection,
    requiresManagerApproval: requiresManagerApproval,
  );
}

ReturnPolicyCheck _check({
  required String code,
  required String label,
  required String status,
  bool passed = true,
  bool requiresReview = false,
  String? reason,
}) {
  return ReturnPolicyCheck(
    label: label,
    value: label,
    passed: passed,
    code: code,
    description: '$label description',
    status: status,
    severity: status == 'FAILED' ? 'ERROR' : 'INFO',
    reason: reason,
    requiresReview: requiresReview,
  );
}

void main() {
  group('Step 4 eligibility checklist rendering', () {
    testWidgets('renders backend checklist statuses without fabricating rows',
        (tester) async {
      final result = _result(
        checks: [
          _check(code: 'RETURN_WINDOW', label: 'Return Window', status: 'PASSED'),
          _check(
            code: 'ORIGINAL_RECEIPT',
            label: 'Original Receipt',
            status: 'FAILED',
            passed: false,
            reason: 'Receipt required',
          ),
          _check(
            code: 'PAYMENT_VERIFICATION',
            label: 'Payment Verification',
            status: 'PASSED',
          ),
          _check(
            code: 'PRODUCT_RETURN_POLICY',
            label: 'Product Return Policy',
            status: 'PASSED',
          ),
          _check(
            code: 'INSPECTION_REQUIRED',
            label: 'Inspection Requirement',
            status: 'NOT_APPLICABLE',
          ),
          _check(
            code: 'MANAGER_APPROVAL_REQUIRED',
            label: 'Manager Approval Requirement',
            status: 'REQUIRES_REVIEW',
            passed: false,
            requiresReview: true,
          ),
        ],
        canContinue: false,
        overallStatus: 'NOT_ELIGIBLE',
        requiresManagerApproval: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EligibilityChecklistCard(checks: result.policyChecks),
          ),
        ),
      );

      expect(find.text('Original Receipt'), findsOneWidget);
      expect(find.text('Product Return Policy'), findsOneWidget);
      expect(find.text('Inspection Requirement'), findsOneWidget);
      expect(find.text('Manager Approval Requirement'), findsOneWidget);
      expect(find.text('Passed'), findsWidgets);
      expect(find.text('Failed'), findsOneWidget);
      expect(find.text('N/A'), findsOneWidget);
      expect(find.text('Requires Review'), findsOneWidget);
      expect(find.text('Product Category Rule'), findsNothing);
      expect(find.text('Item Condition Requirement'), findsNothing);
    });

    testWidgets('hides policy note when backend omits it', (tester) async {
      final result = _result(
        checks: [
          _check(code: 'RETURN_WINDOW', label: 'Return Window', status: 'PASSED'),
        ],
        policyNote: null,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EligibilitySummaryCard(result: result),
          ),
        ),
      );

      expect(find.textContaining('Policy'), findsNothing);
      expect(find.text('1 item'), findsOneWidget);
    });

    testWidgets('shows policy note only when supplied', (tester) async {
      final result = _result(
        checks: const [],
        policyNote: 'Return window: 30 days',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EligibilitySummaryCard(result: result),
          ),
        ),
      );

      expect(find.text('Return window: 30 days'), findsOneWidget);
      expect(find.textContaining('original packaging'), findsNothing);
    });

    test('displayStatus does not invent PASSED from passed bool', () {
      const check = ReturnPolicyCheck(
        label: 'X',
        value: 'Y',
        passed: true,
        status: '',
      );
      expect(check.displayStatus, 'UNKNOWN');
    });

    testWidgets('EligibilityCheckItem maps REQUIRES_REVIEW', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EligibilityCheckItem(
              check: _check(
                code: 'MANAGER_APPROVAL_REQUIRED',
                label: 'Manager Approval Requirement',
                status: 'REQUIRES_REVIEW',
                passed: false,
                requiresReview: true,
              ),
            ),
          ),
        ),
      );

      expect(find.text('Requires Review'), findsOneWidget);
    });

    test('fromJson parses inspection and approval flags', () {
      final result = ReturnSaleEligibility.fromJson({
        'saleId': 'e06a0d4b-8e7a-4f50-a026-da0e6fea6441',
        'invoiceNo': 'RCP-000036',
        'customerName': 'John Perera',
        'paymentMethod': 'Cash',
        'maskedCard': '',
        'currency': 'LKR',
        'overallStatus': 'ELIGIBLE_WITH_WARNINGS',
        'canContinue': true,
        'eligibleItemCount': 1,
        'selectedItemCount': 1,
        'overallMessage': 'Review later',
        'requiresInspection': false,
        'requiresManagerApproval': true,
        'items': <Map<String, dynamic>>[],
        'policyChecks': [
          {
            'label': 'Manager Approval Requirement',
            'value': 'Required',
            'passed': false,
            'code': 'MANAGER_APPROVAL_REQUIRED',
            'description': 'Preliminary',
            'status': 'REQUIRES_REVIEW',
            'severity': 'WARNING',
            'requiresReview': true,
          },
        ],
      });

      expect(result.requiresManagerApproval, isTrue);
      expect(result.requiresInspection, isFalse);
      expect(result.hasWarnings, isTrue);
      expect(result.policyChecks.single.displayStatus, 'REQUIRES_REVIEW');
    });
  });
}

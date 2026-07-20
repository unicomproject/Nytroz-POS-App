import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nytroz_pos/core/access/pos_access_codes.dart';
import 'package:nytroz_pos/core/access/pos_permission_access.dart';
import 'package:nytroz_pos/features/returns_refunds/domain/entities/refund_method_type.dart';
import 'package:nytroz_pos/features/returns_refunds/domain/entities/return_credit_preview.dart';
import 'package:nytroz_pos/features/returns_refunds/domain/entities/return_flow_steps.dart';
import 'package:nytroz_pos/features/returns_refunds/domain/entities/return_refund_method.dart';
import 'package:nytroz_pos/features/returns_refunds/domain/entities/return_resolution_type.dart';
import 'package:nytroz_pos/features/returns_refunds/presentation/providers/return_flow_provider.dart';
import 'package:nytroz_pos/features/returns_refunds/presentation/providers/return_refund_details_provider.dart';
import 'package:nytroz_pos/features/returns_refunds/presentation/widgets/refund_details/refund_method_section.dart';
import 'package:nytroz_pos/features/returns_refunds/presentation/widgets/refund_details/refund_summary_card.dart';
import 'package:nytroz_pos/features/returns_refunds/presentation/widgets/return_stepper.dart';

void main() {
  group('ReturnStepper dynamic Step 8', () {
    test('neutral branch label before selection', () {
      expect(
        ReturnStepper.branchStepLabel(null),
        'Refund / Exchange',
      );
    });

    test('refund branch label', () {
      expect(
        ReturnStepper.branchStepLabel(ReturnResolutionType.refund),
        'Refund',
      );
    });

    test('exchange branch label', () {
      expect(
        ReturnStepper.branchStepLabel(ReturnResolutionType.exchange),
        'Exchange',
      );
    });

    testWidgets('shows one Step 8 instead of 8A and 8B', (tester) async {
      await _pumpAtSize(
        tester,
        const ReturnStepper(
          currentStep: ReturnFlowSteps.branchAction,
          selectedBranch: ReturnResolutionType.refund,
        ),
        const Size(1280, 800),
      );

      expect(find.text('8A'), findsNothing);
      expect(find.text('8B'), findsNothing);
      expect(find.text('Refund'), findsOneWidget);
      expect(find.text('Review & Confirm'), findsOneWidget);
    });
  });

  group('ReturnFlowState refund branch', () {
    test('clear refund method when switching to exchange', () {
      final controller = ReturnFlowController();
      controller.setSelectedResolution(ReturnResolutionType.refund);
      controller.setSelectedRefundMethod(RefundMethodType.cash);
      controller.setRefundPreview(_preview());

      controller.setSelectedResolution(ReturnResolutionType.exchange);

      expect(controller.state.selectedRefundMethod, isNull);
      expect(controller.state.refundPreview, isNull);
      expect(controller.state.selectedResolution, ReturnResolutionType.exchange);
    });
  });

  group('Strict refund permission helper', () {
    test('canProcessRefund requires exact refunds.create', () {
      expect(
        PosPermissionAccess.canProcessRefund({
          PosPermissionCodes.viewReturns,
          PosPermissionCodes.createReturn,
          PosPermissionCodes.createRefund,
        }),
        isTrue,
      );
      expect(
        PosPermissionAccess.canProcessRefund({
          PosPermissionCodes.viewReturns,
          PosPermissionCodes.createReturn,
        }),
        isFalse,
      );
      expect(
        PosPermissionAccess.canProcessRefund({
          PosPermissionCodes.viewReturns,
          PosPermissionCodes.createReturn,
          PosPermissionCodes.viewRefunds,
        }),
        isFalse,
      );
    });
  });

  group('Refund details widgets', () {
    test('backend methods render masked original payment reference', () {
      const methods = [
        ReturnRefundMethodOption(
          code: 'ORIGINAL_PAYMENT',
          displayName: 'Original Payment Method',
          enabled: true,
          originalPaymentMethod: 'VISA',
          maskedReference: '•••• 4242',
          requiresProvider: true,
        ),
        ReturnRefundMethodOption(
          code: 'CASH',
          displayName: 'Cash',
          enabled: true,
          requiresOpenTill: true,
        ),
      ];

      expect(methods[0].description, 'VISA •••• 4242');
      expect(
        methods.any((method) => method.code == 'STORE_CREDIT' && method.enabled),
        isFalse,
      );
    });

    testWidgets('summary card renders dynamic preview values', (tester) async {
      await _pumpAtSize(
        tester,
        RefundSummaryCard(preview: _preview()),
        const Size(420, 500),
      );

      expect(find.text('Refund Summary'), findsOneWidget);
      expect(find.text('2 items'), findsOneWidget);
      expect(find.textContaining('CUR 250.00'), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('disabled backend methods cannot be selected', (tester) async {
      ReturnRefundMethodOption? selected;
      const methods = [
        ReturnRefundMethodOption(
          code: 'STORE_CREDIT',
          displayName: 'Store Credit',
          enabled: false,
          disabledReason: 'Store credit is not supported for this return.',
        ),
        ReturnRefundMethodOption(
          code: 'CASH',
          displayName: 'Cash',
          enabled: true,
        ),
      ];

      await _pumpAtSize(
        tester,
        RefundMethodSection(
          methods: methods,
          selectedMethodCode: null,
          onMethodSelected: (method) => selected = method,
        ),
        const Size(600, 500),
      );

      await tester.tap(find.text('Store Credit'));
      await tester.pump();
      expect(selected, isNull);

      await tester.tap(find.text('Cash'));
      await tester.pump();
      expect(selected?.code, 'CASH');
    });
  });

  group('ReturnRefundDetailsState confirm gating', () {
    test('confirm disabled without persisted enabled method', () {
      const state = ReturnRefundDetailsState(
        preview: null,
        methods: [
          ReturnRefundMethodOption(
            code: 'CASH',
            displayName: 'Cash',
            enabled: true,
          ),
        ],
        selectedMethodCode: 'CASH',
        methodPersisted: false,
      );

      expect(state.canConfirm, isFalse);
    });

    test('confirm enabled when preview can proceed and method persisted', () {
      final state = ReturnRefundDetailsState(
        preview: _preview(canProceed: true),
        methods: const [
          ReturnRefundMethodOption(
            code: 'CASH',
            displayName: 'Cash',
            enabled: true,
          ),
        ],
        selectedMethodCode: 'CASH',
        methodPersisted: true,
      );

      expect(state.canConfirm, isTrue);
    });
  });
}

ReturnCreditPreview _preview({bool canProceed = true}) {
  return ReturnCreditPreview(
    saleId: 'sale-1',
    invoiceNo: 'INV-100',
    customerName: 'Customer',
    customerDisplayId: 'C-1',
    paymentMethod: 'Card',
    maskedCard: '**** 1234',
    currency: 'CUR',
    saleTotal: 500,
    saleItemCount: 2,
    reasonCode: 'DAMAGED',
    reasonLabel: 'Damaged',
    items: const [],
    calculation: const ReturnCreditCalculation(
      itemValue: 200,
      discountLabel: '',
      discountAdjustment: 0,
      taxLabel: 'Tax Adjustment (18%)',
      taxAdjustment: 50,
      netCreditAmount: 250,
    ),
    creditReference: 'CR-1',
    validityDays: 30,
    selectedItemCount: 2,
    canProceed: canProceed,
  );
}

Future<void> _pumpAtSize(
  WidgetTester tester,
  Widget child,
  Size size,
) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: child,
        ),
      ),
    ),
  );
}

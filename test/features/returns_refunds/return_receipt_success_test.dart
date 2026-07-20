import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nytroz_pos/core/access/pos_access_codes.dart';
import 'package:nytroz_pos/core/access/pos_permission_access.dart';
import 'package:nytroz_pos/features/returns_refunds/domain/entities/return_flow_steps.dart';
import 'package:nytroz_pos/features/returns_refunds/domain/entities/return_receipt.dart';
import 'package:nytroz_pos/features/returns_refunds/domain/entities/return_resolution_type.dart';
import 'package:nytroz_pos/features/returns_refunds/presentation/navigation/returns_route_guard.dart';
import 'package:nytroz_pos/features/returns_refunds/presentation/providers/return_flow_provider.dart';
import 'package:nytroz_pos/features/returns_refunds/presentation/providers/return_success_display.dart';
import 'package:nytroz_pos/features/returns_refunds/presentation/widgets/receipt_success/invalid_completion_state.dart';
import 'package:nytroz_pos/features/returns_refunds/presentation/widgets/receipt_success/return_exchange_success_hero.dart';
import 'package:nytroz_pos/features/returns_refunds/presentation/widgets/receipt_success/success_page_actions.dart';
import 'package:nytroz_pos/features/returns_refunds/presentation/widgets/return_stepper.dart';
import 'package:nytroz_pos/features/auth/domain/entities/auth_session.dart';

ReturnReceipt _receipt({
  String receiptNumber = 'RCPT-1',
  String returnStatus = 'Completed',
  String resolution = 'REFUND',
  DateTime? completedAt,
  List<ReturnCompletionItem> returnedItems = const [
    ReturnCompletionItem(
      saleLineId: 'line-1',
      name: 'Item One',
      variantLabel: 'Default',
      quantity: 1,
      unitPrice: 100,
      lineAmount: 100,
    ),
  ],
  List<ReturnCompletionItem> replacementItems = const [],
  double? returnItemValue,
  double? replacementItemValue,
  double? differenceAmount,
  String? differenceDirection,
  String? exchangeNumber,
  String? returnNumber = 'RET-1',
  bool canPrint = true,
  String? receiptId = 'rcp-1',
  String? originalSaleId = 'sale-1',
}) {
  return ReturnReceipt(
    returnId: 'ret-1',
    receiptNumber: receiptNumber,
    originalInvoiceNo: 'INV-1',
    returnedItemCount: returnedItems.length,
    settlementMethodCode:
        resolution == 'EXCHANGE' ? 'CUSTOMER_PAYS' : 'CARD_REFUND',
    settlementMethodLabel:
        resolution == 'EXCHANGE' ? 'Customer Pays' : 'Card Refund',
    settlementDisplay:
        resolution == 'EXCHANGE' ? 'Customer Pays' : 'Card **** 1111',
    settlementResult: resolution == 'EXCHANGE'
        ? 'Exchange completed'
        : 'Refund settled to original payment method.',
    currency: 'CUR',
    refundAmount: 100,
    customerCreditAmount: 100,
    completedAt: completedAt ?? DateTime(2024, 5, 20, 9, 42),
    returnStatus: returnStatus,
    customerName: 'Customer',
    cashierName: 'Cashier',
    tillName: 'Till 01',
    approvalStatus: 'Approved',
    customerAcknowledgement: '',
    resolution: resolution,
    canPrint: canPrint,
    receiptId: receiptId,
    originalSaleId: originalSaleId,
    returnNumber: returnNumber,
    exchangeNumber: exchangeNumber,
    returnedItems: returnedItems,
    replacementItems: replacementItems,
    returnItemValue: returnItemValue,
    replacementItemValue: replacementItemValue,
    differenceAmount: differenceAmount,
    differenceDirection: differenceDirection,
  );
}

AuthSession _session(List<String> codes) {
  return AuthSession(
    accessToken: 'token',
    refreshToken: 'refresh',
    expiresAt: DateTime.now().add(const Duration(hours: 1)),
    userId: 'user',
    userDisplayName: 'Cashier',
    permissionCodes: codes,
  );
}

void main() {
  group('Step 10 stepper', () {
    testWidgets('shows steps 1-9 completed and step 10 active', (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(1280, 800);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 1280,
              height: 800,
              child: ReturnStepper(
                currentStep: ReturnFlowSteps.receipt,
                selectedBranch: ReturnResolutionType.refund,
              ),
            ),
          ),
        ),
      );

      expect(find.text('Receipt / Success'), findsOneWidget);
      expect(find.text('Review & Confirm'), findsOneWidget);
      expect(find.text('Refund'), findsOneWidget);
      expect(find.text('8A'), findsNothing);
      expect(find.text('8B'), findsNothing);
      expect(find.byIcon(Icons.check_rounded), findsWidgets);
    });
  });

  group('Success route permissions', () {
    test('blocked without returns.view', () {
      final session = _session([
        PosPermissionCodes.viewHome,
        PosPermissionCodes.createReturn,
        PosPermissionCodes.createRefund,
      ]);
      expect(
        ReturnsRouteGuard.canAccessPath(session, '/pos/returns-refunds/receipt'),
        isFalse,
      );
    });

    test('refund success requires exact refunds.create for process path', () {
      expect(
        PosPermissionAccess.canViewRefundSuccess({
          PosPermissionCodes.viewReturns,
          PosPermissionCodes.createReturn,
          PosPermissionCodes.createRefund,
        }),
        isTrue,
      );
      expect(
        PosPermissionAccess.canViewRefundSuccess({
          PosPermissionCodes.viewReturns,
          PosPermissionCodes.createReturn,
          PosPermissionCodes.createExchange,
        }),
        isFalse,
      );
    });

    test('exchange success requires exact exchanges.create', () {
      expect(
        PosPermissionAccess.canViewExchangeSuccess({
          PosPermissionCodes.viewReturns,
          PosPermissionCodes.createReturn,
          PosPermissionCodes.createExchange,
        }),
        isTrue,
      );
      expect(
        PosPermissionAccess.canViewExchangeSuccess({
          PosPermissionCodes.viewReturns,
          PosPermissionCodes.createReturn,
          PosPermissionCodes.createRefund,
        }),
        isFalse,
      );
    });

    test('local completion alone does not unlock route without permissions', () {
      final session = _session([PosPermissionCodes.viewHome]);
      expect(
        ReturnsRouteGuard.canAccessPath(session, '/pos/returns-refunds/receipt'),
        isFalse,
      );
    });

    test('print requires receipts.print', () {
      expect(
        PosPermissionAccess.canPrintReceipts({
          PosPermissionCodes.viewReturns,
          PosPermissionCodes.createRefund,
        }),
        isFalse,
      );
      expect(
        PosPermissionAccess.canPrintReceipts({
          PosPermissionCodes.printReceipts,
        }),
        isTrue,
      );
    });

    test('start new return requires returns.view and returns.create', () {
      expect(
        PosPermissionAccess.canStartNewReturn({
          PosPermissionCodes.viewReturns,
        }),
        isFalse,
      );
      expect(
        PosPermissionAccess.canStartNewReturn({
          PosPermissionCodes.viewReturns,
          PosPermissionCodes.createReturn,
        }),
        isTrue,
      );
    });
  });

  group('Completion display builder', () {
    test('invalid without completed receipt', () {
      const state = ReturnFlowState();
      expect(isValidReturnCompletion(state), isFalse);
      expect(buildReturnSuccessDisplay(state), isNull);
    });

    test('invalid when reference missing', () {
      final controller = ReturnFlowController();
      controller.setCompletedReceipt(
        const ReturnReceipt(
          returnId: '',
          receiptNumber: '',
          originalInvoiceNo: 'INV-1',
          returnedItemCount: 1,
          settlementMethodCode: 'CASH_REFUND',
          settlementMethodLabel: 'Cash',
          settlementDisplay: 'Cash',
          settlementResult: '',
          currency: 'CUR',
          refundAmount: 10,
          customerCreditAmount: 10,
          completedAt: null,
          returnStatus: 'Completed',
          customerName: 'Customer',
          cashierName: 'Cashier',
          tillName: 'Till',
          approvalStatus: 'Approved',
          customerAcknowledgement: '',
        ),
      );

      expect(isValidReturnCompletion(controller.state), isFalse);
    });

    test('refund success uses backend receipt fields only', () {
      final display = buildReturnSuccessDisplayFromReceipt(_receipt())!;

      expect(display.isExchange, isFalse);
      expect(display.heading, 'Return Completed Successfully');
      expect(display.reference, 'RET-1');
      expect(display.customerName, 'Customer');
      expect(display.processedBy, 'Cashier');
      expect(display.methodLabel, 'Card **** 1111');
      expect(display.totalAmount, 100);
      expect(display.items.length, 1);
      expect(display.items.first.name, 'Item One');
      expect(display.settlementMessage, isNotNull);
      expect(
        display.settlementMessage!.toLowerCase().contains('3-5 business days'),
        isFalse,
      );
    });

    test('exchange success uses resolution from receipt not local flags', () {
      final display = buildReturnSuccessDisplayFromReceipt(
        _receipt(
          resolution: 'EXCHANGE',
          exchangeNumber: 'EXC-9',
          returnItemValue: 100,
          replacementItemValue: 150,
          differenceAmount: 50,
          differenceDirection: 'CUSTOMER_PAYS',
          replacementItems: const [
            ReturnCompletionItem(
              saleLineId: 'rep-1',
              name: 'Replacement Product',
              variantLabel: 'Size M',
              quantity: 1,
              unitPrice: 150,
              lineAmount: 150,
              isReplacement: true,
            ),
          ],
        ),
      )!;

      expect(display.isExchange, isTrue);
      expect(display.heading, 'Exchange Completed Successfully');
      expect(display.reference, 'EXC-9');
      expect(display.replacementProductName, 'Replacement Product');
      expect(display.differenceAmount, 50);
      expect(display.items.any((item) => item.isReplacement), isTrue);
      expect(display.methodLabel, isNot(contains('Total Refund Amount')));
    });

    test('local resolution flag alone does not force exchange framing', () {
      final controller = ReturnFlowController();
      controller.setSelectedResolution(ReturnResolutionType.exchange);
      controller.setCompletedReceipt(_receipt(resolution: 'REFUND'));

      final display = buildReturnSuccessDisplay(controller.state)!;
      expect(display.isExchange, isFalse);
      expect(display.heading, 'Return Completed Successfully');
    });

    test('resetReturnExchangeDraft clears draft including completion', () {
      final controller = ReturnFlowController();
      controller.setSelectedResolution(ReturnResolutionType.refund);
      controller.setCompletedReceipt(_receipt());
      controller.resetReturnExchangeDraft();

      expect(controller.state.completedReceipt, isNull);
      expect(controller.state.selectedResolution, isNull);
    });
  });

  group('Success widgets', () {
    testWidgets('hero shows provided heading only', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ReturnExchangeSuccessHero(
              heading: 'Return Completed Successfully',
              supportingMessage: 'The return has been processed.',
            ),
          ),
        ),
      );

      expect(find.text('Return Completed Successfully'), findsOneWidget);
      expect(find.text('RET-0002456'), findsNothing);
      expect(find.text('John Perera'), findsNothing);
    });

    testWidgets('invalid completion never shows success heading',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: InvalidCompletionState(
              onBackToHome: () {},
            ),
          ),
        ),
      );

      expect(find.text('Return Completed Successfully'), findsNothing);
      expect(find.text('Completion details unavailable'), findsOneWidget);
      expect(find.text('Back to Review'), findsNothing);
    });

    testWidgets('actions hide print without printEnabled', (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(1280, 800);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SuccessPageActions(
              printEnabled: false,
              onPrintReceipt: () {},
              onStartNewReturn: () {},
              onBackToHome: () {},
            ),
          ),
        ),
      );

      expect(find.text('Print Receipt'), findsNothing);
      expect(find.text('Start New Return'), findsOneWidget);
      expect(find.text('Back to POS Home'), findsOneWidget);
    });

    testWidgets('actions render three labels at tablet width', (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(1280, 800);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SuccessPageActions(
              onPrintReceipt: () {},
              onStartNewReturn: () {},
              onBackToHome: () {},
            ),
          ),
        ),
      );

      expect(find.text('Print Receipt'), findsOneWidget);
      expect(find.text('Start New Return'), findsOneWidget);
      expect(find.text('Back to POS Home'), findsOneWidget);
    });
  });
}

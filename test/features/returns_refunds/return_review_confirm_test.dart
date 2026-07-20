import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nytroz_pos/features/returns_refunds/domain/entities/exchange_replacement_selection.dart';
import 'package:nytroz_pos/features/returns_refunds/domain/entities/refund_method_type.dart';
import 'package:nytroz_pos/features/returns_refunds/domain/entities/return_credit_preview.dart';
import 'package:nytroz_pos/features/returns_refunds/domain/entities/return_flow_steps.dart';
import 'package:nytroz_pos/features/returns_refunds/domain/entities/return_resolution_type.dart';
import 'package:nytroz_pos/features/returns_refunds/presentation/providers/return_flow_provider.dart';
import 'package:nytroz_pos/features/returns_refunds/presentation/providers/return_review_provider.dart';
import 'package:nytroz_pos/features/returns_refunds/presentation/widgets/return_stepper.dart';
import 'package:nytroz_pos/features/returns_refunds/presentation/widgets/review_confirm/return_exchange_review_action_footer.dart';
import 'package:nytroz_pos/features/returns_refunds/presentation/widgets/review_confirm/return_exchange_review_header.dart';
import 'package:nytroz_pos/features/returns_refunds/presentation/widgets/review_confirm/return_reference_details_card.dart';
import 'package:nytroz_pos/features/returns_refunds/presentation/widgets/review_confirm/settlement_information_banner.dart';

ReturnCreditPreview _preview({
  String paymentMethod = 'Card',
  String maskedCard = '**** 1111',
  String? customerId = 'cust-1',
  String creditReference = 'CR-100',
  int validityDays = 30,
}) {
  return ReturnCreditPreview(
    saleId: 'sale-1',
    invoiceNo: 'INV-1',
    customerId: customerId,
    customerName: 'Customer',
    customerDisplayId: 'C-1',
    paymentMethod: paymentMethod,
    maskedCard: maskedCard,
    currency: 'CUR',
    saleTotal: 100,
    saleItemCount: 1,
    reasonCode: 'R1',
    reasonLabel: 'Reason',
    items: const [
      ReturnCreditPreviewItem(
        saleLineId: 'line-1',
        name: 'Item',
        sku: 'SKU-1',
        variantLabel: 'Default',
        returnQty: 1,
        unitPrice: 100,
        lineAmount: 100,
      ),
    ],
    calculation: const ReturnCreditCalculation(
      itemValue: 100,
      discountLabel: 'Discount',
      discountAdjustment: 0,
      taxLabel: 'Tax',
      taxAdjustment: 0,
      netCreditAmount: 100,
    ),
    creditReference: creditReference,
    validityDays: validityDays,
    selectedItemCount: 1,
  );
}

void main() {
  group('Step 9 Review stepper', () {
    testWidgets('shows steps 1-8 completed, 9 active, 10 inactive',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 1280,
              height: 800,
              child: ReturnStepper(
                currentStep: ReturnFlowSteps.settlement,
                selectedBranch: ReturnResolutionType.refund,
              ),
            ),
          ),
        ),
      );

      expect(find.text('Review & Confirm'), findsOneWidget);
      expect(find.text('Receipt / Success'), findsOneWidget);
      expect(find.text('Refund'), findsOneWidget);
      expect(find.text('8A'), findsNothing);
      expect(find.text('8B'), findsNothing);
      expect(find.byIcon(Icons.check_rounded), findsWidgets);
    });

    test('dynamic step 8 remains Exchange on review', () {
      expect(
        ReturnStepper.branchStepLabel(ReturnResolutionType.exchange),
        'Exchange',
      );
    });
  });

  group('Settlement method mapping', () {
    test('maps cash refund method to CASH_REFUND', () {
      final code = mapRefundMethodToSettlementCode(
        refundMethod: RefundMethodType.cash,
        resolution: ReturnResolutionType.refund,
        preview: _preview(),
      );
      expect(code, 'CASH_REFUND');
    });

    test('maps original payment to CARD_REFUND when card available', () {
      final code = mapRefundMethodToSettlementCode(
        refundMethod: RefundMethodType.originalPaymentMethod,
        resolution: ReturnResolutionType.refund,
        preview: _preview(),
      );
      expect(code, 'CARD_REFUND');
    });

    test('maps store credit away from STORE_CREDIT completion code', () {
      final code = mapRefundMethodToSettlementCode(
        refundMethod: RefundMethodType.storeCredit,
        resolution: ReturnResolutionType.refund,
        preview: _preview(),
      );
      expect(code, isNot('STORE_CREDIT'));
      expect(code, 'CASH_REFUND');
    });

    test('exchange customer-pays maps to CASH_PAYMENT', () {
      final code = mapRefundMethodToSettlementCode(
        refundMethod: null,
        resolution: ReturnResolutionType.exchange,
        preview: _preview(),
        exchangeDifferenceDirection: 'CUSTOMER_PAYS',
      );
      expect(code, 'CASH_PAYMENT');
    });

    test('even exchange maps to NO_SETTLEMENT', () {
      final code = mapRefundMethodToSettlementCode(
        refundMethod: null,
        resolution: ReturnResolutionType.exchange,
        preview: _preview(),
        exchangeDifferenceDirection: 'EVEN_EXCHANGE',
      );
      expect(code, 'NO_SETTLEMENT');
    });

    test('exchange customer-refund maps to CASH_REFUND', () {
      final code = mapRefundMethodToSettlementCode(
        refundMethod: null,
        resolution: ReturnResolutionType.exchange,
        preview: _preview(),
        exchangeDifferenceDirection: 'CUSTOMER_RECEIVES',
      );
      expect(code, 'CASH_REFUND');
    });

    test('exchange ignores stale STORE_CREDIT existing code', () {
      final code = mapRefundMethodToSettlementCode(
        refundMethod: RefundMethodType.storeCredit,
        resolution: ReturnResolutionType.exchange,
        preview: _preview(),
        existingCode: 'STORE_CREDIT',
        exchangeDifferenceDirection: 'CUSTOMER_PAYS',
      );
      expect(code, 'CASH_PAYMENT');
    });

    test('exchange without backend direction does not invent settlement', () {
      final code = mapRefundMethodToSettlementCode(
        refundMethod: null,
        resolution: ReturnResolutionType.exchange,
        preview: _preview(),
        existingCode: 'CASH_PAYMENT',
      );
      expect(code, isNull);
    });
  });

  group('Settlement information banner', () {
    test('uses store credit validity from preview', () {
      final controller = ReturnFlowController();
      controller.setSelectedResolution(ReturnResolutionType.refund);
      controller.setSelectedRefundMethod(RefundMethodType.storeCredit);

      final message = settlementInformationMessage(
        flowState: controller.state,
        preview: _preview(validityDays: 14),
      );

      expect(message.contains('14'), isTrue);
      expect(message.toLowerCase().contains('3-5 business days'), isFalse);
    });

    test('exchange uses generic confirmation message', () {
      final controller = ReturnFlowController();
      controller.setSelectedResolution(ReturnResolutionType.exchange);

      final message = settlementInformationMessage(
        flowState: controller.state,
        preview: _preview(),
      );

      expect(message.toLowerCase().contains('exchange'), isTrue);
    });
  });

  group('Review readiness', () {
    test('refund method clearing preserves replacement clearing rules', () {
      final controller = ReturnFlowController();
      controller.setSelectedResolution(ReturnResolutionType.exchange);
      controller.setSelectedReplacement(
        const ExchangeReplacementSelection(
          productId: 'p1',
          productVariantId: 'v1',
          productName: 'Product',
          variantDisplayName: 'Size',
          quantity: 1,
          unitPrice: 50,
          currencyCode: 'CUR',
        ),
      );
      controller.setSelectedResolution(ReturnResolutionType.refund);

      expect(controller.state.selectedReplacement, isNull);
      expect(controller.state.selectedResolution, ReturnResolutionType.refund);
    });
  });

  group('Review widgets', () {
    testWidgets('header shows approved title and helper text', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: ReturnExchangeReviewHeader()),
        ),
      );

      expect(find.text('Return / Exchange Receipt Preview'), findsOneWidget);
      expect(
        find.text('Review the return details and complete the process.'),
        findsOneWidget,
      );
    });

    testWidgets('reference card renders provided metadata only', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ReturnReferenceDetailsCard(
              returnReference: 'Generated after completion',
              customerName: 'Customer Name',
              processedBy: 'Cashier Name',
            ),
          ),
        ),
      );

      expect(find.text('Generated after completion'), findsOneWidget);
      expect(find.text('Customer Name'), findsOneWidget);
      expect(find.text('Cashier Name'), findsOneWidget);
      expect(find.text('RET-0002456'), findsNothing);
      expect(find.text('Pending'), findsNothing);
      expect(find.text('John Perera'), findsNothing);
    });

    testWidgets('Step 9 footer has no Print button', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ReturnExchangeReviewActionFooter(
              canComplete: false,
              isSubmitting: false,
              completeLabel: 'Complete Return',
              onBack: () {},
              onComplete: () {},
            ),
          ),
        ),
      );

      expect(find.text('Print'), findsNothing);
      expect(find.text('Back'), findsOneWidget);
      expect(find.text('Complete Return'), findsOneWidget);
      expect(find.textContaining('not available yet'), findsNothing);
    });

    testWidgets('information banner uses supplied message', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SettlementInformationBanner(
              message: 'Review all return details carefully before completing.',
            ),
          ),
        ),
      );

      expect(
        find.text('Review all return details carefully before completing.'),
        findsOneWidget,
      );
      expect(find.textContaining('3-5 business days'), findsNothing);
    });

    testWidgets('tablet two-column width keeps review header readable',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(size: Size(1280, 800)),
            child: Scaffold(
              body: SizedBox(
                width: 1280,
                height: 800,
                child: ReturnExchangeReviewHeader(),
              ),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('Return / Exchange Receipt Preview'), findsOneWidget);
    });
  });
}

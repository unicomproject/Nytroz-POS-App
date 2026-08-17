import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:nytroz_pos/features/hardware/receipt_printer/esc_pos/esc_pos_receipt_generator.dart';
import 'package:nytroz_pos/features/hardware/receipt_printer/mappers/canonical_receipt_presentation_mapper.dart';
import 'package:nytroz_pos/features/hardware/receipt_printer/models/canonical_receipt_presentation.dart';
import 'package:nytroz_pos/features/hardware/receipt_printer/models/local_print_agent_models.dart';
import 'package:nytroz_pos/features/hardware/receipt_printer/models/pos_device_printer_config.dart';
import 'package:nytroz_pos/features/sale/domain/entities/pos_checkout_summary.dart';
import 'package:nytroz_pos/features/sale/presentation/providers/pos_cash_payment_success_provider.dart';
import 'package:nytroz_pos/shared/pos_session/pos_session_context.dart';

void main() {
  group('receipt customer mapping', () {
    test(
        'Payment Success keeps Sam when backend payload omits customerName',
        () {
      final notifier = PosCashPaymentSuccessNotifier();
      final payload = _completedPayload(customerName: null);

      notifier.recordCheckoutPayment(
        payload,
        customerName: 'Sam',
        customerPhone: '+94770000000',
        customerId: 'cust-sam',
      );

      final success = notifier.state!;
      expect(success.customerName, 'Sam');
      expect(success.authoritativePayment!.customerName, 'Sam');
      expect(success.authoritativePayment!.customerId, 'cust-sam');

      final presentation =
          const CanonicalReceiptPresentationMapper().fromPaymentSuccess(
        success: success,
        session: _session(),
        cashierFallback: 'Cashier',
      );
      expect(presentation.customerDisplayName, 'Sam');

      // Cart/provider clear simulation: only success snapshot remains.
      final afterClear = PosCashPaymentSuccessData(
        receiptNumber: success.receiptNumber,
        barcodeValue: success.barcodeValue,
        saleId: success.saleId,
        completedAt: success.completedAt,
        itemCount: success.itemCount,
        subtotal: success.subtotal,
        discount: success.discount,
        tax: success.tax,
        total: success.total,
        cashReceived: success.cashReceived,
        changeDue: success.changeDue,
        items: success.items,
        customerName: success.customerName,
        customerPhone: success.customerPhone,
        cashierName: success.cashierName,
        receiptDataJson: success.receiptDataJson,
        authoritativePayment: success.authoritativePayment,
      );
      final afterClearPresentation =
          const CanonicalReceiptPresentationMapper().fromPaymentSuccess(
        success: afterClear,
        session: _session(),
        cashierFallback: 'Cashier',
      );
      expect(afterClearPresentation.customerDisplayName, 'Sam');
    });

    test('anonymous sale maps Walk-in Customer across renderers', () {
      final notifier = PosCashPaymentSuccessNotifier();
      notifier.recordCheckoutPayment(_completedPayload(customerName: null));
      final success = notifier.state!;
      expect(success.customerName, isNull);

      final presentation =
          const CanonicalReceiptPresentationMapper().fromPaymentSuccess(
        success: success,
        session: _session(),
        cashierFallback: 'Cashier',
      );
      expect(
        presentation.customerDisplayName,
        CanonicalReceiptPresentation.walkInCustomerLabel,
      );

      final text = _escPosText(presentation);
      expect(text, contains(CanonicalReceiptPresentation.walkInCustomerLabel));

      final agentRequest = _agentRequest(presentation);
      expect(
        agentRequest.customerName,
        CanonicalReceiptPresentation.walkInCustomerLabel,
      );
    });

    test('named customer reaches Dart ESC/POS and LocalPrintAgent request', () {
      final notifier = PosCashPaymentSuccessNotifier();
      notifier.recordCheckoutPayment(
        _completedPayload(customerName: null),
        customerName: 'Sam',
      );
      final presentation =
          const CanonicalReceiptPresentationMapper().fromPaymentSuccess(
        success: notifier.state!,
        session: _session(),
        cashierFallback: 'Cashier',
      );

      final text = _escPosText(presentation);
      expect(text, contains('Customer'));
      expect(text, contains('Sam'));
      expect(
        text,
        isNot(contains(CanonicalReceiptPresentation.walkInCustomerLabel)),
      );

      final agentRequest = _agentRequest(presentation);
      expect(agentRequest.customerName, 'Sam');
    });

    test(
        'success.customerName override wins when authoritativePayment lacks name',
        () {
      final payment = _completedPayload(customerName: null);
      final success = PosCashPaymentSuccessData(
        receiptNumber: payment.receiptNumber,
        barcodeValue: payment.barcodeValue,
        saleId: payment.saleId,
        completedAt: payment.completedAt!,
        itemCount: 1,
        subtotal: payment.subtotal,
        discount: payment.discount,
        tax: payment.tax,
        total: payment.grandTotal,
        cashReceived: payment.cashReceived,
        changeDue: payment.changeDue,
        items: const [],
        customerName: 'Sam',
        authoritativePayment: payment,
      );

      final presentation =
          const CanonicalReceiptPresentationMapper().fromPaymentSuccess(
        success: success,
        session: _session(),
        cashierFallback: 'Cashier',
      );
      expect(presentation.customerDisplayName, 'Sam');
    });
  });
}

String _escPosText(CanonicalReceiptPresentation presentation) {
  final bytes = const EscPosReceiptGenerator().generateCanonical(
    presentation: presentation,
    config: const PosDevicePrinterConfig(
      deviceId: 'device-1',
      enabled: true,
      connectionType: PrinterConnectionType.usb,
      displayName: 'USB',
      paperWidth: PrinterPaperWidth.mm80,
    ),
  );
  return latin1.decode(bytes, allowInvalid: true);
}

LocalPrintAgentReceiptRequest _agentRequest(
  CanonicalReceiptPresentation presentation,
) {
  // Build via service private path is not exposed; mirror production mapping.
  return LocalPrintAgentReceiptRequest(
    requestId: '11111111-1111-4111-8111-111111111111',
    receiptNumber: presentation.receiptNumber,
    printedAt: presentation.issuedAtUtc,
    merchantName: presentation.merchantName,
    currency: presentation.currency,
    items: presentation.items
        .map(
          (item) => LocalPrintAgentReceiptLine(
            name: item.name,
            quantity: item.quantity,
            unitPrice: item.valueUnitPrice,
            lineTotal: item.lineTotal,
            sku: item.sku,
            valueUnitPrice: item.valueUnitPrice,
            rateUnitPrice: item.rateUnitPrice,
          ),
        )
        .toList(growable: false),
    subtotal: presentation.subtotal,
    discountTotal: presentation.discountTotal,
    taxTotal: presentation.taxTotal,
    total: presentation.total,
    paymentMethod: presentation.paymentMethodDisplay,
    customerName: presentation.customerDisplayName,
    amountTendered: presentation.amountTendered,
    change: presentation.changeDue,
    barcodeValue: presentation.barcodeValue,
    footerLines: presentation.footerLines,
  );
}

PosCheckoutStartPaymentPayload _completedPayload({String? customerName}) {
  final completedAt = DateTime.utc(2026, 8, 16, 12);
  return PosCheckoutStartPaymentPayload(
    checkoutSessionId: 'checkout',
    saleId: 'aaaaaaaa-aaaa-4aaa-aaaa-aaaaaaaaaaaa',
    saleNumber: 'SALE-1',
    paymentMethod: 'cash',
    grandTotal: 1000,
    currency: 'LKR',
    saleStatus: 'completed',
    nextAction: 'completed',
    receiptNumber: 'RCP-SAM',
    barcodeValue: 'RCP-SAM',
    completedAt: completedAt,
    subtotal: 1000,
    discount: 0,
    tax: 0,
    cashReceived: 1000,
    changeDue: 0,
    receiptId: 'bbbbbbbb-bbbb-4bbb-abbb-bbbbbbbbbbbb',
    merchantName: 'OneVerz',
    outletName: 'Main Outlet',
    tillId: 'till-1',
    tillName: 'Front Till 01',
    cashierId: 'cashier-1',
    cashierName: 'Kavin',
    customerName: customerName,
    items: const [
      PosCheckoutCompletedLinePayload(
        name: 'Item',
        quantity: 1,
        unitPrice: 1000,
        lineTotal: 1000,
      ),
    ],
    tenders: const [
      PosReceiptTenderPayload(
        paymentId: 'pay-1',
        methodCode: 'CASH',
        methodName: 'Cash',
        methodType: 'CASH',
        amount: 1000,
        currency: 'LKR',
        status: 'CAPTURED',
      ),
    ],
  );
}

PosSessionContext _session() => const PosSessionContext(
      brandName: 'OneVerz',
      brandSubtitle: 'POS',
      outletName: 'Main Outlet',
      outletLocation: 'Colombo',
      tillName: 'Front Till 01',
      tillStatus: 'Open',
      userName: 'Cashier',
      userRole: 'Cashier',
      deviceName: 'POS 01',
      deviceCode: 'POS-01',
      systemStatus: 'Online',
      lastSyncLabel: 'Now',
    );

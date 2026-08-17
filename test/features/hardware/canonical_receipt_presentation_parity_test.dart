import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:nytroz_pos/features/hardware/receipt_printer/esc_pos/esc_pos_receipt_generator.dart';
import 'package:nytroz_pos/features/hardware/receipt_printer/mappers/canonical_receipt_presentation_mapper.dart';
import 'package:nytroz_pos/features/hardware/receipt_printer/models/canonical_receipt_presentation.dart';
import 'package:nytroz_pos/features/hardware/receipt_printer/models/completed_sale_receipt.dart';
import 'package:nytroz_pos/features/hardware/receipt_printer/models/pos_device_printer_config.dart';
import 'package:nytroz_pos/features/sale/domain/entities/pos_checkout_summary.dart';
import 'package:nytroz_pos/shared/pos_session/pos_session_context.dart';
import 'package:nytroz_pos/features/sale/presentation/providers/pos_cash_payment_success_provider.dart';

void main() {
  group('canonical receipt presentation parity', () {
    test('maps VALUE/RATE and shared fields for discounted sale', () {
      final presentation = const CanonicalReceiptPresentationMapper()
          .fromCompletedSale(_discountedReceipt());

      expect(presentation.receiptNumber, 'RCP-000200');
      expect(presentation.customerDisplayName, 'Sundhar');
      expect(presentation.terminalName, 'Front Till 01');
      expect(presentation.paymentMethodDisplay, 'Cash');
      expect(presentation.itemCount, 2);
      expect(presentation.items, hasLength(2));
      expect(presentation.items[0].valueUnitPrice, 4500);
      expect(presentation.items[0].rateUnitPrice, 3375);
      expect(presentation.items[0].sku, 'MER-001-SKU');
      expect(presentation.items[1].valueUnitPrice, 2800);
      expect(presentation.items[1].rateUnitPrice, 2100);
      expect(presentation.thankYouText,
          CanonicalReceiptPresentation.defaultThankYouText);
      expect(presentation.policyText,
          CanonicalReceiptPresentation.defaultPolicyText);
      expect(presentation.barcodeValue, 'RCP-000200');
      expect(presentation.issuedAtDisplay, contains('2026'));
    });

    test('preview mapper uses authoritative payment method not hardcoded Cash',
        () {
      final payment = _cardPayment();
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
        cashReceived: 0,
        changeDue: 0,
        items: const [],
        authoritativePayment: payment,
      );
      final presentation =
          const CanonicalReceiptPresentationMapper().fromPaymentSuccess(
        success: success,
        session: _session(),
        cashierFallback: 'Cashier',
      );
      expect(presentation.paymentMethodDisplay, 'Card');
      expect(presentation.customerDisplayName, 'Sundhar');
    });

    test('Dart ESC/POS encodes canonical semantics for 80mm', () {
      final presentation = const CanonicalReceiptPresentationMapper()
          .fromCompletedSale(_discountedReceipt());
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
      final text = latin1.decode(bytes, allowInvalid: true);
      expect(text, contains('Receipt No'));
      expect(text, contains('Date & Time'));
      expect(text, contains('Sundhar'));
      expect(text, contains('Terminal'));
      expect(text, contains('Front Till 01'));
      expect(text, contains('Payment'));
      expect(text, contains('Cash'));
      expect(text, contains('ITEM'));
      expect(text, contains('VALUE'));
      expect(text, contains('RATE'));
      expect(text, contains('MER-001-SKU'));
      expect(text, contains('3,375.00'));
      expect(text, contains('No. of Items'));
      expect(text, contains('Paid by Cash'));
      expect(text, contains('Change Due'));
      expect(text, contains('Thank you for your purchase'));
      expect(text, contains('Goods once sold can be exchanged'));
      expect(text, contains('RCP-000200'));
      expect(text, isNot(contains('SALE RECEIPT - CUSTOMER COPY')));
      expect(text, isNot(contains('Dev Promo')));
    });
  });
}

CompletedSaleReceipt _discountedReceipt() => CompletedSaleReceipt(
      receiptId: 'bbbbbbbb-bbbb-4bbb-abbb-bbbbbbbbbbbb',
      saleId: 'aaaaaaaa-aaaa-4aaa-aaaa-aaaaaaaaaaaa',
      receiptNumber: 'RCP-000200',
      completedAt: DateTime.utc(2026, 8, 16, 10, 57, 12),
      merchantName: 'OneVerz',
      outletName: 'Development Main Store',
      tillId: 'till-1',
      tillName: 'Front Till 01',
      cashierId: 'cashier-1',
      cashierName: 'Kavin',
      customerName: 'Sundhar',
      deviceId: 'device-1',
      currency: 'LKR',
      items: const [
        CompletedSaleReceiptLine(
          name: 'Team Jersey',
          quantity: 1,
          unitPrice: 4500,
          lineTotal: 3375,
          variantOrSku: 'MER-001-SKU',
        ),
        CompletedSaleReceiptLine(
          name: 'Match Shorts',
          quantity: 1,
          unitPrice: 2800,
          lineTotal: 2100,
          variantOrSku: 'SHO-002',
        ),
      ],
      subtotal: 7300,
      discountTotal: 1825,
      taxTotal: 0,
      total: 5475,
      paymentMethods: const ['cash'],
      amountTendered: 5500,
      change: 25,
      barcodeValue: 'RCP-000200',
      footerLines: const [
        CanonicalReceiptPresentation.defaultThankYouText,
        CanonicalReceiptPresentation.defaultPolicyText,
      ],
      tenders: const [
        CompletedSaleTender(
          methodCode: 'CASH',
          methodName: 'Cash',
          methodType: 'CASH',
          amount: 5475,
          amountTendered: 5500,
          changeAmount: 25,
          currency: 'LKR',
          status: 'CAPTURED',
        ),
      ],
    );

PosCheckoutStartPaymentPayload _cardPayment() {
  final completedAt = DateTime.utc(2026, 8, 16, 10);
  return PosCheckoutStartPaymentPayload(
    checkoutSessionId: 'checkout',
    saleId: 'aaaaaaaa-aaaa-4aaa-aaaa-aaaaaaaaaaaa',
    saleNumber: 'SALE-1',
    paymentMethod: 'card',
    grandTotal: 1000,
    currency: 'LKR',
    saleStatus: 'completed',
    nextAction: 'completed',
    receiptNumber: 'RCP-CARD',
    barcodeValue: 'RCP-CARD',
    completedAt: completedAt,
    subtotal: 1000,
    discount: 0,
    tax: 0,
    cashReceived: 0,
    changeDue: 0,
    receiptId: 'bbbbbbbb-bbbb-4bbb-abbb-bbbbbbbbbbbb',
    merchantName: 'OneVerz',
    outletName: 'Main Outlet',
    tillId: 'till-1',
    tillName: 'Till 01',
    cashierId: 'cashier-1',
    cashierName: 'Kavin',
    customerName: 'Sundhar',
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
        paymentId: 'p1',
        methodCode: 'CARD',
        methodName: 'Card',
        methodType: 'CARD',
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
      tillName: 'Till 01',
      tillStatus: 'Open',
      userName: 'Cashier',
      userRole: 'Cashier',
      deviceName: 'POS 01',
      deviceCode: 'POS-01',
      systemStatus: 'Online',
      lastSyncLabel: 'Now',
    );

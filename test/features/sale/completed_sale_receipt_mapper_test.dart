import 'package:flutter_test/flutter_test.dart';
import 'package:nytroz_pos/features/auth/domain/entities/auth_session.dart';
import 'package:nytroz_pos/features/device_activation/domain/entities/pos_device_context.dart';
import 'package:nytroz_pos/features/sale/data/mappers/completed_sale_receipt_mapper.dart';
import 'package:nytroz_pos/features/sale/domain/entities/pos_checkout_summary.dart';

void main() {
  test('maps backend completed values without recalculating money', () {
    final completedAt = DateTime.utc(2026, 7, 28, 10, 30);
    final receipt = const CompletedSaleReceiptMapper().fromCompletedPayment(
      payment: PosCheckoutStartPaymentPayload(
        checkoutSessionId: 'checkout',
        saleId: 'aaaaaaaa-aaaa-4aaa-aaaa-aaaaaaaaaaaa',
        saleNumber: 'SALE-1',
        paymentMethod: 'cash',
        grandTotal: 1681,
        currency: 'lkr',
        saleStatus: 'completed',
        nextAction: 'completed',
        receiptNumber: 'REC-1',
        barcodeValue: 'REC-1',
        completedAt: completedAt,
        subtotal: 1480,
        discount: 99,
        tax: 300,
        cashReceived: 2000,
        changeDue: 319,
        receiptId: 'bbbbbbbb-bbbb-4bbb-abbb-bbbbbbbbbbbb',
        merchantName: 'OneVerz',
        outletName: 'Main Outlet',
        tillId: 'till-id',
        tillName: 'Till 01',
        cashierId: 'cashier-id',
        cashierName: 'Kavin',
        items: const [
          PosCheckoutCompletedLinePayload(
            name: 'A very long authoritative product name',
            quantity: 2,
            unitPrice: 740,
            lineTotal: 1480,
            variantSummary: 'SKU-1',
          ),
        ],
        tenders: const [
          PosReceiptTenderPayload(
            paymentId: 'payment-id',
            methodCode: 'CASH',
            methodName: 'Cash',
            methodType: 'CASH',
            amount: 1681,
            amountTendered: 2000,
            changeAmount: 319,
            currency: 'LKR',
            status: 'PAID',
          ),
        ],
      ),
      device: _device(),
      session: _session(),
    );

    expect(receipt.receiptId, 'bbbbbbbb-bbbb-4bbb-abbb-bbbbbbbbbbbb');
    expect(receipt.total, 1681);
    expect(receipt.subtotal, 1480);
    expect(receipt.discountTotal, 99);
    expect(receipt.taxTotal, 300);
    expect(receipt.items.single.lineTotal, 1480);
    expect(receipt.paymentMethods, ['cash']);
    expect(receipt.merchantName, 'OneVerz');
    expect(receipt.barcodeValue, 'REC-1');
  });

  test('rejects a payment that backend has not completed', () {
    expect(
      () => const CompletedSaleReceiptMapper().fromCompletedPayment(
        payment: _payment(status: 'pending'),
        device: _device(),
        session: _session(),
      ),
      throwsFormatException,
    );
  });

  test('blocks printing when authoritative tender allocation is unavailable',
      () {
    expect(
      () => const CompletedSaleReceiptMapper().fromCompletedPayment(
        payment: _payment(status: 'completed'),
        device: _device(),
        session: _session(),
      ),
      throwsFormatException,
    );
  });

  test(
      'maps authoritative tender discount tax and copy policy without recalculation',
      () {
    final payload = PosCheckoutStartPaymentPayload.fromJson({
      'checkoutSessionId': 'checkout',
      'saleId': 'aaaaaaaa-aaaa-4aaa-aaaa-aaaaaaaaaaaa',
      'saleNumber': 'SALE-2',
      'paymentMethod': 'split',
      'grandTotal': 1500,
      'currency': 'LKR',
      'saleStatus': 'completed',
      'nextAction': 'completed',
      'receiptNumber': 'REC-2',
      'completedAt': '2026-07-28T10:30:00Z',
      'subtotal': 1500,
      'discountTotal': 100,
      'taxTotal': 100,
      'cashReceived': 0,
      'changeDue': 0,
      'items': [],
      'tenders': [
        {
          'paymentId': 'p1',
          'methodCode': 'CASH',
          'methodName': 'Cash',
          'methodType': 'CASH',
          'amount': 500,
          'currency': 'LKR',
          'status': 'PAID',
        },
        {
          'paymentId': 'p2',
          'methodCode': 'CARD',
          'methodName': 'Card',
          'methodType': 'CARD',
          'amount': 1000,
          'currency': 'LKR',
          'status': 'PAID',
          'cardBrand': 'VISA',
          'maskedCardLast4': '4242',
        }
      ],
      'discountLines': [
        {
          'scope': 'TRANSACTION',
          'name': 'Offer',
          'amount': 100,
        }
      ],
      'taxLines': [
        {
          'taxCode': 'VAT',
          'taxName': 'VAT',
          'rate': 8,
          'taxableAmount': 1250,
          'taxAmount': 100,
        }
      ],
      'copyPolicy': {
        'customerCopyCount': 1,
        'merchantCopyCount': 1,
        'printCustomerCopy': true,
        'printMerchantCopy': true,
      },
    });

    final receipt = const CompletedSaleReceiptMapper().fromCompletedPayment(
      payment: payload,
      device: _device(),
      session: _session(),
    );

    expect(receipt.tenders.map((x) => x.amount), [500, 1000]);
    expect(receipt.tenders.last.maskedCardLast4, '4242');
    expect(receipt.discountLines.single.amount, 100);
    expect(receipt.taxLines.single.taxAmount, 100);
    expect(receipt.copyPolicy.printMerchantCopy, isTrue);
    expect(receipt.total, 1500);
  });
}

PosCheckoutStartPaymentPayload _payment({required String status}) {
  return PosCheckoutStartPaymentPayload(
    checkoutSessionId: 'checkout',
    saleId: 'aaaaaaaa-aaaa-4aaa-aaaa-aaaaaaaaaaaa',
    saleNumber: 'SALE-1',
    paymentMethod: 'cash',
    grandTotal: 100,
    currency: 'LKR',
    saleStatus: status,
    nextAction: status,
    receiptNumber: 'REC-1',
    barcodeValue: 'REC-1',
    completedAt: DateTime.utc(2026),
    subtotal: 100,
    discount: 0,
    tax: 0,
    cashReceived: 100,
    changeDue: 0,
    items: const [],
  );
}

PosDeviceContext _device() => PosDeviceContext(
      deviceId: 'device-id',
      deviceCode: 'POS-1',
      deviceName: 'Tablet',
      deviceType: 'fixed',
      platform: 'android',
      deviceFingerprint: 'fingerprint',
      isTrusted: true,
      tenantId: 'tenant-id',
      outletId: 'outlet-id',
      outletName: 'Fallback Outlet',
      tillId: 'fallback-till',
      tillCode: 'T01',
      tillName: 'Fallback Till',
      pairedAt: DateTime.utc(2026),
    );

AuthSession _session() => const AuthSession(
      accessToken: 'token',
      userId: 'fallback-user',
      userDisplayName: 'Fallback Cashier',
    );

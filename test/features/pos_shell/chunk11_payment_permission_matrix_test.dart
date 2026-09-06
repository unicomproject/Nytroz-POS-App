import 'package:flutter_test/flutter_test.dart';
import 'package:nytroz_pos/core/access/effective_permission_set.dart';
import 'package:nytroz_pos/core/access/pos_access_codes.dart';
import 'package:nytroz_pos/core/access/pos_payment_permission_visibility.dart';
import 'package:nytroz_pos/features/sale/domain/entities/pos_payment_method_type.dart';

void main() {
  group('Chunk 11 — Payment method independence', () {
    test('Cash only', () {
      final p = EffectivePermissionSet.fromIterable([
        PosPermissionCodes.acceptCashPayment,
      ]);
      expect(PosPaymentPermissionVisibility.canAcceptCash(p), isTrue);
      expect(PosPaymentPermissionVisibility.canAcceptCard(p), isFalse);
      expect(PosPaymentPermissionVisibility.canAcceptQr(p), isFalse);
      expect(PosPaymentPermissionVisibility.canAcceptSplit(p), isFalse);
      expect(
        PosPaymentPermissionVisibility.visiblePaymentMethods(p),
        [PosPaymentMethodType.cash],
      );
    });

    test('Card only does not authorize Cash', () {
      final p = EffectivePermissionSet.fromIterable([
        PosPermissionCodes.acceptCardPayment,
      ]);
      expect(PosPaymentPermissionVisibility.canAcceptCard(p), isTrue);
      expect(PosPaymentPermissionVisibility.canAcceptCash(p), isFalse);
      expect(
        PosPaymentPermissionVisibility.visiblePaymentMethods(p),
        [PosPaymentMethodType.card],
      );
    });

    test('QR does not authorize Split', () {
      final p = EffectivePermissionSet.fromIterable([
        PosPermissionCodes.acceptQrPayment,
      ]);
      expect(PosPaymentPermissionVisibility.canAcceptQr(p), isTrue);
      expect(PosPaymentPermissionVisibility.canAcceptSplit(p), isFalse);
    });

    test('Split does not authorize QR', () {
      final p = EffectivePermissionSet.fromIterable([
        PosPermissionCodes.acceptSplitPayment,
      ]);
      expect(PosPaymentPermissionVisibility.canAcceptSplit(p), isTrue);
      expect(PosPaymentPermissionVisibility.canAcceptQr(p), isFalse);
    });

    test('Card + QR', () {
      final p = EffectivePermissionSet.fromIterable([
        PosPermissionCodes.acceptCardPayment,
        PosPermissionCodes.acceptQrPayment,
      ]);
      expect(
        PosPaymentPermissionVisibility.visiblePaymentMethods(p),
        [PosPaymentMethodType.card, PosPaymentMethodType.qrMobile],
      );
    });

    test('all four methods', () {
      final p = EffectivePermissionSet.fromIterable([
        PosPermissionCodes.acceptCashPayment,
        PosPermissionCodes.acceptCardPayment,
        PosPermissionCodes.acceptQrPayment,
        PosPermissionCodes.acceptSplitPayment,
      ]);
      expect(
        PosPaymentPermissionVisibility.visiblePaymentMethods(p).length,
        4,
      );
    });

    test('none collapses', () {
      final p = EffectivePermissionSet.fromIterable(const []);
      expect(PosPaymentPermissionVisibility.visiblePaymentMethods(p), isEmpty);
    });
  });

  group('Chunk 11 — Exact Cash independence', () {
    test('Cash accept alone does not show Exact Cash', () {
      final p = EffectivePermissionSet.fromIterable([
        PosPermissionCodes.acceptCashPayment,
      ]);
      expect(PosPaymentPermissionVisibility.canAcceptCash(p), isTrue);
      expect(PosPaymentPermissionVisibility.canShowExactCash(p), isFalse);
    });

    test('Exact Cash granted', () {
      final p = EffectivePermissionSet.fromIterable([
        PosPermissionCodes.cashPaymentTenderExact,
      ]);
      expect(PosPaymentPermissionVisibility.canShowExactCash(p), isTrue);
    });
  });

  group('Chunk 11 — Quick amounts', () {
    test('container denied hides all', () {
      final p = EffectivePermissionSet.fromIterable([
        PosPermissionCodes.cashPaymentTenderExact,
        PosPermissionCodes.cashPaymentQuickAmountsSlot1,
      ]);
      expect(
        PosPaymentPermissionVisibility.filterQuickAmounts(
          p,
          amounts: [1000, 2000, 3000],
          exactAmount: 1000,
        ),
        isEmpty,
      );
    });

    test('exact + slot_1 only', () {
      final p = EffectivePermissionSet.fromIterable([
        PosPermissionCodes.cashPaymentQuickAmountsContainer,
        PosPermissionCodes.cashPaymentTenderExact,
        PosPermissionCodes.cashPaymentQuickAmountsSlot1,
      ]);
      expect(
        PosPaymentPermissionVisibility.filterQuickAmounts(
          p,
          amounts: [1000, 2000, 3000],
          exactAmount: 1000,
        ),
        [1000, 2000],
      );
    });

    test('exact denied keeps slots', () {
      final p = EffectivePermissionSet.fromIterable([
        PosPermissionCodes.cashPaymentQuickAmountsContainer,
        PosPermissionCodes.cashPaymentQuickAmountsSlot1,
        PosPermissionCodes.cashPaymentQuickAmountsSlot2,
      ]);
      expect(
        PosPaymentPermissionVisibility.filterQuickAmounts(
          p,
          amounts: [1000, 2000, 3000],
          exactAmount: 1000,
        ),
        [2000, 3000],
      );
    });
  });

  group('Chunk 11 — Numpad keys', () {
    test('Cash accept alone does not grant numpad children', () {
      final p = EffectivePermissionSet.fromIterable([
        PosPermissionCodes.acceptCashPayment,
      ]);
      expect(PosPaymentPermissionVisibility.canShowNumpadContainer(p), isFalse);
      for (final d in ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9', '00', '.']) {
        expect(
          PosPaymentPermissionVisibility.canShowNumpadDigit(p, d),
          isFalse,
          reason: 'digit $d',
        );
      }
      expect(PosPaymentPermissionVisibility.canShowNumpadBackspace(p), isFalse);
      expect(PosPaymentPermissionVisibility.canShowNumpadClear(p), isFalse);
    });

    test('partial digits independent', () {
      final p = EffectivePermissionSet.fromIterable([
        PosPermissionCodes.cashPaymentNumpadDigit1,
        PosPermissionCodes.cashPaymentNumpadDigit2,
        PosPermissionCodes.cashPaymentNumpadDigit4,
      ]);
      expect(PosPaymentPermissionVisibility.canShowNumpadDigit(p, '1'), isTrue);
      expect(PosPaymentPermissionVisibility.canShowNumpadDigit(p, '2'), isTrue);
      expect(PosPaymentPermissionVisibility.canShowNumpadDigit(p, '3'), isFalse);
      expect(PosPaymentPermissionVisibility.canShowNumpadDigit(p, '4'), isTrue);
    });

    test('decimal / backspace / clear independent', () {
      final p = EffectivePermissionSet.fromIterable([
        PosPermissionCodes.cashPaymentNumpadDecimal,
        PosPermissionCodes.cashPaymentControlsBackspace,
      ]);
      expect(PosPaymentPermissionVisibility.canShowNumpadDigit(p, '.'), isTrue);
      expect(PosPaymentPermissionVisibility.canShowNumpadBackspace(p), isTrue);
      expect(PosPaymentPermissionVisibility.canShowNumpadClear(p), isFalse);
    });
  });

  group('Chunk 11 — Cash completion', () {
    test('completion requires accept + completion.execute', () {
      final acceptOnly = EffectivePermissionSet.fromIterable([
        PosPermissionCodes.acceptCashPayment,
      ]);
      expect(
        PosPaymentPermissionVisibility.canCompleteCashSale(acceptOnly),
        isFalse,
      );

      final both = EffectivePermissionSet.fromIterable([
        PosPermissionCodes.acceptCashPayment,
        PosPermissionCodes.cashPaymentCompletionExecute,
      ]);
      expect(PosPaymentPermissionVisibility.canCompleteCashSale(both), isTrue);
    });
  });

  group('Chunk 11 — Sale complete / receipt actions', () {
    test('field independence', () {
      final p = EffectivePermissionSet.fromIterable([
        PosPermissionCodes.saleCompleteDetailsReceiptNumber,
        PosPermissionCodes.saleCompleteDetailsPaymentMethod,
      ]);
      expect(
        PosPaymentPermissionVisibility.canShowSaleCompleteReceiptNumber(p),
        isTrue,
      );
      expect(
        PosPaymentPermissionVisibility.canShowSaleCompletePaymentMethod(p),
        isTrue,
      );
      expect(
        PosPaymentPermissionVisibility.canShowSaleCompleteCustomer(p),
        isFalse,
      );
      expect(
        PosPaymentPermissionVisibility.canShowSaleCompleteChangeDue(p),
        isFalse,
      );
    });

    test('Print does not authorize Reprint', () {
      final printOnly = EffectivePermissionSet.fromIterable([
        PosPermissionCodes.receiptsPhysicalPrint,
      ]);
      expect(
        PosPaymentPermissionVisibility.canPrintPhysicalReceipt(printOnly),
        isTrue,
      );
      expect(
        PosPaymentPermissionVisibility.canReprintReceipt(printOnly),
        isFalse,
      );

      final reprintOnly = EffectivePermissionSet.fromIterable([
        PosPermissionCodes.receiptsHistoryReprint,
      ]);
      expect(
        PosPaymentPermissionVisibility.canPrintPhysicalReceipt(reprintOnly),
        isFalse,
      );
      expect(
        PosPaymentPermissionVisibility.canReprintReceipt(reprintOnly),
        isTrue,
      );
    });
  });

  group('Chunk 11 — Receipt details', () {
    test('partial receipt fields', () {
      final p = EffectivePermissionSet.fromIterable([
        PosPermissionCodes.receiptsDetailsTotal,
        PosPermissionCodes.receiptsDetailsPaymentMethod,
      ]);
      expect(PosPaymentPermissionVisibility.canShowReceiptTotal(p), isTrue);
      expect(
        PosPaymentPermissionVisibility.canShowReceiptPaymentMethod(p),
        isTrue,
      );
      expect(PosPaymentPermissionVisibility.canShowReceiptCustomer(p), isFalse);
      expect(
        PosPaymentPermissionVisibility.canShowReceiptChangeDue(p),
        isFalse,
      );
    });
  });
}

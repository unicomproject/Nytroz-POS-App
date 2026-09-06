import 'package:flutter_test/flutter_test.dart';
import 'package:nytroz_pos/core/access/cashier_pos/cashier_pos_canonical_permission_codes.dart';
import 'package:nytroz_pos/core/access/pos_access_codes.dart';

void main() {
  group('CashierPosCanonicalPermissionCodes Chunk 2', () {
    test('role-assignable codes are unique and four-tier', () {
      const codes = CashierPosCanonicalPermissionCodes.roleAssignableCodes;
      expect(codes.toSet().length, codes.length);
      for (final code in codes) {
        expect(code.split('.').length, 4, reason: code);
        expect(code, code.toLowerCase());
      }
    });

    test('pre-auth codes are excluded from role-assignable', () {
      expect(CashierPosCanonicalPermissionCodes.preAuthCodes.length, 7);
      for (final code in CashierPosCanonicalPermissionCodes.preAuthCodes) {
        expect(
          CashierPosCanonicalPermissionCodes.roleAssignableCodes.contains(code),
          isFalse,
        );
        expect(code.startsWith('pre_auth.'), isTrue);
      }
    });

    test('parent map references known codes and has no cycles', () {
      final known = {
        ...CashierPosCanonicalPermissionCodes.roleAssignableCodes,
        ...CashierPosCanonicalPermissionCodes.preAuthCodes,
      };
      CashierPosCanonicalPermissionCodes.parentByChild.forEach((child, parent) {
        expect(known.contains(parent), isTrue, reason: '$child -> $parent');
      });

      CashierPosCanonicalPermissionCodes.parentByChild.forEach((start, _) {
        final seen = <String>{};
        var current = start;
        while (CashierPosCanonicalPermissionCodes.parentByChild
            .containsKey(current)) {
          expect(seen.add(current), isTrue, reason: 'cycle at $current');
          current = CashierPosCanonicalPermissionCodes.parentByChild[current]!;
        }
      });
    });

    test('Chunk 1 classification counts match', () {
      expect(CashierPosCanonicalPermissionCodes.newCodes.length, 14);
      expect(CashierPosCanonicalPermissionCodes.splitCodes.length, 280);
      expect(
        CashierPosCanonicalPermissionCodes.documentedResolvedCodes,
        contains('pos.sales.held_sales.cancel'),
      );
    });

    test('backend/flutter business constants stay aligned', () {
      expect(
        PosPermissionCodes.acceptCashPayment,
        'pos.payments.cash.accept',
      );
      expect(
        PosPermissionCodes.acceptCardPayment,
        'pos.payments.card.accept',
      );
      expect(PosPermissionCodes.acceptQrPayment, 'pos.payments.qr.accept');
      expect(
        PosPermissionCodes.acceptSplitPayment,
        'pos.payments.split.accept',
      );
      expect(
        PosPermissionCodes.heldSalesCancel,
        'pos.sales.held_sales.cancel',
      );
      expect(
        PosPermissionCodes.cashDrawerCashIn,
        'pos.cash_drawer.movements.cash_in',
      );
      expect(
        PosPermissionCodes.cashDrawerCashOut,
        'pos.cash_drawer.movements.cash_out',
      );
      expect(
        PosPermissionCodes.cashDrawerCashDrop,
        'pos.cash_drawer.movements.cash_drop',
      );
      expect(
        CashierPosCanonicalPermissionCodes.roleAssignableCodes,
        containsAll([
          PosPermissionCodes.acceptCashPayment,
          PosPermissionCodes.acceptCardPayment,
          PosPermissionCodes.acceptQrPayment,
          PosPermissionCodes.acceptSplitPayment,
          PosPermissionCodes.heldSalesCancel,
          PosPermissionCodes.cashDrawerCashIn,
          PosPermissionCodes.customersAttachSale,
          PosPermissionCodes.shellNavigationSettings,
        ]),
      );
    });

    test('sensitive codes are a subset of role-assignable', () {
      for (final code in CashierPosCanonicalPermissionCodes.sensitiveCodes) {
        expect(
          CashierPosCanonicalPermissionCodes.roleAssignableCodes.contains(code),
          isTrue,
          reason: code,
        );
      }
    });
  });
}

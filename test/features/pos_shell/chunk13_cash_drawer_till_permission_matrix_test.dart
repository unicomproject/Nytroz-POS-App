import 'package:flutter_test/flutter_test.dart';
import 'package:nytroz_pos/core/access/effective_permission_set.dart';
import 'package:nytroz_pos/core/access/pos_access_codes.dart';
import 'package:nytroz_pos/core/access/pos_cash_drawer_till_visibility.dart';
import 'package:nytroz_pos/core/access/pos_permission_access.dart';

void main() {
  group('Chunk 13 — Cash Drawer independence', () {
    test('View alone does not expose expected cash', () {
      final p = EffectivePermissionSet.fromIterable([
        PosPermissionCodes.cashDrawerPositionView,
        PosPermissionCodes.cashDrawerSummaryOpeningCash,
      ]);
      expect(PosCashDrawerTillVisibility.canViewCashDrawer(p), isTrue);
      expect(PosCashDrawerTillVisibility.canShowOpeningCash(p), isTrue);
      expect(PosCashDrawerTillVisibility.canShowCashSales(p), isFalse);
      expect(PosCashDrawerTillVisibility.canShowExpectedCash(p), isFalse);
    });

    test('Cash In/Out/Drop are independent', () {
      expect(
        PosPermissionAccess.canCashIn({PosPermissionCodes.cashDrawerCashIn}),
        isTrue,
      );
      expect(
        PosPermissionAccess.canCashOut({PosPermissionCodes.cashDrawerCashIn}),
        isFalse,
      );
      expect(
        PosPermissionAccess.canCashDrop({PosPermissionCodes.cashDrawerCashIn}),
        isFalse,
      );
      expect(
        PosPermissionAccess.canCashIn({PosPermissionCodes.cashDrawerCashDrop}),
        isFalse,
      );
      expect(
        PosPermissionAccess.canCashDrop({PosPermissionCodes.cashDrawerCashDrop}),
        isTrue,
      );
    });

    test('Physical manage ≠ drawer view', () {
      final viewOnly = EffectivePermissionSet.fromIterable([
        PosPermissionCodes.cashDrawerPositionView,
      ]);
      expect(
        PosCashDrawerTillVisibility.canPhysicalOpenDrawer(viewOnly),
        isFalse,
      );
      final physical = EffectivePermissionSet.fromIterable([
        PosPermissionCodes.cashDrawerPhysicalManage,
      ]);
      expect(
        PosCashDrawerTillVisibility.canPhysicalOpenDrawer(physical),
        isTrue,
      );
    });
  });

  group('Chunk 13 — Open Drawer reasons', () {
    test('reasons are independently gated', () {
      final p = EffectivePermissionSet.fromIterable([
        PosPermissionCodes.cashDrawerPhysicalManage,
        PosPermissionCodes.cashDrawerOpenReasonProvideChange,
        PosPermissionCodes.cashDrawerOpenReasonCashCount,
      ]);
      expect(
        PosCashDrawerTillVisibility.canShowOpenReasonProvideChange(p),
        isTrue,
      );
      expect(
        PosCashDrawerTillVisibility.canShowOpenReasonTillCheck(p),
        isFalse,
      );
      expect(
        PosCashDrawerTillVisibility.canShowOpenReasonCashCount(p),
        isTrue,
      );
      expect(
        PosCashDrawerTillVisibility.canShowOpenReasonManagerOperation(p),
        isFalse,
      );
      expect(
        PosCashDrawerTillVisibility.canShowOpenReasonOther(p),
        isFalse,
      );
    });

    test('stable reason ids — no static index', () {
      final p = EffectivePermissionSet.fromIterable([
        PosPermissionCodes.cashDrawerOpenReasonCashCount,
      ]);
      final allowed = PosCashDrawerTillVisibility.openDrawerReasons
          .where((r) =>
              PosCashDrawerTillVisibility.canShowOpenReason(p, r.id))
          .map((r) => r.id)
          .toList();
      expect(allowed, ['cash_count']);
    });
  });

  group('Chunk 13 — Open / Close Till independence', () {
    test('Open does not authorize Close', () {
      expect(
        PosPermissionAccess.canOpenTill({PosPermissionCodes.tillSessionOpen}),
        isTrue,
      );
      expect(
        PosPermissionAccess.canCloseTill({PosPermissionCodes.tillSessionOpen}),
        isFalse,
      );
    });

    test('Close does not authorize Open', () {
      expect(
        PosPermissionAccess.canCloseTill({PosPermissionCodes.tillSessionClose}),
        isTrue,
      );
      expect(
        PosPermissionAccess.canOpenTill({PosPermissionCodes.tillSessionClose}),
        isFalse,
      );
    });
  });

  group('Chunk 13 — Blind cash count', () {
    test('difference UI requires expected visibility', () {
      final blind = EffectivePermissionSet.fromIterable([
        PosPermissionCodes.tillSessionClose,
        PosPermissionCodes.tillClosingCountedCashEntry,
        PosPermissionCodes.tillClosingDifference,
      ]);
      expect(
        PosCashDrawerTillVisibility.canShowClosingCountedCashEntry(blind),
        isTrue,
      );
      expect(
        PosCashDrawerTillVisibility.canShowClosingExpectedCash(blind),
        isFalse,
      );
      expect(
        PosCashDrawerTillVisibility.canExposeCloseTillDifferenceUi(blind),
        isFalse,
      );
      expect(
        PosCashDrawerTillVisibility.canExposeCloseTillBalanceStatusUi(blind),
        isFalse,
      );
    });
  });

  group('Chunk 13 — multi-device fixture logical parity', () {
    test('FIXTURE A drawer partial', () {
      final p = EffectivePermissionSet.fromIterable([
        PosPermissionCodes.cashDrawerPositionView,
        PosPermissionCodes.cashDrawerSummaryOpeningCash,
        PosPermissionCodes.cashDrawerCashIn,
        PosPermissionCodes.cashDrawerCashDrop,
      ]);
      expect(PosCashDrawerTillVisibility.canShowOpeningCash(p), isTrue);
      expect(PosCashDrawerTillVisibility.canShowCashSales(p), isFalse);
      expect(PosCashDrawerTillVisibility.canShowExpectedCash(p), isFalse);
      expect(PosCashDrawerTillVisibility.canCashIn(p), isTrue);
      expect(PosCashDrawerTillVisibility.canCashOut(p), isFalse);
      expect(PosCashDrawerTillVisibility.canCashDrop(p), isTrue);
    });

    test('FIXTURE C blind close till', () {
      final p = EffectivePermissionSet.fromIterable([
        PosPermissionCodes.tillSessionClose,
        PosPermissionCodes.tillClosingCountedCashEntry,
      ]);
      expect(PosCashDrawerTillVisibility.canCloseTill(p), isTrue);
      expect(
        PosCashDrawerTillVisibility.canShowClosingCountedCashEntry(p),
        isTrue,
      );
      expect(
        PosCashDrawerTillVisibility.canShowClosingExpectedCash(p),
        isFalse,
      );
      expect(
        PosCashDrawerTillVisibility.canExposeCloseTillDifferenceUi(p),
        isFalse,
      );
    });

    test('FIXTURE D open till without close', () {
      final p = EffectivePermissionSet.fromIterable([
        PosPermissionCodes.tillSessionOpen,
      ]);
      expect(PosCashDrawerTillVisibility.canOpenTill(p), isTrue);
      expect(PosCashDrawerTillVisibility.canCloseTill(p), isFalse);
    });
  });
}

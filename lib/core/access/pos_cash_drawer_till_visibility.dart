import 'effective_permission_set.dart';
import 'pos_access_codes.dart';
import 'pos_permission_access.dart';

/// Chunk 13 Cash Drawer / Till visibility (exact membership only).
class PosCashDrawerTillVisibility {
  const PosCashDrawerTillVisibility._();

  // --- Drawer position / summary ---
  static bool canViewCashDrawer(EffectivePermissionSet p) =>
      PosPermissionAccess.canViewCashDrawer(p.codes.toSet());

  static bool canShowSummaryTill(EffectivePermissionSet p) =>
      p.hasPermission(PosPermissionCodes.cashDrawerSummaryTill);

  static bool canShowSummaryStatus(EffectivePermissionSet p) =>
      p.hasPermission(PosPermissionCodes.cashDrawerSummaryStatus);

  static bool canShowOpeningCash(EffectivePermissionSet p) =>
      p.hasPermission(PosPermissionCodes.cashDrawerSummaryOpeningCash);

  static bool canShowCashSales(EffectivePermissionSet p) =>
      p.hasPermission(PosPermissionCodes.cashDrawerSummaryCashSales);

  static bool canShowExpectedCash(EffectivePermissionSet p) =>
      p.hasPermission(PosPermissionCodes.cashDrawerSummaryExpectedCash);

  static bool canShowMovementsList(EffectivePermissionSet p) =>
      p.hasPermission(PosPermissionCodes.cashDrawerMovementsList);

  static bool canShowMovementType(EffectivePermissionSet p) =>
      p.hasPermission(PosPermissionCodes.cashDrawerMovementsType);

  static bool canShowMovementDate(EffectivePermissionSet p) =>
      p.hasPermission(PosPermissionCodes.cashDrawerMovementsDate);

  static bool canShowMovementTime(EffectivePermissionSet p) =>
      p.hasPermission(PosPermissionCodes.cashDrawerMovementsTime);

  static bool canShowMovementCashier(EffectivePermissionSet p) =>
      p.hasPermission(PosPermissionCodes.cashDrawerMovementsCashier);

  static bool canShowMovementAmount(EffectivePermissionSet p) =>
      p.hasPermission(PosPermissionCodes.cashDrawerMovementsAmountView);

  // --- Physical open ---
  static bool canPhysicalOpenDrawer(EffectivePermissionSet p) =>
      PosPermissionAccess.canManageCashDrawerPhysical(p.codes.toSet());

  static bool canShowOpenPopup(EffectivePermissionSet p) =>
      p.hasPermission(PosPermissionCodes.cashDrawerOpenPopupView);

  static bool canContinueOpenPopup(EffectivePermissionSet p) =>
      p.hasPermission(PosPermissionCodes.cashDrawerOpenPopupContinue);

  static bool canCancelOpenPopup(EffectivePermissionSet p) =>
      p.hasPermission(PosPermissionCodes.cashDrawerOpenPopupCancel);

  static bool canShowOpenReasonProvideChange(EffectivePermissionSet p) =>
      p.hasPermission(PosPermissionCodes.cashDrawerOpenReasonProvideChange);

  static bool canShowOpenReasonTillCheck(EffectivePermissionSet p) =>
      p.hasPermission(PosPermissionCodes.cashDrawerOpenReasonTillCheck);

  static bool canShowOpenReasonCashCount(EffectivePermissionSet p) =>
      p.hasPermission(PosPermissionCodes.cashDrawerOpenReasonCashCount);

  static bool canShowOpenReasonManagerOperation(EffectivePermissionSet p) =>
      p.hasPermission(PosPermissionCodes.cashDrawerOpenReasonManagerOperation);

  static bool canShowOpenReasonOther(EffectivePermissionSet p) =>
      p.hasPermission(PosPermissionCodes.cashDrawerOpenReasonOther);

  /// Stable reason id → permission.
  static bool canShowOpenReason(EffectivePermissionSet p, String reasonId) {
    switch (reasonId) {
      case 'provide_change':
        return canShowOpenReasonProvideChange(p);
      case 'till_check':
        return canShowOpenReasonTillCheck(p);
      case 'cash_count':
        return canShowOpenReasonCashCount(p);
      case 'manager_operation':
        return canShowOpenReasonManagerOperation(p);
      case 'other':
        return canShowOpenReasonOther(p);
      default:
        return false;
    }
  }

  static const openDrawerReasons = <({String id, String label})>[
    (id: 'provide_change', label: 'Provide change'),
    (id: 'till_check', label: 'Till check'),
    (id: 'cash_count', label: 'Cash count'),
    (id: 'manager_operation', label: 'Manager operation'),
    (id: 'other', label: 'Other'),
  ];

  // --- Movements actions ---
  static bool canCashIn(EffectivePermissionSet p) =>
      PosPermissionAccess.canCashIn(p.codes.toSet());

  static bool canCashOut(EffectivePermissionSet p) =>
      PosPermissionAccess.canCashOut(p.codes.toSet());

  static bool canCashDrop(EffectivePermissionSet p) =>
      PosPermissionAccess.canCashDrop(p.codes.toSet());

  // Cash In children
  static bool canShowCashInExpectedCash(EffectivePermissionSet p) =>
      p.hasPermission(PosPermissionCodes.cashMovementsCashInExpectedCash);
  static bool canShowCashInAvailableCash(EffectivePermissionSet p) =>
      p.hasPermission(PosPermissionCodes.cashMovementsCashInAvailableCash);
  static bool canShowCashInAmountEntry(EffectivePermissionSet p) =>
      p.hasPermission(PosPermissionCodes.cashMovementsCashInAmountEntry);
  static bool canShowCashInReason(EffectivePermissionSet p) =>
      p.hasPermission(PosPermissionCodes.cashMovementsCashInReason);
  static bool canShowCashInNote(EffectivePermissionSet p) =>
      p.hasPermission(PosPermissionCodes.cashMovementsCashInNote);
  static bool canShowCashInManagerPin(EffectivePermissionSet p) =>
      p.hasPermission(PosPermissionCodes.cashMovementsCashInManagerPin);
  static bool canShowCashInSummary(EffectivePermissionSet p) =>
      p.hasPermission(PosPermissionCodes.cashMovementsCashInSummary);
  static bool canShowCashInResultingBalance(EffectivePermissionSet p) =>
      p.hasPermission(PosPermissionCodes.cashMovementsCashInResultingBalance);
  static bool canShowCashInTill(EffectivePermissionSet p) =>
      p.hasPermission(PosPermissionCodes.cashMovementsCashInTill);
  static bool canConfirmCashIn(EffectivePermissionSet p) =>
      p.hasPermission(PosPermissionCodes.cashMovementsCashInConfirm);

  // Cash Drop children
  static bool canShowCashDropExpectedCash(EffectivePermissionSet p) =>
      p.hasPermission(PosPermissionCodes.cashMovementsCashDropExpectedCash);
  static bool canShowCashDropAvailableCash(EffectivePermissionSet p) =>
      p.hasPermission(PosPermissionCodes.cashMovementsCashDropAvailableCash);
  static bool canShowCashDropAmountEntry(EffectivePermissionSet p) =>
      p.hasPermission(PosPermissionCodes.cashMovementsCashDropAmountEntry);
  static bool canShowCashDropReason(EffectivePermissionSet p) =>
      p.hasPermission(PosPermissionCodes.cashMovementsCashDropReason);
  static bool canShowCashDropNote(EffectivePermissionSet p) =>
      p.hasPermission(PosPermissionCodes.cashMovementsCashDropNote);
  static bool canShowCashDropManagerPin(EffectivePermissionSet p) =>
      p.hasPermission(PosPermissionCodes.cashMovementsCashDropManagerPin);
  static bool canShowCashDropSummary(EffectivePermissionSet p) =>
      p.hasPermission(PosPermissionCodes.cashMovementsCashDropSummary);
  static bool canShowCashDropResultingBalance(EffectivePermissionSet p) =>
      p.hasPermission(PosPermissionCodes.cashMovementsCashDropResultingBalance);
  static bool canShowCashDropTill(EffectivePermissionSet p) =>
      p.hasPermission(PosPermissionCodes.cashMovementsCashDropTill);
  static bool canConfirmCashDrop(EffectivePermissionSet p) =>
      p.hasPermission(PosPermissionCodes.cashMovementsCashDropConfirm);

  // --- Till open ---
  static bool canOpenTill(EffectivePermissionSet p) =>
      PosPermissionAccess.canOpenTill(p.codes.toSet());

  static bool canShowStartingCashView(EffectivePermissionSet p) =>
      p.hasPermission(PosPermissionCodes.tillOpeningStartingCashView);
  static bool canShowStartingCashEntry(EffectivePermissionSet p) =>
      p.hasPermission(PosPermissionCodes.tillOpeningStartingCashEntry);
  static bool canShowOpenTillNoteView(EffectivePermissionSet p) =>
      p.hasPermission(PosPermissionCodes.tillOpeningNoteView);
  static bool canShowOpenTillNoteEntry(EffectivePermissionSet p) =>
      p.hasPermission(PosPermissionCodes.tillOpeningNoteEntry);
  static bool canShowOpenTillQuickAmounts(EffectivePermissionSet p) =>
      p.hasPermission(PosPermissionCodes.tillOpeningQuickAmounts);
  static bool canShowOpenTillQuickSlot1(EffectivePermissionSet p) =>
      p.hasPermission(PosPermissionCodes.tillOpeningQuickSlot1);
  static bool canShowOpenTillQuickSlot2(EffectivePermissionSet p) =>
      p.hasPermission(PosPermissionCodes.tillOpeningQuickSlot2);
  static bool canShowOpenTillQuickSlot3(EffectivePermissionSet p) =>
      p.hasPermission(PosPermissionCodes.tillOpeningQuickSlot3);
  static bool canShowOpenTillNumpad(EffectivePermissionSet p) =>
      p.hasPermission(PosPermissionCodes.tillOpeningNumpad);
  static bool canShowOpenTillBackspace(EffectivePermissionSet p) =>
      p.hasPermission(PosPermissionCodes.tillOpeningBackspace);
  static bool canShowOpenTillClear(EffectivePermissionSet p) =>
      p.hasPermission(PosPermissionCodes.tillOpeningClear);
  static bool canShowOpenTillConfirmMessage(EffectivePermissionSet p) =>
      p.hasPermission(PosPermissionCodes.tillOpeningConfirmMessage);
  static bool canShowOpenTillValidation(EffectivePermissionSet p) =>
      p.hasPermission(PosPermissionCodes.tillOpeningValidationMessage);

  /// Exact key label → frozen `pos.till.opening.key_*` membership.
  static bool canShowOpenTillNumpadKey(EffectivePermissionSet p, String key) {
    return switch (key) {
      '0' => p.hasPermission(PosPermissionCodes.tillOpeningKey0),
      '1' => p.hasPermission(PosPermissionCodes.tillOpeningKey1),
      '2' => p.hasPermission(PosPermissionCodes.tillOpeningKey2),
      '3' => p.hasPermission(PosPermissionCodes.tillOpeningKey3),
      '4' => p.hasPermission(PosPermissionCodes.tillOpeningKey4),
      '5' => p.hasPermission(PosPermissionCodes.tillOpeningKey5),
      '6' => p.hasPermission(PosPermissionCodes.tillOpeningKey6),
      '7' => p.hasPermission(PosPermissionCodes.tillOpeningKey7),
      '8' => p.hasPermission(PosPermissionCodes.tillOpeningKey8),
      '9' => p.hasPermission(PosPermissionCodes.tillOpeningKey9),
      '00' => p.hasPermission(PosPermissionCodes.tillOpeningKey00),
      '.' => p.hasPermission(PosPermissionCodes.tillOpeningKeyDecimal),
      _ => false,
    };
  }

  /// Canonical quick amounts: 100→slot_1, 500→slot_2, 1000→slot_3.
  static const openTillQuickAmountSlots = <({int amount, int slot})>[
    (amount: 100, slot: 1),
    (amount: 500, slot: 2),
    (amount: 1000, slot: 3),
  ];

  static bool canShowOpenTillQuickSlot(EffectivePermissionSet p, int slot) {
    return switch (slot) {
      1 => canShowOpenTillQuickSlot1(p),
      2 => canShowOpenTillQuickSlot2(p),
      3 => canShowOpenTillQuickSlot3(p),
      _ => false,
    };
  }

  /// Container + slot; denied slots omitted (no blank space).
  static List<int> filterOpenTillQuickAmounts(EffectivePermissionSet p) {
    if (!canShowOpenTillQuickAmounts(p)) return const [];
    return [
      for (final item in openTillQuickAmountSlots)
        if (canShowOpenTillQuickSlot(p, item.slot)) item.amount,
    ];
  }

  /// Shared authorize path for keypad + physical keyboard digit mutation.
  /// Requires entry + numpad container + exact key permission.
  static bool canAuthorizeOpenTillKeyInput(
    EffectivePermissionSet p,
    String key,
  ) {
    return canShowStartingCashEntry(p) &&
        canShowOpenTillNumpad(p) &&
        canShowOpenTillNumpadKey(p, key);
  }

  static bool canAuthorizeOpenTillBackspace(EffectivePermissionSet p) =>
      canShowStartingCashEntry(p) && canShowOpenTillBackspace(p);

  static bool canAuthorizeOpenTillClear(EffectivePermissionSet p) =>
      canShowStartingCashEntry(p) && canShowOpenTillClear(p);

  static bool canAuthorizeOpenTillQuickAmount(
    EffectivePermissionSet p,
    int amount,
  ) {
    if (!canShowStartingCashEntry(p) || !canShowOpenTillQuickAmounts(p)) {
      return false;
    }
    for (final item in openTillQuickAmountSlots) {
      if (item.amount == amount) {
        return canShowOpenTillQuickSlot(p, item.slot);
      }
    }
    return false;
  }

  // --- Till close ---
  static bool canCloseTill(EffectivePermissionSet p) =>
      PosPermissionAccess.canCloseTill(p.codes.toSet());

  static bool canShowClosingTill(EffectivePermissionSet p) =>
      p.hasPermission(PosPermissionCodes.tillClosingTill);
  static bool canShowClosingOpenedBy(EffectivePermissionSet p) =>
      p.hasPermission(PosPermissionCodes.tillClosingOpenedBy);
  static bool canShowClosingOpenedTime(EffectivePermissionSet p) =>
      p.hasPermission(PosPermissionCodes.tillClosingOpenedTime);
  static bool canShowClosingExpectedCash(EffectivePermissionSet p) =>
      p.hasPermission(PosPermissionCodes.tillClosingExpectedCash);
  static bool canShowClosingCountedCashEntry(EffectivePermissionSet p) =>
      p.hasPermission(PosPermissionCodes.tillClosingCountedCashEntry);
  static bool canShowClosingDifference(EffectivePermissionSet p) =>
      p.hasPermission(PosPermissionCodes.tillClosingDifference);
  static bool canShowClosingBalanceStatus(EffectivePermissionSet p) =>
      p.hasPermission(PosPermissionCodes.tillClosingBalanceStatus);
  static bool canShowClosingMismatchReason(EffectivePermissionSet p) =>
      p.hasPermission(PosPermissionCodes.tillClosingMismatchReason);
  static bool canShowClosingNotes(EffectivePermissionSet p) =>
      p.hasPermission(PosPermissionCodes.tillClosingNotes);
  static bool canShowClosingSummary(EffectivePermissionSet p) =>
      p.hasPermission(PosPermissionCodes.tillClosingSummary);
  static bool canShowClosingExpectedCashSummary(EffectivePermissionSet p) =>
      p.hasPermission(PosPermissionCodes.tillClosingExpectedCashSummary);
  static bool canShowClosingCountedCashSummary(EffectivePermissionSet p) =>
      p.hasPermission(PosPermissionCodes.tillClosingCountedCashSummary);
  static bool canShowClosingDifferenceSummary(EffectivePermissionSet p) =>
      p.hasPermission(PosPermissionCodes.tillClosingDifferenceSummary);
  static bool canShowClosingStatusSummary(EffectivePermissionSet p) =>
      p.hasPermission(PosPermissionCodes.tillClosingStatusSummary);

  /// Blind-count safety: difference/status must not reveal expected cash.
  static bool canExposeCloseTillDifferenceUi(EffectivePermissionSet p) =>
      canShowClosingDifference(p) && canShowClosingExpectedCash(p);

  static bool canExposeCloseTillBalanceStatusUi(EffectivePermissionSet p) =>
      canShowClosingBalanceStatus(p) && canShowClosingExpectedCash(p);
}

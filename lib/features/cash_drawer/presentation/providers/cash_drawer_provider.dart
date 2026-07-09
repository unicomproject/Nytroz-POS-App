import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/session_provider.dart';
import '../../../cart/presentation/providers/pos_new_sale_cart_provider.dart';
import '../../../device_activation/presentation/providers/device_activation_provider.dart';
import '../../../till/presentation/providers/till_provider.dart';
import '../../../../shared/pos_session/pos_session_provider.dart';
import '../../domain/entities/cash_drawer_summary.dart';
import '../../domain/entities/cash_movement.dart';

/// Frontend-only cash drawer state.
/// backend endpoints exist (movements list, cash in/out, close till).
class CashDrawerState {
  const CashDrawerState({
    this.summary,
    this.movements = const [],
    this.isSubmitting = false,
    this.errorMessage,
    this.closeTillMessage,
  });

  final CashDrawerSummary? summary;
  final List<CashMovement> movements;
  final bool isSubmitting;
  final String? errorMessage;
  final String? closeTillMessage;

  bool get hasOpenTill => summary?.isOpen == true;

  CashDrawerState copyWith({
    CashDrawerSummary? summary,
    List<CashMovement>? movements,
    bool? isSubmitting,
    String? errorMessage,
    String? closeTillMessage,
    bool clearError = false,
    bool clearCloseTillMessage = false,
  }) {
    return CashDrawerState(
      summary: summary ?? this.summary,
      movements: movements ?? this.movements,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      closeTillMessage: clearCloseTillMessage
          ? null
          : closeTillMessage ?? this.closeTillMessage,
    );
  }
}

class CashDrawerController extends StateNotifier<CashDrawerState> {
  CashDrawerController(this._ref) : super(const CashDrawerState()) {
    _ref.listen(tillProvider, (_, __) => refresh());
    refresh();
  }

  final Ref _ref;
  var _movementSequence = 0;

  void refresh() {
    final tillState = _ref.read(tillProvider);
    final sessionContext = _ref.read(posSessionContextProvider);
    final authSession = _ref.read(authSessionProvider);
    final tillSession = tillState.session;
    final hasOpenSession = tillState.hasOpenSession;

    final openingCash = tillSession?.openingFloat ?? 0;
    final movements = state.movements;

    final totals = _totalsFromMovements(movements);
    final expectedCash = openingCash +
        totals.cashSales +
        totals.cashIns -
        totals.cashRefunds -
        totals.cashDrops -
        totals.cashOuts;

    state = state.copyWith(
      clearError: true,
      summary: CashDrawerSummary(
        tillName: tillSession?.tillName.trim().isNotEmpty == true
            ? tillSession!.tillName
            : sessionContext.tillName,
        status: hasOpenSession ? 'Open' : 'Closed',
        openedBy: authSession?.userDisplayName.trim().isNotEmpty == true
            ? authSession!.userDisplayName
            : sessionContext.userName,
        openedTime: tillSession?.openedAt,
        openingCash: openingCash,
        cashSales: totals.cashSales,
        cashRefunds: totals.cashRefunds,
        cashDrops: totals.cashDrops,
        cashIns: totals.cashIns,
        cashOuts: totals.cashOuts,
        currentExpectedCash: expectedCash,
      ),
    );
  }

  Future<bool> recordCashIn({
    required double amount,
    String? reason,
    String? note,
  }) async {
    return _recordMovement(
      type: CashMovementType.cashIn,
      amount: amount,
      reason: reason,
      note: note,
    );
  }

  Future<bool> recordCashOut({
    required double amount,
    String? note,
  }) async {
    final expected = state.summary?.currentExpectedCash ?? 0;
    if (amount > expected) {
      state = state.copyWith(
        errorMessage:
            'Amount cannot exceed current expected cash (${formatLkr(expected.round())}).',
      );
      return false;
    }

    return _recordMovement(
      type: CashMovementType.cashOut,
      amount: amount,
      note: note,
    );
  }

  Future<bool> recordCashDrop({
    required double amount,
    String? reason,
    String? note,
  }) async {
    final expected = state.summary?.currentExpectedCash ?? 0;
    if (amount > expected) {
      state = state.copyWith(
        errorMessage:
            'Amount cannot exceed available cash in drawer (${formatLkr(expected.round())}).',
      );
      return false;
    }

    return _recordMovement(
      type: CashMovementType.cashDrop,
      amount: amount,
      reason: reason,
      note: note,
    );
  }

  Future<bool> submitCloseTill({
    required double countedCash,
    String? mismatchReason,
    String? note,
  }) async {
    final summary = state.summary;
    if (summary == null || !summary.isOpen) {
      state = state.copyWith(
        errorMessage: 'An open till session is required to close the till.',
      );
      return false;
    }

    if (countedCash < 0) {
      state = state.copyWith(
        errorMessage: 'Counted cash must be zero or greater.',
      );
      return false;
    }

    final device = _ref.read(deviceActivationProvider).deviceContext;
    if (device == null) {
      state = state.copyWith(
        errorMessage: 'Device context is required to close the till.',
      );
      return false;
    }

    state = state.copyWith(isSubmitting: true, clearError: true);

    final closedSession = await _ref.read(tillProvider.notifier).closeTill(
          deviceContext: device,
          countedCash: countedCash,
          expectedCash: summary.currentExpectedCash,
          mismatchReason: mismatchReason,
          closingNote: note,
        );

    if (closedSession == null) {
      final tillError = _ref.read(tillProvider).errorMessage;
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: tillError ?? 'Till could not be closed. Try again.',
      );
      return false;
    }

    final difference = closedSession.cashDifference;
    final differenceLabel = difference == 0
        ? 'balanced'
        : difference > 0
            ? 'over by ${formatLkr(difference.abs().round())}'
            : 'short by ${formatLkr(difference.abs().round())}';

    refresh();
    state = state.copyWith(
      isSubmitting: false,
      clearCloseTillMessage: true,
      closeTillMessage: 'Till closed successfully. Count was $differenceLabel.',
    );
    return true;
  }

  Future<bool> _recordMovement({
    required CashMovementType type,
    required double amount,
    String? reason,
    String? note,
  }) async {
    final summary = state.summary;
    if (summary == null || !summary.isOpen) {
      state = state.copyWith(
        errorMessage: 'An open till session is required for cash movements.',
      );
      return false;
    }

    if (amount <= 0) {
      state = state.copyWith(
        errorMessage: 'Amount must be greater than zero.',
      );
      return false;
    }

    state = state.copyWith(isSubmitting: true, clearError: true);

    await Future<void>.delayed(const Duration(milliseconds: 250));

    final authSession = _ref.read(authSessionProvider);
    final userName = authSession?.userDisplayName.trim().isNotEmpty == true
        ? authSession!.userDisplayName
        : _ref.read(posSessionContextProvider).userName;

    _movementSequence += 1;
    final movement = CashMovement(
      id: 'local-${DateTime.now().millisecondsSinceEpoch}-$_movementSequence',
      type: type,
      amount: amount,
      dateTime: DateTime.now(),
      userName: userName,
      reason: reason?.trim().isEmpty == true ? null : reason?.trim(),
      note: note?.trim().isEmpty == true ? null : note?.trim(),
    );

    final movements = [movement, ...state.movements];
    final totals = _totalsFromMovements(movements);
    final expectedCash = summary.openingCash +
        totals.cashSales +
        totals.cashIns -
        totals.cashRefunds -
        totals.cashDrops -
        totals.cashOuts;

    state = state.copyWith(
      isSubmitting: false,
      movements: movements,
      summary: summary.copyWith(
        cashSales: totals.cashSales,
        cashRefunds: totals.cashRefunds,
        cashDrops: totals.cashDrops,
        cashIns: totals.cashIns,
        cashOuts: totals.cashOuts,
        currentExpectedCash: expectedCash,
      ),
    );
    return true;
  }

  _MovementTotals _totalsFromMovements(List<CashMovement> movements) {
    var cashSales = 0.0;
    var cashRefunds = 0.0;
    var cashDrops = 0.0;
    var cashIns = 0.0;
    var cashOuts = 0.0;

    for (final movement in movements) {
      switch (movement.type) {
        case CashMovementType.cashSale:
          cashSales += movement.amount;
        case CashMovementType.cashRefund:
          cashRefunds += movement.amount;
        case CashMovementType.cashDrop:
          cashDrops += movement.amount;
        case CashMovementType.cashIn:
          cashIns += movement.amount;
        case CashMovementType.cashOut:
          cashOuts += movement.amount;
      }
    }

    return _MovementTotals(
      cashSales: cashSales,
      cashRefunds: cashRefunds,
      cashDrops: cashDrops,
      cashIns: cashIns,
      cashOuts: cashOuts,
    );
  }
}

class _MovementTotals {
  const _MovementTotals({
    required this.cashSales,
    required this.cashRefunds,
    required this.cashDrops,
    required this.cashIns,
    required this.cashOuts,
  });

  final double cashSales;
  final double cashRefunds;
  final double cashDrops;
  final double cashIns;
  final double cashOuts;
}

final cashDrawerProvider =
    StateNotifierProvider<CashDrawerController, CashDrawerState>((ref) {
  return CashDrawerController(ref);
});

String formatCashDrawerAmount(double value) {
  return formatLkr(value.round());
}

String formatCashDrawerDateTime(DateTime value) {
  final hour = value.hour % 12 == 0 ? 12 : value.hour % 12;
  final minute = value.minute.toString().padLeft(2, '0');
  final period = value.hour >= 12 ? 'PM' : 'AM';
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${months[value.month - 1]} ${value.day}, ${value.year} • $hour:$minute $period';
}

String formatCashDrawerOpenedTime(DateTime? value) {
  if (value == null) {
    return '—';
  }

  final hour = value.hour % 12 == 0 ? 12 : value.hour % 12;
  final minute = value.minute.toString().padLeft(2, '0');
  final period = value.hour >= 12 ? 'PM' : 'AM';
  return '$hour:$minute $period';
}

import 'dart:math' as math;
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PosCashPaymentState {
  const PosCashPaymentState({
    required this.cashReceived,
    required this.inputBuffer,
    this.selectedQuickAmount,
  });

  final int cashReceived;
  final String inputBuffer;
  final int? selectedQuickAmount;

  PosCashPaymentState copyWith({
    int? cashReceived,
    String? inputBuffer,
    int? selectedQuickAmount,
    bool clearSelectedQuickAmount = false,
  }) {
    return PosCashPaymentState(
      cashReceived: cashReceived ?? this.cashReceived,
      inputBuffer: inputBuffer ?? this.inputBuffer,
      selectedQuickAmount: clearSelectedQuickAmount
          ? null
          : (selectedQuickAmount ?? this.selectedQuickAmount),
    );
  }
}

class PosCashPaymentNotifier extends StateNotifier<PosCashPaymentState> {
  PosCashPaymentNotifier()
      : super(
          const PosCashPaymentState(
            cashReceived: 0,
            inputBuffer: '',
          ),
        );

  static const _maxDigitCount = 9;

  void clearAmount() {
    state = const PosCashPaymentState(
      cashReceived: 0,
      inputBuffer: '',
      selectedQuickAmount: null,
    );
  }

  void setAmount(int amount, {int? selectedQuickAmount}) {
    state = PosCashPaymentState(
      cashReceived: amount,
      inputBuffer: amount == 0 ? '' : amount.toString(),
      selectedQuickAmount: selectedQuickAmount,
    );
  }

  void appendKey(String key) {
    if (key == 'ok' || key == '.' || key == '+' || key == '-') {
      return;
    }

    if (key == 'clear') {
      clearAmount();
      return;
    }

    if (key == 'backspace') {
      if (state.inputBuffer.isEmpty) {
        return;
      }

      final nextBuffer =
          state.inputBuffer.substring(0, state.inputBuffer.length - 1);
      final nextCash = _parseAmount(nextBuffer);
      state = PosCashPaymentState(
        inputBuffer: nextBuffer,
        cashReceived: nextCash,
        selectedQuickAmount: nextCash == state.selectedQuickAmount
            ? state.selectedQuickAmount
            : null,
      );
      return;
    }

    if (key == '00') {
      if (state.inputBuffer.isEmpty || state.inputBuffer == '0') {
        return;
      }
    }

    final nextBuffer = (state.inputBuffer.isEmpty || state.inputBuffer == '0')
        ? key
        : '${state.inputBuffer}$key';

    if (nextBuffer.length > _maxDigitCount) {
      return;
    }

    final nextCash = _parseAmount(nextBuffer);

    state = PosCashPaymentState(
      inputBuffer: nextBuffer,
      cashReceived: nextCash,
      selectedQuickAmount: nextCash == state.selectedQuickAmount
          ? state.selectedQuickAmount
          : null,
    );
  }

  int _parseAmount(String buffer) {
    if (buffer.isEmpty) {
      return 0;
    }
    return int.tryParse(buffer) ?? 0;
  }
}

final posCashPaymentProvider = StateNotifierProvider.autoDispose<
    PosCashPaymentNotifier, PosCashPaymentState>(
  (ref) => PosCashPaymentNotifier(),
);

int cashPaymentChangeDue(int cashReceived, int total) {
  return math.max(cashReceived - total, 0);
}

bool canConfirmCashPayment(int cashReceived, int total) {
  return cashReceived >= total && total > 0;
}

List<int> generateCashQuickAmounts(int totalDue) {
  if (totalDue <= 0) {
    return [];
  }

  final exactAmount = totalDue;
  final int nextRoundedAmount;
  if (totalDue % 1000 == 0) {
    nextRoundedAmount = totalDue + 1000;
  } else {
    nextRoundedAmount = (totalDue / 1000).ceil() * 1000;
  }
  final thirdAmount = nextRoundedAmount + 1000;

  final amounts = <int>[exactAmount];
  if (nextRoundedAmount != exactAmount) {
    amounts.add(nextRoundedAmount);
  }
  if (thirdAmount != exactAmount && thirdAmount != nextRoundedAmount) {
    amounts.add(thirdAmount);
  }
  return amounts;
}

import 'package:flutter_riverpod/flutter_riverpod.dart';

class PosCashPaymentState {
  const PosCashPaymentState({
    required this.cashReceived,
    required this.inputBuffer,
  });

  final int cashReceived;
  final String inputBuffer;

  PosCashPaymentState copyWith({
    int? cashReceived,
    String? inputBuffer,
  }) {
    return PosCashPaymentState(
      cashReceived: cashReceived ?? this.cashReceived,
      inputBuffer: inputBuffer ?? this.inputBuffer,
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
    );
  }

  void appendKey(String key) {
    if (key == '.') {
      if (state.inputBuffer.contains('.')) {
        return;
      }

      final nextBuffer =
          state.inputBuffer.isEmpty ? '0.' : '${state.inputBuffer}.';
      state = state.copyWith(
        inputBuffer: nextBuffer,
        cashReceived: _parseAmount(nextBuffer),
      );
      return;
    }

    if (key == 'backspace') {
      if (state.inputBuffer.isEmpty) {
        return;
      }

      final nextBuffer =
          state.inputBuffer.substring(0, state.inputBuffer.length - 1);
      state = PosCashPaymentState(
        inputBuffer: nextBuffer,
        cashReceived: _parseAmount(nextBuffer),
      );
      return;
    }

    final digitCount = state.inputBuffer.replaceAll('.', '').length;
    if (digitCount >= _maxDigitCount) {
      return;
    }

    final nextBuffer = state.inputBuffer == '0' ? key : '${state.inputBuffer}$key';
    state = PosCashPaymentState(
      inputBuffer: nextBuffer,
      cashReceived: _parseAmount(nextBuffer),
    );
  }

  int _parseAmount(String buffer) {
    if (buffer.isEmpty || buffer == '.') {
      return 0;
    }

    final normalized =
        buffer.endsWith('.') ? buffer.substring(0, buffer.length - 1) : buffer;
    if (normalized.isEmpty) {
      return 0;
    }

    final parsed = double.tryParse(normalized);
    if (parsed == null) {
      return 0;
    }

    return parsed.round();
  }
}

final posCashPaymentProvider =
    StateNotifierProvider.autoDispose<PosCashPaymentNotifier, PosCashPaymentState>(
  (ref) => PosCashPaymentNotifier(),
);

int cashPaymentChangeDue(int cashReceived, int total) {
  return cashReceived - total;
}

bool canConfirmCashPayment(int cashReceived, int total) {
  return cashReceived >= total && total > 0;
}

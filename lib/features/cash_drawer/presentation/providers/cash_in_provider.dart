import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/cash_in_reason.dart';

class CashInFormState {
  const CashInFormState({
    this.amountText = '',
    this.reason,
    this.note = '',
    this.managerPin = '',
    this.obscureManagerPin = true,
  });

  final String amountText;
  final String? reason;
  final String note;
  final String managerPin;
  final bool obscureManagerPin;

  double? get parsedAmount {
    final raw = amountText.trim();
    if (raw.isEmpty) {
      return null;
    }
    return double.tryParse(raw);
  }

  bool get hasValidAmount => parsedAmount != null && parsedAmount! > 0;

  CashInFormState copyWith({
    String? amountText,
    String? reason,
    String? note,
    String? managerPin,
    bool? obscureManagerPin,
    bool clearReason = false,
  }) {
    return CashInFormState(
      amountText: amountText ?? this.amountText,
      reason: clearReason ? null : reason ?? this.reason,
      note: note ?? this.note,
      managerPin: managerPin ?? this.managerPin,
      obscureManagerPin: obscureManagerPin ?? this.obscureManagerPin,
    );
  }
}

class CashInFormController extends StateNotifier<CashInFormState> {
  CashInFormController() : super(const CashInFormState());

  void reset() {
    state = const CashInFormState();
  }

  void setAmountText(String value) {
    state = state.copyWith(amountText: value);
  }

  void setReason(String? value) {
    state = state.copyWith(reason: value);
  }

  void setNote(String value) {
    state = state.copyWith(note: value);
  }

  void setManagerPin(String value) {
    state = state.copyWith(managerPin: value);
  }

  void toggleManagerPinVisibility() {
    state = state.copyWith(obscureManagerPin: !state.obscureManagerPin);
  }
}

final cashInFormProvider =
    StateNotifierProvider.autoDispose<CashInFormController, CashInFormState>(
  (ref) => CashInFormController(),
);

double cashInNewExpectedCash({
  required double currentExpectedCash,
  required CashInFormState form,
}) {
  final amount = form.parsedAmount ?? 0;
  return currentExpectedCash + amount;
}

String? validateCashInAmount(String? value) {
  final raw = value?.trim() ?? '';
  if (raw.isEmpty) {
    return 'Amount is required';
  }

  final amount = double.tryParse(raw);
  if (amount == null) {
    return 'Enter a valid amount';
  }

  if (amount <= 0) {
    return 'Amount must be greater than zero';
  }

  return null;
}

String? validateCashInReason(String? value) {
  if (value == null || value.trim().isEmpty) {
    return 'Reason is required';
  }

  if (!CashInReason.options.contains(value)) {
    return 'Select a valid reason';
  }

  return null;
}

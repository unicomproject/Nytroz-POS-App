import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/cash_drop_reason.dart';

class CashDropFormState {
  const CashDropFormState({
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

  CashDropFormState copyWith({
    String? amountText,
    String? reason,
    String? note,
    String? managerPin,
    bool? obscureManagerPin,
    bool clearReason = false,
  }) {
    return CashDropFormState(
      amountText: amountText ?? this.amountText,
      reason: clearReason ? null : reason ?? this.reason,
      note: note ?? this.note,
      managerPin: managerPin ?? this.managerPin,
      obscureManagerPin: obscureManagerPin ?? this.obscureManagerPin,
    );
  }
}

class CashDropFormController extends StateNotifier<CashDropFormState> {
  CashDropFormController() : super(const CashDropFormState());

  void reset() {
    state = const CashDropFormState();
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

final cashDropFormProvider = StateNotifierProvider.autoDispose<
    CashDropFormController, CashDropFormState>(
  (ref) => CashDropFormController(),
);

double cashDropRemainingExpectedCash({
  required double currentExpectedCash,
  required CashDropFormState form,
}) {
  final amount = form.parsedAmount ?? 0;
  return currentExpectedCash - amount;
}

String? validateCashDropAmount(String? value, {required double maxAvailable}) {
  final raw = value?.trim() ?? '';
  if (raw.isEmpty) {
    return 'Drop amount is required';
  }

  final amount = double.tryParse(raw);
  if (amount == null) {
    return 'Enter a valid amount';
  }

  if (amount <= 0) {
    return 'Amount must be greater than zero';
  }

  if (amount > maxAvailable) {
    return 'Amount cannot exceed available cash in drawer';
  }

  return null;
}

String? validateCashDropReason(String? value) {
  if (value == null || value.trim().isEmpty) {
    return 'Reason is required';
  }

  if (!CashDropReason.options.contains(value)) {
    return 'Select a valid reason';
  }

  return null;
}

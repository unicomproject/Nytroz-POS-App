import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/return_reason_option.dart';

const returnReasonNotesMaxLength = 500;

class ReturnReasonState {
  const ReturnReasonState({
    this.selectedReasonCode,
    this.notes = '',
    this.showValidationMessage = false,
  });

  final String? selectedReasonCode;
  final String notes;
  final bool showValidationMessage;

  bool get hasSelectedReason =>
      selectedReasonCode != null && selectedReasonCode!.isNotEmpty;

  ReturnReasonState copyWith({
    String? selectedReasonCode,
    String? notes,
    bool? showValidationMessage,
    bool clearSelectedReason = false,
  }) {
    return ReturnReasonState(
      selectedReasonCode: clearSelectedReason
          ? null
          : selectedReasonCode ?? this.selectedReasonCode,
      notes: notes ?? this.notes,
      showValidationMessage:
          showValidationMessage ?? this.showValidationMessage,
    );
  }
}

class ReturnReasonController extends StateNotifier<ReturnReasonState> {
  ReturnReasonController() : super(const ReturnReasonState());

  void hydrate({
    required String? selectedReasonCode,
    required String notes,
  }) {
    state = ReturnReasonState(
      selectedReasonCode: selectedReasonCode,
      notes: notes,
    );
  }

  void selectReason(String code) {
    state = state.copyWith(
      selectedReasonCode: code,
      showValidationMessage: false,
    );
  }

  void setNotes(String value) {
    final trimmed = value.length <= returnReasonNotesMaxLength
        ? value
        : value.substring(0, returnReasonNotesMaxLength);
    state = state.copyWith(notes: trimmed);
  }

  bool validate() {
    if (state.hasSelectedReason) {
      state = state.copyWith(showValidationMessage: false);
      return true;
    }

    state = state.copyWith(showValidationMessage: true);
    return false;
  }

  void reset() {
    state = const ReturnReasonState();
  }
}

String? validateReturnReasonCode(String? value) {
  if (value == null || value.isEmpty) {
    return 'A return reason is required.';
  }

  if (ReturnReasonOption.findByCode(value) == null) {
    return 'Select a valid return reason.';
  }

  return null;
}

final returnReasonProvider =
    StateNotifierProvider.autoDispose<ReturnReasonController, ReturnReasonState>(
  (ref) => ReturnReasonController(),
);

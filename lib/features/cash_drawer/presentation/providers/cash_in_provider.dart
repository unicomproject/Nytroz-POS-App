import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/cash_movement_type.dart';
import '../../domain/repositories/cash_drawer_repository.dart';
import 'cash_drawer_provider.dart';

class CashInFormState {
  const CashInFormState({
    this.amountText = '',
    this.selectedMovementTypeId,
    this.note = '',
    this.managerPin = '',
    this.obscureManagerPin = true,
    this.pendingRequestId,
  });

  final String amountText;
  final String? selectedMovementTypeId;
  final String note;
  final String managerPin;
  final bool obscureManagerPin;

  /// Stable idempotency key for the current logical Cash In submission.
  final String? pendingRequestId;

  double? get parsedAmount {
    final raw = amountText.trim();
    if (raw.isEmpty) {
      return null;
    }
    return double.tryParse(raw);
  }

  bool get hasValidAmount => parsedAmount != null && parsedAmount! > 0;

  bool get hasSelectedMovementType =>
      selectedMovementTypeId != null && selectedMovementTypeId!.trim().isNotEmpty;

  CashInFormState copyWith({
    String? amountText,
    String? selectedMovementTypeId,
    String? note,
    String? managerPin,
    bool? obscureManagerPin,
    String? pendingRequestId,
    bool clearSelectedMovementType = false,
    bool clearPendingRequestId = false,
  }) {
    return CashInFormState(
      amountText: amountText ?? this.amountText,
      selectedMovementTypeId: clearSelectedMovementType
          ? null
          : selectedMovementTypeId ?? this.selectedMovementTypeId,
      note: note ?? this.note,
      managerPin: managerPin ?? this.managerPin,
      obscureManagerPin: obscureManagerPin ?? this.obscureManagerPin,
      pendingRequestId: clearPendingRequestId
          ? null
          : pendingRequestId ?? this.pendingRequestId,
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

  void setSelectedMovementTypeId(String? value) {
    state = state.copyWith(
      selectedMovementTypeId: value,
      clearSelectedMovementType: value == null,
    );
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

  /// Returns the request id for the current logical submit; creates once.
  String ensurePendingRequestId() {
    final existing = state.pendingRequestId;
    if (existing != null && existing.isNotEmpty) {
      return existing;
    }
    final created = _newRequestId();
    state = state.copyWith(pendingRequestId: created);
    return created;
  }

  void clearPendingRequestId() {
    state = state.copyWith(clearPendingRequestId: true);
  }
}

enum CashInCatalogStatus {
  initial,
  loading,
  ready,
  empty,
  failure,
}

class CashInCatalogState {
  const CashInCatalogState({
    this.status = CashInCatalogStatus.initial,
    this.types = const [],
    this.errorMessage,
  });

  final CashInCatalogStatus status;
  final List<CashMovementTypeOption> types;
  final String? errorMessage;

  bool get isLoading =>
      status == CashInCatalogStatus.initial ||
      status == CashInCatalogStatus.loading;

  CashInCatalogState copyWith({
    CashInCatalogStatus? status,
    List<CashMovementTypeOption>? types,
    String? errorMessage,
    bool clearError = false,
  }) {
    return CashInCatalogState(
      status: status ?? this.status,
      types: types ?? this.types,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}

class CashInCatalogController extends StateNotifier<CashInCatalogState> {
  CashInCatalogController(this._repository) : super(const CashInCatalogState());

  final CashDrawerRepository _repository;

  Future<void> load() async {
    state = state.copyWith(
      status: CashInCatalogStatus.loading,
      clearError: true,
    );
    try {
      final types = await _repository.getCashInMovementTypes();
      if (types.isEmpty) {
        state = state.copyWith(
          status: CashInCatalogStatus.empty,
          types: const [],
          clearError: true,
        );
        return;
      }
      state = state.copyWith(
        status: CashInCatalogStatus.ready,
        types: types,
        clearError: true,
      );
    } catch (error) {
      final message = error is Exception
          ? error.toString().replaceFirst(RegExp(r'^[^:]+:\s*'), '')
          : error.toString();
      state = state.copyWith(
        status: CashInCatalogStatus.failure,
        types: const [],
        errorMessage: message,
      );
    }
  }
}

final cashInFormProvider =
    StateNotifierProvider.autoDispose<CashInFormController, CashInFormState>(
  (ref) => CashInFormController(),
);

final cashInCatalogProvider = StateNotifierProvider.autoDispose<
    CashInCatalogController, CashInCatalogState>((ref) {
  return CashInCatalogController(ref.watch(cashDrawerRepositoryProvider));
});

double? cashInNewExpectedCash({
  required double? currentExpectedCash,
  required CashInFormState form,
}) {
  if (currentExpectedCash == null) {
    return null;
  }
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

String? validateCashInMovementType(
  String? movementTypeId, {
  required List<CashMovementTypeOption> availableTypes,
}) {
  if (movementTypeId == null || movementTypeId.trim().isEmpty) {
    return 'Reason is required';
  }

  final exists =
      availableTypes.any((type) => type.movementTypeId == movementTypeId);
  if (!exists) {
    return 'Select a valid reason';
  }

  return null;
}

String currencyInputPrefix(String currencyCode) {
  final code = currencyCode.trim();
  return code.isEmpty ? '' : code;
}

String _newRequestId() {
  final random = Random.secure();
  final bytes = List<int>.generate(16, (_) => random.nextInt(256));
  bytes[6] = (bytes[6] & 0x0f) | 0x40;
  bytes[8] = (bytes[8] & 0x3f) | 0x80;
  final hex =
      bytes.map((value) => value.toRadixString(16).padLeft(2, '0')).join();
  return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
      '${hex.substring(12, 16)}-${hex.substring(16, 20)}-'
      '${hex.substring(20)}';
}

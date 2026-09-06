import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/cash_movement_type.dart';
import '../../domain/repositories/cash_drawer_repository.dart';
import 'cash_drawer_provider.dart';

class CashDropFormState {
  const CashDropFormState({
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

  /// Stable idempotency key for the current logical Cash Drop submission.
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

  CashDropFormState copyWith({
    String? amountText,
    String? selectedMovementTypeId,
    String? note,
    String? managerPin,
    bool? obscureManagerPin,
    String? pendingRequestId,
    bool clearSelectedMovementType = false,
    bool clearPendingRequestId = false,
  }) {
    return CashDropFormState(
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

class CashDropFormController extends StateNotifier<CashDropFormState> {
  CashDropFormController() : super(const CashDropFormState());

  void reset() {
    state = const CashDropFormState();
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

enum CashDropCatalogStatus {
  initial,
  loading,
  ready,
  empty,
  failure,
}

class CashDropCatalogState {
  const CashDropCatalogState({
    this.status = CashDropCatalogStatus.initial,
    this.types = const [],
    this.errorMessage,
  });

  final CashDropCatalogStatus status;
  final List<CashMovementTypeOption> types;
  final String? errorMessage;

  bool get isLoading =>
      status == CashDropCatalogStatus.initial ||
      status == CashDropCatalogStatus.loading;

  CashDropCatalogState copyWith({
    CashDropCatalogStatus? status,
    List<CashMovementTypeOption>? types,
    String? errorMessage,
    bool clearError = false,
  }) {
    return CashDropCatalogState(
      status: status ?? this.status,
      types: types ?? this.types,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}

class CashDropCatalogController extends StateNotifier<CashDropCatalogState> {
  CashDropCatalogController(this._repository) : super(const CashDropCatalogState());

  final CashDrawerRepository _repository;

  Future<void> load() async {
    state = state.copyWith(
      status: CashDropCatalogStatus.loading,
      clearError: true,
    );
    try {
      final types = await _repository.getCashDropMovementTypes();
      if (types.isEmpty) {
        state = state.copyWith(
          status: CashDropCatalogStatus.empty,
          types: const [],
          clearError: true,
        );
        return;
      }
      state = state.copyWith(
        status: CashDropCatalogStatus.ready,
        types: types,
        clearError: true,
      );
    } catch (error) {
      final message = error is Exception
          ? error.toString().replaceFirst(RegExp(r'^[^:]+:\s*'), '')
          : error.toString();
      state = state.copyWith(
        status: CashDropCatalogStatus.failure,
        types: const [],
        errorMessage: message,
      );
    }
  }
}

final cashDropFormProvider = StateNotifierProvider.autoDispose<
    CashDropFormController, CashDropFormState>(
  (ref) => CashDropFormController(),
);

final cashDropCatalogProvider = StateNotifierProvider.autoDispose<
    CashDropCatalogController, CashDropCatalogState>((ref) {
  return CashDropCatalogController(ref.watch(cashDrawerRepositoryProvider));
});

double? cashDropRemainingExpectedCash({
  required double? currentExpectedCash,
  required CashDropFormState form,
}) {
  if (currentExpectedCash == null) {
    return null;
  }
  final amount = form.parsedAmount ?? 0;
  return currentExpectedCash - amount;
}

String? validateCashDropAmount(String? value, {required double? maxAvailable}) {
  if (maxAvailable == null) {
    return 'Available cash is unavailable';
  }
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

String? validateCashDropMovementType(
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

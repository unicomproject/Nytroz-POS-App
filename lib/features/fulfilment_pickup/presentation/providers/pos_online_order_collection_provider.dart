import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/pos_online_order_collection.dart';
import 'pos_online_orders_provider.dart';

enum PosCollectionPhase {
  initial,
  scannerReady,
  validating,
  invalidQr,
  invalidExpired,
  invalidWrongOutlet,
  invalidNotReady,
  invalidCancelled,
  invalidAlreadyCollected,
  invalidOther,
  validReady,
  paymentRequired,
  paymentSuccess,
  handoverReady,
  handoverSubmitting,
  collected,
  collectionComplete,
}

class PosOnlineOrderCollectionState {
  const PosOnlineOrderCollectionState({
    this.phase = PosCollectionPhase.scannerReady,
    this.validation,
    this.completeResult,
    this.failureReason,
    this.errorMessage,
    this.lastPaymentSaleId,
  });

  final PosCollectionPhase phase;
  final PosCollectionValidationResult? validation;
  final PosCollectionCompleteResult? completeResult;
  final PosCollectionFailureReason? failureReason;
  final String? errorMessage;
  final String? lastPaymentSaleId;

  bool get isValidating => phase == PosCollectionPhase.validating;
  bool get isSubmittingHandover =>
      phase == PosCollectionPhase.handoverSubmitting;

  PosOnlineOrderCollectionState copyWith({
    PosCollectionPhase? phase,
    PosCollectionValidationResult? validation,
    PosCollectionCompleteResult? completeResult,
    PosCollectionFailureReason? failureReason,
    String? errorMessage,
    String? lastPaymentSaleId,
    bool clearValidation = false,
    bool clearComplete = false,
    bool clearFailure = false,
    bool clearError = false,
    bool clearLastPaymentSaleId = false,
  }) {
    return PosOnlineOrderCollectionState(
      phase: phase ?? this.phase,
      validation: clearValidation ? null : (validation ?? this.validation),
      completeResult:
          clearComplete ? null : (completeResult ?? this.completeResult),
      failureReason:
          clearFailure ? null : (failureReason ?? this.failureReason),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      lastPaymentSaleId: clearLastPaymentSaleId
          ? null
          : (lastPaymentSaleId ?? this.lastPaymentSaleId),
    );
  }
}

class PosOnlineOrderCollectionController
    extends StateNotifier<PosOnlineOrderCollectionState> {
  PosOnlineOrderCollectionController(this._ref)
      : super(const PosOnlineOrderCollectionState());

  final Ref _ref;
  CancelToken? _validateToken;
  CancelToken? _completeToken;

  Future<void> validateToken(String rawToken) async {
    if (state.isValidating) return;

    final token = rawToken.trim();
    if (token.isEmpty) return;

    final outletId = _ref.read(posOnlineOrdersOutletIdProvider);
    if (outletId == null || outletId.isEmpty) {
      state = state.copyWith(
        phase: PosCollectionPhase.invalidOther,
        failureReason: PosCollectionFailureReason.unknown,
        errorMessage: 'Assigned outlet is unavailable.',
        clearValidation: true,
        clearComplete: true,
      );
      return;
    }

    _validateToken?.cancel('superseded');
    _validateToken = CancelToken();
    state = state.copyWith(
      phase: PosCollectionPhase.validating,
      clearFailure: true,
      clearError: true,
      clearComplete: true,
    );

    try {
      final result = await _ref
          .read(posOnlineOrdersRepositoryProvider)
          .validateCollectionQr(
            outletId: outletId,
            token: token,
            cancelToken: _validateToken,
          );

      if (!mounted) return;

      final phase = result.canTakePayment
          ? PosCollectionPhase.paymentRequired
          : result.canCollect
              ? PosCollectionPhase.validReady
              : PosCollectionPhase.invalidOther;

      state = state.copyWith(
        phase: phase,
        validation: result,
        clearFailure: true,
        clearError: true,
      );
    } on DioException catch (error) {
      if (CancelToken.isCancel(error) || !mounted) return;
      final code = _errorCode(error);
      final reason = PosCollectionFailureReason.fromErrorCode(code);
      state = state.copyWith(
        phase: _phaseForFailure(reason),
        failureReason: reason,
        errorMessage: onlineOrderErrorMessage(error),
        clearValidation: true,
      );
    } on Object catch (_) {
      if (!mounted) return;
      state = state.copyWith(
        phase: PosCollectionPhase.invalidOther,
        failureReason: PosCollectionFailureReason.unknown,
        errorMessage: 'Unable to validate this collection QR. Try again.',
        clearValidation: true,
      );
    }
  }

  void markPaymentSettled({String? saleId}) {
    final validation = state.validation;
    if (validation == null) return;
    state = state.copyWith(
      phase: PosCollectionPhase.paymentSuccess,
      validation: validation.withPaymentSettled(),
      lastPaymentSaleId: saleId,
      clearFailure: true,
      clearError: true,
    );
  }

  void prepareHandover() {
    if (state.validation == null) return;
    state = state.copyWith(
      phase: PosCollectionPhase.handoverReady,
      clearFailure: true,
      clearError: true,
    );
  }

  Future<bool> completeHandover() async {
    if (state.isSubmittingHandover) return false;
    final validation = state.validation;
    if (validation == null) return false;

    final outletId = _ref.read(posOnlineOrdersOutletIdProvider);
    if (outletId == null || outletId.isEmpty) {
      state = state.copyWith(
        errorMessage: 'Assigned outlet is unavailable.',
        failureReason: PosCollectionFailureReason.unknown,
      );
      return false;
    }

    _completeToken?.cancel('superseded');
    _completeToken = CancelToken();
    state = state.copyWith(
      phase: PosCollectionPhase.handoverSubmitting,
      clearFailure: true,
      clearError: true,
    );

    try {
      final result =
          await _ref.read(posOnlineOrdersRepositoryProvider).completeCollection(
                outletId: outletId,
                orderId: validation.orderId,
                expectedVersion: validation.expectedVersion,
                cancelToken: _completeToken,
              );
      if (!mounted) return false;
      state = state.copyWith(
        phase: PosCollectionPhase.collectionComplete,
        completeResult: result,
        clearFailure: true,
        clearError: true,
      );
      return true;
    } on DioException catch (error) {
      if (CancelToken.isCancel(error) || !mounted) return false;
      final code = _errorCode(error);
      final reason = PosCollectionFailureReason.fromErrorCode(code);
      state = state.copyWith(
        phase: PosCollectionPhase.handoverReady,
        failureReason: reason,
        errorMessage: onlineOrderErrorMessage(error),
      );
      return false;
    } on Object catch (_) {
      if (!mounted) return false;
      state = state.copyWith(
        phase: PosCollectionPhase.handoverReady,
        failureReason: PosCollectionFailureReason.unknown,
        errorMessage: 'Unable to complete collection. Try again.',
      );
      return false;
    }
  }

  void clear() {
    _validateToken?.cancel('cleared');
    _completeToken?.cancel('cleared');
    state = const PosOnlineOrderCollectionState();
  }

  void resetToScanner() {
    _validateToken?.cancel('rescan');
    _completeToken?.cancel('rescan');
    state = const PosOnlineOrderCollectionState(
      phase: PosCollectionPhase.scannerReady,
    );
  }

  /// Test-only seed for verification/handover widget harnesses.
  void seedValidationForTest(
    PosCollectionValidationResult result, {
    PosCollectionPhase phase = PosCollectionPhase.validReady,
    String? lastPaymentSaleId,
  }) {
    state = PosOnlineOrderCollectionState(
      phase: phase,
      validation: result,
      lastPaymentSaleId: lastPaymentSaleId,
    );
  }

  @override
  void dispose() {
    _validateToken?.cancel('disposed');
    _completeToken?.cancel('disposed');
    super.dispose();
  }

  static String? _errorCode(DioException error) {
    final data = error.response?.data;
    if (data is Map) {
      return (data['errorCode'] ?? data['code'])?.toString();
    }
    return null;
  }

  static PosCollectionPhase _phaseForFailure(
      PosCollectionFailureReason reason) {
    return switch (reason) {
      PosCollectionFailureReason.qrInvalid => PosCollectionPhase.invalidQr,
      PosCollectionFailureReason.qrExpired => PosCollectionPhase.invalidExpired,
      PosCollectionFailureReason.wrongOutlet =>
        PosCollectionPhase.invalidWrongOutlet,
      PosCollectionFailureReason.notReady => PosCollectionPhase.invalidNotReady,
      PosCollectionFailureReason.cancelled =>
        PosCollectionPhase.invalidCancelled,
      PosCollectionFailureReason.alreadyCollected =>
        PosCollectionPhase.invalidAlreadyCollected,
      _ => PosCollectionPhase.invalidOther,
    };
  }
}

final posOnlineOrderCollectionProvider = StateNotifierProvider<
    PosOnlineOrderCollectionController, PosOnlineOrderCollectionState>((ref) {
  return PosOnlineOrderCollectionController(ref);
});

/// Outstanding balance settlement context for Click & Collect collection.
class CollectionPaymentContext {
  const CollectionPaymentContext({
    required this.salesOrderId,
    required this.orderNumber,
    required this.amountDue,
    required this.currency,
    required this.expectedVersion,
    required this.outletId,
  });

  final String salesOrderId;
  final String orderNumber;
  final int amountDue;
  final String currency;
  final int expectedVersion;
  final String outletId;
}

final collectionPaymentContextProvider =
    StateProvider<CollectionPaymentContext?>((ref) => null);

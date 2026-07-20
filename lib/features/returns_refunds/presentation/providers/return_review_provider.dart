import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_error_message.dart';
import '../../../../core/network/dio_provider.dart';
import '../../../auth/domain/entities/auth_session.dart';
import '../../../auth/presentation/providers/session_provider.dart';
import '../../../device_activation/presentation/providers/device_activation_provider.dart';
import '../../domain/entities/refund_method_type.dart';
import '../../domain/entities/return_credit_preview.dart';
import '../../domain/entities/return_receipt.dart';
import '../../domain/entities/return_resolution_type.dart';
import '../../domain/entities/return_settlement_method.dart';
import 'return_exchange_flow_provider.dart';
import 'return_flow_provider.dart';
import 'return_resolution_provider.dart';
import 'return_search_provider.dart';

class ReturnReviewState {
  const ReturnReviewState({
    this.preview,
    this.reviewDraftVersion,
    this.reviewDraftId,
    this.reviewResolution,
    this.isLoadingPreview = false,
    this.isCompleting = false,
    this.previewErrorMessage,
    this.completionErrorMessage,
    this.completionIdempotencyKey,
  });

  final ReturnCreditPreview? preview;
  final int? reviewDraftVersion;
  final String? reviewDraftId;
  final ReturnResolutionType? reviewResolution;
  final bool isLoadingPreview;
  final bool isCompleting;
  final String? previewErrorMessage;
  final String? completionErrorMessage;
  final String? completionIdempotencyKey;

  bool get hasAuthoritativePreview =>
      preview != null &&
      reviewDraftVersion != null &&
      reviewDraftVersion! > 0 &&
      previewErrorMessage == null &&
      !isLoadingPreview;

  ReturnReviewState copyWith({
    ReturnCreditPreview? preview,
    int? reviewDraftVersion,
    String? reviewDraftId,
    ReturnResolutionType? reviewResolution,
    bool? isLoadingPreview,
    bool? isCompleting,
    String? previewErrorMessage,
    String? completionErrorMessage,
    String? completionIdempotencyKey,
    bool clearPreview = false,
    bool clearPreviewError = false,
    bool clearCompletionError = false,
    bool clearReviewMeta = false,
    bool clearCompletionIdempotencyKey = false,
  }) {
    return ReturnReviewState(
      preview: clearPreview ? null : preview ?? this.preview,
      reviewDraftVersion: clearReviewMeta
          ? null
          : reviewDraftVersion ?? this.reviewDraftVersion,
      reviewDraftId:
          clearReviewMeta ? null : reviewDraftId ?? this.reviewDraftId,
      reviewResolution:
          clearReviewMeta ? null : reviewResolution ?? this.reviewResolution,
      isLoadingPreview: isLoadingPreview ?? this.isLoadingPreview,
      isCompleting: isCompleting ?? this.isCompleting,
      previewErrorMessage: clearPreviewError
          ? null
          : previewErrorMessage ?? this.previewErrorMessage,
      completionErrorMessage: clearCompletionError
          ? null
          : completionErrorMessage ?? this.completionErrorMessage,
      completionIdempotencyKey: clearCompletionIdempotencyKey
          ? null
          : completionIdempotencyKey ?? this.completionIdempotencyKey,
    );
  }
}

class ReturnReviewController extends StateNotifier<ReturnReviewState> {
  ReturnReviewController(this._ref) : super(const ReturnReviewState()) {
    _ref.onDispose(() {
      _disposed = true;
      _previewToken?.cancel('Review provider disposed.');
      _completionToken?.cancel('Review provider disposed.');
    });
  }

  final Ref _ref;
  CancelToken? _previewToken;
  CancelToken? _completionToken;
  var _previewSequence = 0;
  var _completionSequence = 0;
  var _disposed = false;

  /// Always loads resolution + a fresh backend preview for Step 9.
  Future<void> loadPreview() async {
    final sequence = ++_previewSequence;
    _previewToken?.cancel('Superseded review preview request.');
    final cancelToken = CancelToken();
    _previewToken = cancelToken;

    state = state.copyWith(
      isLoadingPreview: true,
      clearPreview: true,
      clearPreviewError: true,
      clearReviewMeta: true,
      clearCompletionError: true,
    );

    final flowState = _ref.read(returnFlowProvider);
    final sale = flowState.selectedSale;
    final reasonCode = flowState.selectedReasonCode;
    final lines = flowState.selectedReturnLines;

    if (sale == null || reasonCode == null || lines.isEmpty) {
      if (!_acceptPreview(sequence)) return;
      state = state.copyWith(
        isLoadingPreview: false,
        clearPreview: true,
        previewErrorMessage:
            'Complete earlier return steps before reviewing.',
      );
      return;
    }

    final session = _ref.read(authSessionProvider);
    final deviceContext = _ref.read(deviceActivationProvider).deviceContext;
    if (session == null || !session.isAuthenticated || deviceContext == null) {
      if (!_acceptPreview(sequence)) return;
      state = state.copyWith(
        isLoadingPreview: false,
        clearPreview: true,
        previewErrorMessage:
            'Device context is required to load the latest preview.',
      );
      return;
    }

    _ensureAuthorizationHeader(_ref.read(appDioProvider), session);

    try {
      final loaded = await _ref
          .read(returnResolutionProvider.notifier)
          .loadSavedResolution();
      if (!_acceptPreview(sequence) || cancelToken.isCancelled) return;

      final resolution = _ref.read(returnResolutionProvider).savedResolution;
      if (!loaded || resolution == null || !resolution.isValidated) {
        state = state.copyWith(
          isLoadingPreview: false,
          clearPreview: true,
          previewErrorMessage:
              'The return workflow changed. Reload resolution and try again.',
        );
        return;
      }

      final isExchange =
          flowState.selectedResolution == ReturnResolutionType.exchange ||
              resolution.resolutionType == ReturnResolutionType.exchange;

      if (isExchange) {
        final ok = await _ref
            .read(returnExchangeFlowProvider.notifier)
            .refreshPreview();
        if (!_acceptPreview(sequence) || cancelToken.isCancelled) return;

        final exchangeState = _ref.read(returnExchangeFlowProvider);
        final exchangePreview = exchangeState.preview;
        if (!ok || exchangePreview == null) {
          state = state.copyWith(
            isLoadingPreview: false,
            clearPreview: true,
            previewErrorMessage: exchangeState.errorMessage ??
                'Unable to load latest exchange summary',
          );
          return;
        }

        if (exchangePreview.draftVersion != null &&
            exchangePreview.draftVersion != resolution.version) {
          _invalidateStaleReview();
          state = state.copyWith(
            isLoadingPreview: false,
            clearPreview: true,
            previewErrorMessage:
                'The exchange preview is out of date. Reload and review again.',
          );
          return;
        }

        if (exchangePreview.requiresApproval || !exchangePreview.canProceed) {
          state = state.copyWith(
            isLoadingPreview: false,
            clearPreview: true,
            previewErrorMessage: exchangePreview.policyMessages.isNotEmpty
                ? exchangePreview.policyMessages.first
                : 'Exchange cannot proceed with the current selection.',
            reviewDraftVersion: resolution.version,
            reviewDraftId: resolution.draftId,
            reviewResolution: ReturnResolutionType.exchange,
          );
          return;
        }

        // Compose credit-shaped preview fields from backend exchange preview + items.
        final creditPreview = await _ref
            .read(returnsRefundRemoteDatasourceProvider)
            .getCreditPreview(
              deviceId: deviceContext.deviceId,
              saleId: sale.saleId,
              reasonCode: reasonCode,
              lines: lines
                  .map(
                    (line) => {
                      'saleLineId': line.saleLineId,
                      'returnQty': line.returnQty,
                    },
                  )
                  .toList(growable: false),
              cancelToken: cancelToken,
            );
        if (!_acceptPreview(sequence) || cancelToken.isCancelled) return;

        if (creditPreview.draftVersion != null &&
            creditPreview.draftVersion != resolution.version) {
          _invalidateStaleReview();
          state = state.copyWith(
            isLoadingPreview: false,
            clearPreview: true,
            previewErrorMessage:
                'The return preview is out of date. Reload and review again.',
          );
          return;
        }

        _ensureSettlementMethod(
          flowState,
          creditPreview,
          exchangeDifferenceDirection: exchangePreview.differenceDirection,
        );

        state = state.copyWith(
          isLoadingPreview: false,
          preview: creditPreview,
          reviewDraftVersion: resolution.version,
          reviewDraftId: resolution.draftId,
          reviewResolution: ReturnResolutionType.exchange,
          clearPreviewError: true,
        );
        return;
      }

      final preview = await _ref
          .read(returnsRefundRemoteDatasourceProvider)
          .getCreditPreview(
            deviceId: deviceContext.deviceId,
            saleId: sale.saleId,
            reasonCode: reasonCode,
            lines: lines
                .map(
                  (line) => {
                    'saleLineId': line.saleLineId,
                    'returnQty': line.returnQty,
                  },
                )
                .toList(growable: false),
            cancelToken: cancelToken,
          );
      if (!_acceptPreview(sequence) || cancelToken.isCancelled) return;

      if (preview.draftVersion != null &&
          preview.draftVersion != resolution.version) {
        _invalidateStaleReview();
        state = state.copyWith(
          isLoadingPreview: false,
          clearPreview: true,
          previewErrorMessage:
              'The refund preview is out of date. Reload and review again.',
        );
        return;
      }

      // Do not treat in-memory Step 8A cache as authoritative for Step 9.
      _ref.read(returnFlowProvider.notifier).setRefundPreview(preview);
      _ensureSettlementMethod(flowState, preview);

      state = state.copyWith(
        isLoadingPreview: false,
        preview: preview,
        reviewDraftVersion: resolution.version,
        reviewDraftId: resolution.draftId,
        reviewResolution: ReturnResolutionType.refund,
        clearPreviewError: true,
      );
    } on DioException catch (error) {
      if (!_acceptPreview(sequence) || CancelToken.isCancel(error)) return;
      state = state.copyWith(
        isLoadingPreview: false,
        clearPreview: true,
        previewErrorMessage: messageFromDioException(
          error,
          contextPrefix: 'Unable to load latest preview',
          fallback: 'Unable to load latest preview. Please try again.',
        ),
      );
    } catch (_) {
      if (!_acceptPreview(sequence)) return;
      state = state.copyWith(
        isLoadingPreview: false,
        clearPreview: true,
        previewErrorMessage: 'Unable to load latest preview. Please try again.',
      );
    }
  }

  bool canComplete(ReturnFlowState flowState) {
    if (state.isCompleting || state.isLoadingPreview) {
      return false;
    }
    if (!state.hasAuthoritativePreview) {
      return false;
    }
    if (flowState.completedReceipt != null) {
      return false;
    }
    if (flowState.selectedSale == null ||
        flowState.selectedReturnLines.isEmpty ||
        flowState.selectedReasonCode == null) {
      return false;
    }
    if (flowState.selectedResolution == null) {
      return false;
    }

    final resolution = _ref.read(returnResolutionProvider).savedResolution;
    if (resolution == null ||
        !resolution.isValidated ||
        resolution.requiresManagerApproval) {
      return false;
    }
    if (state.reviewDraftVersion == null ||
        state.reviewDraftVersion != resolution.version ||
        state.reviewDraftId != resolution.draftId) {
      return false;
    }

    if (flowState.selectedResolution == ReturnResolutionType.refund) {
      if (flowState.selectedRefundMethod == null) {
        return false;
      }
      if (state.preview == null ||
          !state.preview!.canProceed ||
          state.preview!.requiresApproval) {
        return false;
      }
    }

    if (flowState.selectedResolution == ReturnResolutionType.exchange) {
      final exchangePreview = _ref.read(returnExchangeFlowProvider).preview;
      if (exchangePreview == null ||
          !exchangePreview.canProceed ||
          exchangePreview.requiresApproval) {
        return false;
      }
      if (exchangePreview.draftVersion != null &&
          exchangePreview.draftVersion != resolution.version) {
        return false;
      }
      final settlement =
          flowState.selectedSettlementMethodCode?.trim().toUpperCase();
      if (settlement == null ||
          settlement.isEmpty ||
          settlement == 'STORE_CREDIT') {
        return false;
      }
      final required =
          settlementCodeForExchangeDirection(exchangePreview.differenceDirection);
      if (required != null && settlement != required) {
        return false;
      }
    }

    if (flowState.selectedSettlementMethodCode == null ||
        flowState.selectedSettlementMethodCode!.isEmpty ||
        flowState.selectedSettlementMethodCode!.toUpperCase() ==
            'STORE_CREDIT') {
      return false;
    }
    return true;
  }

  Future<ReturnReceipt?> completeReturn() async {
    final flowState = _ref.read(returnFlowProvider);
    if (!canComplete(flowState)) {
      state = state.copyWith(
        completionErrorMessage:
            'Required return details are incomplete. Review previous steps.',
      );
      return null;
    }

    if (flowState.completedReceipt != null) {
      return flowState.completedReceipt;
    }

    final session = _ref.read(authSessionProvider);
    final deviceContext = _ref.read(deviceActivationProvider).deviceContext;
    if (session == null || !session.isAuthenticated || deviceContext == null) {
      state = state.copyWith(
        completionErrorMessage:
            'Device context is required to complete the return.',
      );
      return null;
    }

    final sale = flowState.selectedSale!;
    final reasonCode = flowState.selectedReasonCode!;
    final settlementCode = flowState.selectedSettlementMethodCode!;
    final lines = flowState.selectedReturnLines;
    final resolution = _ref.read(returnResolutionProvider).savedResolution;
    if (resolution == null || resolution.version < 1) {
      state = state.copyWith(
        completionErrorMessage:
            'Reload the authoritative return details before completing.',
      );
      return null;
    }

    // Reuse one key for the logical attempt (timeouts/retries must not mint a new key).
    final idempotencyKey = state.completionIdempotencyKey ??
        '${sale.saleId}:${resolution.draftId}:${resolution.version}:$settlementCode:complete';

    _ensureAuthorizationHeader(_ref.read(appDioProvider), session);
    final sequence = ++_completionSequence;
    _completionToken?.cancel('Superseded completion request.');
    final cancelToken = CancelToken();
    _completionToken = cancelToken;
    state = state.copyWith(
      isCompleting: true,
      clearCompletionError: true,
      completionIdempotencyKey: idempotencyKey,
    );

    try {
      final receipt = await _ref
          .read(returnsRefundRemoteDatasourceProvider)
          .completeReturn(
            deviceId: deviceContext.deviceId,
            saleId: sale.saleId,
            reasonCode: reasonCode,
            settlementMethodCode: settlementCode,
            notes: flowState.returnNotes,
            lines: lines
                .map(
                  (line) => {
                    'saleLineId': line.saleLineId,
                    'returnQty': line.returnQty,
                  },
                )
                .toList(growable: false),
            expectedVersion: resolution.version,
            idempotencyKey: idempotencyKey,
            cancelToken: cancelToken,
          );

      if (_disposed || sequence != _completionSequence) return null;
      _ref.read(returnFlowProvider.notifier).setCompletedReceipt(receipt);
      state = state.copyWith(
        isCompleting: false,
        clearCompletionIdempotencyKey: true,
      );
      return receipt;
    } on DioException catch (error) {
      if (_disposed ||
          sequence != _completionSequence ||
          CancelToken.isCancel(error)) {
        return null;
      }
      final isTimeout = error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.sendTimeout ||
          error.type == DioExceptionType.receiveTimeout;
      state = state.copyWith(
        isCompleting: false,
        // Keep key on timeout so retry is the same logical request.
        clearCompletionIdempotencyKey: !isTimeout && error.response != null,
        completionErrorMessage: messageFromDioException(
          error,
          contextPrefix: 'Unable to complete return',
          fallback: 'Unable to complete the return. Please try again.',
        ),
      );
      return null;
    } catch (_) {
      if (_disposed || sequence != _completionSequence) return null;
      state = state.copyWith(
        isCompleting: false,
        completionErrorMessage:
            'Unable to complete the return. Please try again.',
      );
      return null;
    }
  }

  void _invalidateStaleReview() {
    _ref.read(returnFlowProvider.notifier).setRefundPreview(null);
    state = state.copyWith(
      clearPreview: true,
      clearReviewMeta: true,
      clearCompletionIdempotencyKey: true,
    );
  }

  bool _acceptPreview(int sequence) =>
      !_disposed && sequence == _previewSequence;

  void _ensureSettlementMethod(
    ReturnFlowState flowState,
    ReturnCreditPreview preview, {
    String? exchangeDifferenceDirection,
  }) {
    final mapped = mapRefundMethodToSettlementCode(
      refundMethod: flowState.selectedRefundMethod,
      resolution: flowState.selectedResolution,
      preview: preview,
      existingCode: flowState.selectedSettlementMethodCode,
      exchangeDifferenceDirection: exchangeDifferenceDirection,
    );
    if (mapped == null) {
      if (flowState.selectedResolution == ReturnResolutionType.exchange) {
        _ref.read(returnFlowProvider.notifier).clearSettlementMethod();
      }
      return;
    }
    if (flowState.selectedSettlementMethodCode != mapped) {
      _ref.read(returnFlowProvider.notifier).setSettlementMethod(mapped);
    }
  }
}

/// Maps Step 8 refund method / branch onto an existing settlement method code
/// required by the completion API.
String? mapRefundMethodToSettlementCode({
  required RefundMethodType? refundMethod,
  required ReturnResolutionType? resolution,
  required ReturnCreditPreview preview,
  String? existingCode,
  String? exchangeDifferenceDirection,
}) {
  if (resolution == ReturnResolutionType.exchange) {
    final required =
        settlementCodeForExchangeDirection(exchangeDifferenceDirection);
    if (required != null) {
      return required;
    }
    // Without backend direction, do not invent settlement from local totals.
    return null;
  }

  final existing = ReturnSettlementMethodOption.findByCode(existingCode);
  if (existing != null &&
      existing.code != 'STORE_CREDIT' &&
      existing.isAvailableFor(preview)) {
    return existing.code;
  }

  switch (refundMethod) {
    case RefundMethodType.originalPaymentMethod:
      const card = ReturnSettlementMethodOption.cardRefund;
      if (card.isAvailableFor(preview)) {
        return card.code;
      }
      return ReturnSettlementMethodOption.cashRefund.code;
    case RefundMethodType.cash:
      return ReturnSettlementMethodOption.cashRefund.code;
    case RefundMethodType.storeCredit:
      // STORE_CREDIT remains unsupported for completion.
      return ReturnSettlementMethodOption.cashRefund.code;
    case null:
      for (final option in ReturnSettlementMethodOption.options) {
        if (option.code == 'STORE_CREDIT') continue;
        if (option.isAvailableFor(preview)) {
          return option.code;
        }
      }
      return null;
  }
}

String settlementInformationMessage({
  required ReturnFlowState flowState,
  required ReturnCreditPreview? preview,
}) {
  if (flowState.selectedResolution == ReturnResolutionType.exchange) {
    return 'Confirm the exchange details before completing this transaction.';
  }

  final method = flowState.selectedRefundMethod;
  if (method == RefundMethodType.storeCredit &&
      preview != null &&
      preview.validityDays > 0) {
    return 'Store credit remains valid for ${preview.validityDays} days from issue.';
  }

  if (method == RefundMethodType.originalPaymentMethod) {
    return 'The refund will be settled using the original payment method on file.';
  }

  if (method == RefundMethodType.cash) {
    return 'Confirm cash refund details with the customer before completing.';
  }

  return 'Review all return details carefully before completing.';
}

void _ensureAuthorizationHeader(Dio dio, AuthSession session) {
  final currentValue = dio.options.headers['Authorization'];
  if (currentValue is String && currentValue.trim().isNotEmpty) {
    return;
  }

  dio.options.headers['Authorization'] = 'Bearer ${session.accessToken}';
}

final returnReviewProvider =
    StateNotifierProvider.autoDispose<ReturnReviewController, ReturnReviewState>(
  (ref) => ReturnReviewController(ref),
);

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/access/pos_permission_access.dart';
import '../../../../core/network/dio_error_message.dart';
import '../../../../core/network/dio_provider.dart';
import '../../../auth/domain/entities/auth_session.dart';
import '../../../auth/presentation/providers/session_provider.dart';
import '../../../device_activation/presentation/providers/device_activation_provider.dart';
import '../../domain/entities/exchange_replacement_selection.dart';
import '../../domain/entities/return_exchange.dart';
import 'return_flow_provider.dart';
import 'return_resolution_provider.dart';
import 'return_search_provider.dart';

class ReturnExchangeFlowState {
  const ReturnExchangeFlowState({
    this.preview,
    this.savedReplacement,
    this.replacementPersisted = false,
    this.isLoadingPreview = false,
    this.isSavingReplacement = false,
    this.isLoadingSavedReplacement = false,
    this.errorMessage,
    this.isForbidden = false,
    this.draftExpired = false,
  });

  final ReturnExchangePreview? preview;
  final ReturnExchangeReplacementResponse? savedReplacement;
  final bool replacementPersisted;
  final bool isLoadingPreview;
  final bool isSavingReplacement;
  final bool isLoadingSavedReplacement;
  final String? errorMessage;
  final bool isForbidden;
  final bool draftExpired;

  bool get isBusy =>
      isLoadingPreview || isSavingReplacement || isLoadingSavedReplacement;

  bool get canContinue {
    if (isBusy || draftExpired || preview == null || !preview!.canProceed) {
      return false;
    }
    if (!replacementPersisted || savedReplacement == null) {
      return false;
    }
    if (savedReplacement!.items.isEmpty) {
      return false;
    }
    return preview!.replacementItemValue > 0 && preview!.returnItemValue > 0;
  }

  ReturnExchangeFlowState copyWith({
    ReturnExchangePreview? preview,
    ReturnExchangeReplacementResponse? savedReplacement,
    bool? replacementPersisted,
    bool? isLoadingPreview,
    bool? isSavingReplacement,
    bool? isLoadingSavedReplacement,
    String? errorMessage,
    bool? isForbidden,
    bool? draftExpired,
    bool clearPreview = false,
    bool clearReplacement = false,
    bool clearError = false,
  }) {
    return ReturnExchangeFlowState(
      preview: clearPreview ? null : preview ?? this.preview,
      savedReplacement:
          clearReplacement ? null : savedReplacement ?? this.savedReplacement,
      replacementPersisted: clearReplacement
          ? false
          : replacementPersisted ?? this.replacementPersisted,
      isLoadingPreview: isLoadingPreview ?? this.isLoadingPreview,
      isSavingReplacement: isSavingReplacement ?? this.isSavingReplacement,
      isLoadingSavedReplacement:
          isLoadingSavedReplacement ?? this.isLoadingSavedReplacement,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      isForbidden: isForbidden ?? this.isForbidden,
      draftExpired: draftExpired ?? this.draftExpired,
    );
  }
}

class ReturnExchangeFlowController
    extends StateNotifier<ReturnExchangeFlowState> {
  ReturnExchangeFlowController(this._ref)
      : super(const ReturnExchangeFlowState()) {
    _ref.onDispose(() {
      _disposed = true;
      _requestToken?.cancel('Exchange provider disposed.');
    });
  }

  final Ref _ref;
  CancelToken? _requestToken;
  var _sequence = 0;
  var _disposed = false;

  Future<void> hydrate() async {
    final granted =
        _ref.read(authSessionProvider)?.permissionCodes.toSet() ?? const {};
    if (!PosPermissionAccess.canProcessExchange(granted)) {
      state = state.copyWith(
        isForbidden: true,
        errorMessage: 'You do not have permission to process exchanges.',
      );
      return;
    }

    await _loadSavedReplacement();
    await _loadPreview();
  }

  Future<bool> saveReplacement({
    required String returnedSaleLineId,
    required String replacementProductId,
    required String replacementVariantId,
    required double quantity,
  }) async {
    if (state.isSavingReplacement) return false;
    final granted =
        _ref.read(authSessionProvider)?.permissionCodes.toSet() ?? const {};
    if (!PosPermissionAccess.canProcessExchange(granted)) {
      state = state.copyWith(
        isForbidden: true,
        errorMessage: 'You do not have permission to process exchanges.',
      );
      return false;
    }

    final saleId =
        _ref.read(returnFlowProvider).selectedSale?.saleId.trim() ?? '';
    if (saleId.isEmpty) {
      state = state.copyWith(
        errorMessage:
            'Complete earlier return steps before selecting a replacement.',
      );
      return false;
    }

    final expectedVersion = _resolveExpectedVersion();
    if (expectedVersion == null) {
      state = state.copyWith(
        errorMessage:
            'The exchange draft version is unavailable. Reload the return workflow and try again.',
      );
      return false;
    }

    final session = _ref.read(authSessionProvider);
    final deviceContext = _ref.read(deviceActivationProvider).deviceContext;
    if (session == null || !session.isAuthenticated || deviceContext == null) {
      state = state.copyWith(
        errorMessage:
            'Device context is required to save the replacement item.',
      );
      return false;
    }

    _ensureAuthorizationHeader(_ref.read(appDioProvider), session);
    final sequence = ++_sequence;
    _requestToken?.cancel('Superseded exchange request.');
    final cancelToken = CancelToken();
    _requestToken = cancelToken;
    state = state.copyWith(
      isSavingReplacement: true,
      isLoadingPreview: false,
      isLoadingSavedReplacement: false,
      draftExpired: false,
      clearError: true,
      clearPreview: true,
    );

    try {
      final saved = await _ref
          .read(returnsRefundRemoteDatasourceProvider)
          .saveExchangeReplacement(
            deviceId: deviceContext.deviceId,
            saleId: saleId,
            expectedVersion: expectedVersion,
            items: [
              {
                'returnedSaleLineId': returnedSaleLineId,
                'replacementProductId': replacementProductId,
                'replacementVariantId': replacementVariantId,
                'quantity': quantity,
              },
            ],
            cancelToken: cancelToken,
          );

      if (!_accept(sequence)) return false;
      state = state.copyWith(
        isSavingReplacement: false,
        savedReplacement: saved,
        replacementPersisted: true,
      );
      _syncFlowReplacement(saved);
      _clearStaleSettlement();
      await _ref.read(returnResolutionProvider.notifier).loadSavedResolution();
      await _loadPreview();
      return true;
    } on DioException catch (error) {
      if (CancelToken.isCancel(error)) {
        if (_accept(sequence)) {
          state = state.copyWith(isSavingReplacement: false);
        }
        return false;
      }
      if (!_accept(sequence)) return false;
      if (error.response?.statusCode == 403) {
        state = state.copyWith(
          isSavingReplacement: false,
          isForbidden: true,
          replacementPersisted: false,
          errorMessage:
              'You do not have permission to save the replacement item.',
        );
        return false;
      }
      if (error.response?.statusCode == 409) {
        final code = _errorCode(error);
        if (code == 'pos_returns.inspection_draft_expired') {
          state = state.copyWith(
            isSavingReplacement: false,
            draftExpired: true,
            replacementPersisted: false,
            clearPreview: true,
            errorMessage:
                'The inspection draft has expired. Restart inspection for this sale.',
          );
          return false;
        }
        if (code == 'pos_returns.inspection_draft_conflict') {
          await _ref
              .read(returnResolutionProvider.notifier)
              .loadSavedResolution();
          await _loadSavedReplacement();
          state = state.copyWith(
            isSavingReplacement: false,
            errorMessage:
                'The replacement draft changed. Reloaded the latest selection.',
          );
          return false;
        }
      }
      state = state.copyWith(
        isSavingReplacement: false,
        replacementPersisted: false,
        errorMessage: messageFromDioException(
          error,
          contextPrefix: 'Unable to save replacement item',
          fallback: 'Unable to save replacement item. Please try again.',
        ),
      );
      return false;
    } catch (_) {
      if (!_accept(sequence)) return false;
      state = state.copyWith(
        isSavingReplacement: false,
        replacementPersisted: false,
        errorMessage: 'Unable to save replacement item. Please try again.',
      );
      return false;
    }
  }

  Future<bool> updateReplacementQuantity(double quantity) async {
    final saved = state.savedReplacement;
    if (saved == null || saved.items.isEmpty) {
      return false;
    }
    final item = saved.items.first;
    final maxQty = item.availableQuantity;
    if (quantity < 1) {
      return false;
    }
    if (maxQty != null && quantity > maxQty) {
      state = state.copyWith(
        errorMessage:
            'Quantity cannot exceed available outlet stock (${maxQty.toStringAsFixed(0)}).',
      );
      return false;
    }

    return saveReplacement(
      returnedSaleLineId: item.returnedSaleLineId,
      replacementProductId: item.replacementProductId,
      replacementVariantId: item.replacementVariantId,
      quantity: quantity,
    );
  }

  Future<bool> refreshPreview() => _loadPreview();

  Future<void> _loadSavedReplacement() async {
    final saleId =
        _ref.read(returnFlowProvider).selectedSale?.saleId.trim() ?? '';
    if (saleId.isEmpty) {
      return;
    }

    final session = _ref.read(authSessionProvider);
    final deviceContext = _ref.read(deviceActivationProvider).deviceContext;
    if (session == null || !session.isAuthenticated || deviceContext == null) {
      return;
    }

    _ensureAuthorizationHeader(_ref.read(appDioProvider), session);
    final sequence = ++_sequence;
    _requestToken?.cancel('Superseded exchange hydration.');
    final cancelToken = CancelToken();
    _requestToken = cancelToken;
    state = state.copyWith(
      isLoadingSavedReplacement: true,
      isLoadingPreview: false,
      isSavingReplacement: false,
      clearError: true,
    );

    try {
      final saved = await _ref
          .read(returnsRefundRemoteDatasourceProvider)
          .getExchangeReplacement(
            deviceId: deviceContext.deviceId,
            saleId: saleId,
            cancelToken: cancelToken,
          );
      if (!_accept(sequence)) return;
      state = state.copyWith(
        isLoadingSavedReplacement: false,
        savedReplacement: saved,
        replacementPersisted: saved.items.isNotEmpty,
        draftExpired: false,
      );
      _syncFlowReplacement(saved);
    } on DioException catch (error) {
      if (CancelToken.isCancel(error)) {
        if (_accept(sequence)) {
          state = state.copyWith(isLoadingSavedReplacement: false);
        }
        return;
      }
      if (!_accept(sequence)) return;
      if (error.response?.statusCode == 404) {
        state = state.copyWith(
          isLoadingSavedReplacement: false,
          clearReplacement: true,
        );
        return;
      }
      if (error.response?.statusCode == 409 &&
          _errorCode(error) == 'pos_returns.inspection_draft_expired') {
        state = state.copyWith(
          isLoadingSavedReplacement: false,
          draftExpired: true,
          clearReplacement: true,
          clearPreview: true,
          errorMessage:
              'The inspection draft has expired. Restart inspection for this sale.',
        );
        return;
      }
      if (error.response?.statusCode == 403) {
        state = state.copyWith(
          isLoadingSavedReplacement: false,
          isForbidden: true,
        );
        return;
      }
      state = state.copyWith(isLoadingSavedReplacement: false);
    } catch (_) {
      if (!_accept(sequence)) return;
      state = state.copyWith(isLoadingSavedReplacement: false);
    }
  }

  Future<bool> _loadPreview() async {
    final flowState = _ref.read(returnFlowProvider);
    final sale = flowState.selectedSale;
    final reasonCode = flowState.selectedReasonCode;
    final lines = flowState.selectedReturnLines;

    if (sale == null || reasonCode == null || lines.isEmpty) {
      state = state.copyWith(clearPreview: true);
      return false;
    }

    if (!state.replacementPersisted) {
      state = state.copyWith(clearPreview: true);
      return false;
    }

    final session = _ref.read(authSessionProvider);
    final deviceContext = _ref.read(deviceActivationProvider).deviceContext;
    if (session == null || !session.isAuthenticated || deviceContext == null) {
      return false;
    }

    _ensureAuthorizationHeader(_ref.read(appDioProvider), session);
    final sequence = ++_sequence;
    _requestToken?.cancel('Superseded exchange preview.');
    final cancelToken = CancelToken();
    _requestToken = cancelToken;
    state = state.copyWith(
      isLoadingPreview: true,
      isLoadingSavedReplacement: false,
      isSavingReplacement: false,
      clearError: true,
    );

    try {
      final preview = await _ref
          .read(returnsRefundRemoteDatasourceProvider)
          .getExchangePreview(
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

      if (!_accept(sequence)) return false;
      state = state.copyWith(isLoadingPreview: false, preview: preview);
      _alignSettlementToDirection(preview.differenceDirection);
      return true;
    } on DioException catch (error) {
      if (CancelToken.isCancel(error)) {
        if (_accept(sequence)) {
          state = state.copyWith(isLoadingPreview: false);
        }
        return false;
      }
      if (!_accept(sequence)) return false;
      if (error.response?.statusCode == 403) {
        state = state.copyWith(
          isLoadingPreview: false,
          clearPreview: true,
          isForbidden: true,
          errorMessage: 'You do not have permission to preview this exchange.',
        );
        return false;
      }
      if (error.response?.statusCode == 409 &&
          _errorCode(error) == 'pos_returns.inspection_draft_expired') {
        state = state.copyWith(
          isLoadingPreview: false,
          draftExpired: true,
          clearPreview: true,
          errorMessage:
              'The inspection draft has expired. Restart inspection for this sale.',
        );
        return false;
      }
      state = state.copyWith(
        isLoadingPreview: false,
        clearPreview: true,
        errorMessage: messageFromDioException(
          error,
          contextPrefix: 'Unable to load exchange preview',
          fallback: 'Unable to load exchange preview. Please try again.',
        ),
      );
      return false;
    } catch (_) {
      if (!_accept(sequence)) return false;
      state = state.copyWith(
        isLoadingPreview: false,
        clearPreview: true,
        errorMessage: 'Unable to load exchange preview. Please try again.',
      );
      return false;
    }
  }

  int? _resolveExpectedVersion() {
    final fromReplacement = state.savedReplacement?.version;
    if (fromReplacement != null && fromReplacement >= 1) {
      return fromReplacement;
    }
    final fromResolution =
        _ref.read(returnResolutionProvider).savedResolution?.version;
    if (fromResolution != null && fromResolution >= 1) {
      return fromResolution;
    }
    return null;
  }

  void _clearStaleSettlement() {
    _ref.read(returnFlowProvider.notifier).clearSettlementMethod();
  }

  void _alignSettlementToDirection(String differenceDirection) {
    final mapped = settlementCodeForExchangeDirection(differenceDirection);
    final current = _ref
        .read(returnFlowProvider)
        .selectedSettlementMethodCode
        ?.trim()
        .toUpperCase();
    if (mapped == null) {
      return;
    }
    if (current != mapped) {
      _ref.read(returnFlowProvider.notifier).setSettlementMethod(mapped);
    }
  }

  bool _accept(int sequence) => !_disposed && sequence == _sequence;

  String? _errorCode(DioException error) {
    final data = error.response?.data;
    if (data is Map) {
      final errorObj = data['error'];
      if (errorObj is Map && errorObj['code'] != null) {
        return errorObj['code'].toString();
      }
      if (data['code'] != null) {
        return data['code'].toString();
      }
    }
    return null;
  }

  void _syncFlowReplacement(ReturnExchangeReplacementResponse saved) {
    final item = saved.items.isNotEmpty ? saved.items.first : null;
    if (item == null) {
      return;
    }

    _ref.read(returnFlowProvider.notifier).setSelectedReplacement(
          ExchangeReplacementSelection(
            productId: item.replacementProductId,
            productVariantId: item.replacementVariantId,
            productName: item.productName,
            imageUrl: item.imageStorageKey,
            variantDisplayName: item.variantDisplayName ?? '',
            sku: item.sku,
            quantity: item.quantity.round().clamp(1, 999999),
            unitPrice: item.unitPrice,
            currencyCode: item.currencyCode,
            stockStatus: item.stockStatus,
            availableQty: item.availableQuantity,
          ),
        );
  }
}

void _ensureAuthorizationHeader(Dio dio, AuthSession session) {
  final currentValue = dio.options.headers['Authorization'];
  if (currentValue is String && currentValue.trim().isNotEmpty) {
    return;
  }

  dio.options.headers['Authorization'] = 'Bearer ${session.accessToken}';
}

String? settlementCodeForExchangeDirection(String? differenceDirection) {
  switch (differenceDirection?.trim().toUpperCase()) {
    case 'CUSTOMER_PAYS':
      return 'CASH_PAYMENT';
    case 'CUSTOMER_RECEIVES':
      return 'CASH_REFUND';
    case 'EVEN_EXCHANGE':
    case 'EVEN':
      return 'NO_SETTLEMENT';
    default:
      return null;
  }
}

final returnExchangeFlowProvider = StateNotifierProvider.autoDispose<
    ReturnExchangeFlowController, ReturnExchangeFlowState>(
  (ref) => ReturnExchangeFlowController(ref),
);

String exchangeDifferenceLabel(String direction) {
  switch (direction.trim().toUpperCase()) {
    case 'CUSTOMER_PAYS':
      return 'Customer Pays';
    case 'CUSTOMER_RECEIVES':
      return 'Customer Receives';
    case 'EVEN_EXCHANGE':
      return 'Even Exchange';
    default:
      return 'Exchange Difference';
  }
}

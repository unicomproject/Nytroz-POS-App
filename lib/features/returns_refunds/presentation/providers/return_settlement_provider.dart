import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_provider.dart';
import '../../../auth/domain/entities/auth_session.dart';
import '../../../auth/presentation/providers/session_provider.dart';
import '../../../device_activation/presentation/providers/device_activation_provider.dart';
import '../../domain/entities/return_credit_preview.dart';
import '../../domain/entities/return_settlement_method.dart';
import 'return_flow_provider.dart';
import 'return_search_provider.dart';

class ReturnSettlementState {
  const ReturnSettlementState({
    this.preview,
    this.selectedMethodCode,
    this.showValidationMessage = false,
    this.isLoading = false,
    this.errorMessage,
  });

  final ReturnCreditPreview? preview;
  final String? selectedMethodCode;
  final bool showValidationMessage;
  final bool isLoading;
  final String? errorMessage;

  ReturnSettlementMethodOption? get selectedMethod =>
      ReturnSettlementMethodOption.findByCode(selectedMethodCode);

  ReturnSettlementPreviewValues? get settlementPreview {
    final creditPreview = preview;
    final method = selectedMethod;
    if (creditPreview == null || method == null) {
      return null;
    }

    return method.previewFor(creditPreview);
  }

  bool get canConfirmSettlement =>
      preview != null &&
      selectedMethod != null &&
      selectedMethod!.isAvailableFor(preview!);

  ReturnSettlementState copyWith({
    ReturnCreditPreview? preview,
    String? selectedMethodCode,
    bool? showValidationMessage,
    bool? isLoading,
    String? errorMessage,
    bool clearPreview = false,
    bool clearError = false,
    bool clearSelectedMethod = false,
  }) {
    return ReturnSettlementState(
      preview: clearPreview ? null : preview ?? this.preview,
      selectedMethodCode: clearSelectedMethod
          ? null
          : selectedMethodCode ?? this.selectedMethodCode,
      showValidationMessage:
          showValidationMessage ?? this.showValidationMessage,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}

class ReturnSettlementController extends StateNotifier<ReturnSettlementState> {
  ReturnSettlementController(this._ref) : super(const ReturnSettlementState());

  final Ref _ref;

  Future<void> load() async {
    final flowState = _ref.read(returnFlowProvider);
    final sale = flowState.selectedSale;
    final reasonCode = flowState.selectedReasonCode;
    final lines = flowState.selectedReturnLines;

    if (sale == null ||
        reasonCode == null ||
        lines.isEmpty ||
        !flowState.creditPreviewConfirmed) {
      state = state.copyWith(
        isLoading: false,
        clearPreview: true,
        errorMessage:
            'Complete earlier return steps and confirm credit before settlement.',
      );
      return;
    }

    final session = _ref.read(authSessionProvider);
    final deviceContext = _ref.read(deviceActivationProvider).deviceContext;

    if (session == null || !session.isAuthenticated || deviceContext == null) {
      state = state.copyWith(
        isLoading: false,
        clearPreview: true,
        errorMessage: 'Device context is required to load settlement preview.',
      );
      return;
    }

    _ensureAuthorizationHeader(_ref.read(appDioProvider), session);
    state = state.copyWith(isLoading: true, clearError: true, clearPreview: true);

    try {
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
          );

      final hydratedMethod = _resolveInitialMethod(
        flowState.selectedSettlementMethodCode,
        preview,
      );

      state = state.copyWith(
        isLoading: false,
        preview: preview,
        selectedMethodCode: hydratedMethod,
      );
    } on DioException catch (error) {
      state = state.copyWith(
        isLoading: false,
        clearPreview: true,
        errorMessage: _readApiError(error) ??
            'Unable to load settlement preview. Please try again.',
      );
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        clearPreview: true,
        errorMessage: 'Unable to load settlement preview. Please try again.',
      );
    }
  }

  void selectMethod(String code) {
    final preview = state.preview;
    final method = ReturnSettlementMethodOption.findByCode(code);
    if (preview == null || method == null || !method.isAvailableFor(preview)) {
      return;
    }

    state = state.copyWith(
      selectedMethodCode: code,
      showValidationMessage: false,
    );
    _ref.read(returnFlowProvider.notifier).setSettlementMethod(code);
  }

  bool validateSelection() {
    if (state.canConfirmSettlement) {
      state = state.copyWith(showValidationMessage: false);
      return true;
    }

    state = state.copyWith(showValidationMessage: true);
    return false;
  }

  String? _resolveInitialMethod(
    String? savedMethodCode,
    ReturnCreditPreview preview,
  ) {
    final saved = ReturnSettlementMethodOption.findByCode(savedMethodCode);
    if (saved != null && saved.isAvailableFor(preview)) {
      return saved.code;
    }

    for (final option in ReturnSettlementMethodOption.options) {
      if (option.isAvailableFor(preview)) {
        return option.code;
      }
    }

    return null;
  }
}

void _ensureAuthorizationHeader(Dio dio, AuthSession session) {
  final currentValue = dio.options.headers['Authorization'];
  if (currentValue is String && currentValue.trim().isNotEmpty) {
    return;
  }

  dio.options.headers['Authorization'] = 'Bearer ${session.accessToken}';
}

String? _readApiError(DioException error) {
  final data = error.response?.data;
  if (data is Map<String, dynamic>) {
    final message = data['message'];
    if (message is String && message.trim().isNotEmpty) {
      return message.trim();
    }
  }
  return null;
}

final returnSettlementProvider = StateNotifierProvider.autoDispose<
    ReturnSettlementController, ReturnSettlementState>(
  (ref) => ReturnSettlementController(ref),
);

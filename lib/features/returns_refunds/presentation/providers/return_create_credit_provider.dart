import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_error_message.dart';
import '../../../../core/network/dio_provider.dart';
import '../../../auth/domain/entities/auth_session.dart';
import '../../../auth/presentation/providers/session_provider.dart';
import '../../../device_activation/presentation/providers/device_activation_provider.dart';
import '../../domain/entities/return_credit_preview.dart';
import 'return_flow_provider.dart';
import 'return_search_provider.dart';

class ReturnCreateCreditState {
  const ReturnCreateCreditState({
    this.preview,
    this.isConfirmed = false,
    this.showValidationMessage = false,
    this.isLoading = false,
    this.isSubmitting = false,
    this.errorMessage,
  });

  final ReturnCreditPreview? preview;
  final bool isConfirmed;
  final bool showValidationMessage;
  final bool isLoading;
  final bool isSubmitting;
  final String? errorMessage;

  bool get canCreateCredit =>
      preview != null && preview!.calculation.netCreditAmount > 0;

  ReturnCreateCreditState copyWith({
    ReturnCreditPreview? preview,
    bool? isConfirmed,
    bool? showValidationMessage,
    bool? isLoading,
    bool? isSubmitting,
    String? errorMessage,
    bool clearPreview = false,
    bool clearError = false,
  }) {
    return ReturnCreateCreditState(
      preview: clearPreview ? null : preview ?? this.preview,
      isConfirmed: isConfirmed ?? this.isConfirmed,
      showValidationMessage:
          showValidationMessage ?? this.showValidationMessage,
      isLoading: isLoading ?? this.isLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}

class ReturnCreateCreditController
    extends StateNotifier<ReturnCreateCreditState> {
  ReturnCreateCreditController(this._ref)
      : super(const ReturnCreateCreditState());

  final Ref _ref;

  Future<void> load() async {
    final flowState = _ref.read(returnFlowProvider);
    final sale = flowState.selectedSale;
    final reasonCode = flowState.selectedReasonCode;
    final lines = flowState.selectedReturnLines;

    if (sale == null || reasonCode == null || lines.isEmpty) {
      state = state.copyWith(
        isLoading: false,
        clearPreview: true,
        errorMessage: 'Complete earlier return steps before creating credit.',
      );
      return;
    }

    final session = _ref.read(authSessionProvider);
    final deviceContext = _ref.read(deviceActivationProvider).deviceContext;

    if (session == null || !session.isAuthenticated || deviceContext == null) {
      state = state.copyWith(
        isLoading: false,
        clearPreview: true,
        errorMessage: 'Device context is required to load credit preview.',
      );
      return;
    }

    _ensureAuthorizationHeader(_ref.read(appDioProvider), session);
    state =
        state.copyWith(isLoading: true, clearError: true, clearPreview: true);

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

      state = state.copyWith(
        isLoading: false,
        preview: preview,
      );
    } on DioException catch (error) {
      state = state.copyWith(
        isLoading: false,
        clearPreview: true,
        errorMessage: messageFromDioException(
          error,
          contextPrefix: 'Unable to load credit preview',
          fallback: 'Unable to load credit preview. Please try again.',
        ),
      );
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        clearPreview: true,
        errorMessage: error is StateError
            ? error.message
            : 'Unable to load credit preview. Please try again.',
      );
    }
  }

  void hydrateConfirmation({required bool isConfirmed}) {
    state = state.copyWith(
      isConfirmed: isConfirmed,
      showValidationMessage: false,
    );
  }

  void setConfirmed(bool value) {
    state = state.copyWith(
      isConfirmed: value,
      showValidationMessage: false,
    );
  }

  bool validateConfirmation() {
    if (state.isConfirmed) {
      state = state.copyWith(showValidationMessage: false);
      return true;
    }

    state = state.copyWith(showValidationMessage: true);
    return false;
  }
}

void _ensureAuthorizationHeader(Dio dio, AuthSession session) {
  final currentValue = dio.options.headers['Authorization'];
  if (currentValue is String && currentValue.trim().isNotEmpty) {
    return;
  }

  dio.options.headers['Authorization'] = 'Bearer ${session.accessToken}';
}

final returnCreateCreditProvider = StateNotifierProvider.autoDispose<
    ReturnCreateCreditController, ReturnCreateCreditState>(
  (ref) => ReturnCreateCreditController(ref),
);

String formatReturnCreditAmount({
  required String currency,
  required double amount,
}) {
  final prefix = currency.trim().isEmpty ? 'LKR' : currency.trim();
  return '$prefix ${amount.toStringAsFixed(2)}';
}

String formatReturnCreditAdjustment({
  required String currency,
  required double amount,
}) {
  final formatted =
      formatReturnCreditAmount(currency: currency, amount: amount);
  if (amount == 0) {
    return formatted;
  }
  return '-$formatted';
}

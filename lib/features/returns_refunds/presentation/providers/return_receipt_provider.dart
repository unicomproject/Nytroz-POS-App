import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../hardware/receipt_printer/presentation/providers/cash_drawer_controller.dart';

import '../../../../core/network/dio_provider.dart';
import '../../../auth/domain/entities/auth_session.dart';
import '../../../auth/presentation/providers/session_provider.dart';
import '../../../device_activation/presentation/providers/device_activation_provider.dart';
import '../../domain/entities/return_receipt.dart';
import 'return_flow_provider.dart';
import 'return_resolution_provider.dart';
import 'return_search_provider.dart';

class ReturnReceiptState {
  const ReturnReceiptState({
    this.receipt,
    this.isLoading = false,
    this.errorMessage,
  });

  final ReturnReceipt? receipt;
  final bool isLoading;
  final String? errorMessage;

  ReturnReceiptState copyWith({
    ReturnReceipt? receipt,
    bool? isLoading,
    String? errorMessage,
    bool clearReceipt = false,
    bool clearError = false,
  }) {
    return ReturnReceiptState(
      receipt: clearReceipt ? null : receipt ?? this.receipt,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}

class ReturnReceiptController extends StateNotifier<ReturnReceiptState> {
  ReturnReceiptController(this._ref) : super(const ReturnReceiptState());

  final Ref _ref;

  Future<void> completeReturnIfNeeded() async {
    final flowState = _ref.read(returnFlowProvider);
    final existingReceipt = flowState.completedReceipt;

    if (existingReceipt != null) {
      state = ReturnReceiptState(receipt: existingReceipt);
      return;
    }

    final sale = flowState.selectedSale;
    final reasonCode = flowState.selectedReasonCode;
    final settlementCode = flowState.selectedSettlementMethodCode;
    final lines = flowState.selectedReturnLines;
    final resolution = _ref.read(returnResolutionProvider).savedResolution;

    if (sale == null ||
        reasonCode == null ||
        settlementCode == null ||
        lines.isEmpty ||
        resolution == null ||
        resolution.version < 1 ||
        !flowState.creditPreviewConfirmed) {
      state = state.copyWith(
        isLoading: false,
        clearReceipt: true,
        errorMessage:
            'Complete earlier return steps before viewing the receipt.',
      );
      return;
    }

    final session = _ref.read(authSessionProvider);
    final deviceContext = _ref.read(deviceActivationProvider).deviceContext;

    if (session == null || !session.isAuthenticated || deviceContext == null) {
      state = state.copyWith(
        isLoading: false,
        clearReceipt: true,
        errorMessage: 'Device context is required to complete the return.',
      );
      return;
    }

    _ensureAuthorizationHeader(_ref.read(appDioProvider), session);
    state =
        state.copyWith(isLoading: true, clearError: true, clearReceipt: true);

    try {
      final receipt =
          await _ref.read(returnsRefundRemoteDatasourceProvider).completeReturn(
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
                idempotencyKey:
                    '${sale.saleId}:${resolution.draftId}:${resolution.version}:complete',
              );

      _ref.read(returnFlowProvider.notifier).setCompletedReceipt(receipt);

      if (receipt.drawerOperationId != null &&
          receipt.cashDrawerSettings != null) {
        unawaited(
          _ref
              .read(cashDrawerControllerProvider.notifier)
              .triggerAutoOpenForCheckout(
                drawerOperationId: receipt.drawerOperationId!,
                purposeStr: 'cashRefund',
                drawerSettingsJson: receipt.cashDrawerSettings!,
                businessReferenceId: receipt.returnId,
              ),
        );
      }

      state = state.copyWith(isLoading: false, receipt: receipt);
    } on DioException catch (error) {
      state = state.copyWith(
        isLoading: false,
        clearReceipt: true,
        errorMessage: _readApiError(error) ??
            'Unable to complete the return. Please try again.',
      );
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        clearReceipt: true,
        errorMessage: 'Unable to complete the return. Please try again.',
      );
    }
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

final returnReceiptProvider = StateNotifierProvider.autoDispose<
    ReturnReceiptController, ReturnReceiptState>(
  (ref) => ReturnReceiptController(ref),
);

String formatReturnReceiptAmount({
  required String currency,
  required double amount,
}) {
  final prefix = currency.trim().isEmpty ? 'LKR' : currency.trim();
  return '$prefix ${amount.toStringAsFixed(2)}';
}

String formatReturnReceiptDateTime(DateTime? value) {
  if (value == null) {
    return '-';
  }

  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  final hour = value.hour % 12 == 0 ? 12 : value.hour % 12;
  final minute = value.minute.toString().padLeft(2, '0');
  final period = value.hour >= 12 ? 'PM' : 'AM';

  return '${value.day} ${months[value.month - 1]} ${value.year}, '
      '$hour:$minute $period';
}

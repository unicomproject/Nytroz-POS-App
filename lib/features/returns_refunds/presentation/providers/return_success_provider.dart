import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/access/pos_permission_access.dart';
import '../../../../core/network/dio_provider.dart';
import '../../../auth/domain/entities/auth_session.dart';
import '../../../auth/presentation/providers/session_provider.dart';
import '../../../device_activation/presentation/providers/device_activation_provider.dart';
import '../../../hardware/receipt_printer/models/printer_exception.dart';
import '../../../hardware/receipt_printer/pos_receipt_printer_service.dart';
import '../../domain/entities/return_receipt.dart';
import 'return_flow_reset_coordinator.dart';
import 'return_search_provider.dart';
import 'return_success_display.dart';

enum ReturnSuccessLoadStatus {
  idle,
  loading,
  loaded,
  permissionDenied,
  notFound,
  notReady,
  exchangeIncomplete,
  failed,
}

class ReturnSuccessState {
  const ReturnSuccessState({
    this.loadStatus = ReturnSuccessLoadStatus.idle,
    this.loadMessage,
    this.printStatus = ReturnSuccessPrintStatus.idle,
    this.printMessage,
    this.isNavigating = false,
    this.receipt,
    this.auditPendingAfterPrint = false,
  });

  final ReturnSuccessLoadStatus loadStatus;
  final String? loadMessage;
  final ReturnSuccessPrintStatus printStatus;
  final String? printMessage;
  final bool isNavigating;
  final ReturnReceipt? receipt;
  final bool auditPendingAfterPrint;

  ReturnSuccessState copyWith({
    ReturnSuccessLoadStatus? loadStatus,
    String? loadMessage,
    ReturnSuccessPrintStatus? printStatus,
    String? printMessage,
    bool? isNavigating,
    ReturnReceipt? receipt,
    bool? auditPendingAfterPrint,
    bool clearLoadMessage = false,
    bool clearPrintMessage = false,
    bool clearReceipt = false,
  }) {
    return ReturnSuccessState(
      loadStatus: loadStatus ?? this.loadStatus,
      loadMessage:
          clearLoadMessage ? null : loadMessage ?? this.loadMessage,
      printStatus: printStatus ?? this.printStatus,
      printMessage:
          clearPrintMessage ? null : printMessage ?? this.printMessage,
      isNavigating: isNavigating ?? this.isNavigating,
      receipt: clearReceipt ? null : receipt ?? this.receipt,
      auditPendingAfterPrint:
          auditPendingAfterPrint ?? this.auditPendingAfterPrint,
    );
  }
}

class ReturnSuccessController extends StateNotifier<ReturnSuccessState> {
  ReturnSuccessController(this._ref) : super(const ReturnSuccessState());

  final Ref _ref;
  CancelToken? _loadCancelToken;
  int _loadSequence = 0;
  String? _activeReturnId;
  bool _disposed = false;

  Future<void> loadCompletion({String? returnId}) async {
    final session = _ref.read(authSessionProvider);
    final granted = session?.permissionCodes.toSet() ?? const <String>{};

    if (!PosPermissionAccess.canAccessReturnSuccessRoute(granted)) {
      state = state.copyWith(
        loadStatus: ReturnSuccessLoadStatus.permissionDenied,
        loadMessage: 'Permission Denied',
        clearReceipt: true,
      );
      return;
    }

    final resolvedReturnId = returnId?.trim() ?? '';
    if (resolvedReturnId.isEmpty) {
      state = state.copyWith(
        loadStatus: ReturnSuccessLoadStatus.notFound,
        loadMessage:
            'A confirmed return completion identifier is required.',
        clearReceipt: true,
      );
      return;
    }

    final deviceContext = _ref.read(deviceActivationProvider).deviceContext;
    if (session == null || !session.isAuthenticated || deviceContext == null) {
      state = state.copyWith(
        loadStatus: ReturnSuccessLoadStatus.failed,
        loadMessage: 'Device context is required to load the receipt.',
        clearReceipt: true,
      );
      return;
    }

    _loadCancelToken?.cancel('superseded');
    final cancelToken = CancelToken();
    _loadCancelToken = cancelToken;
    final sequence = ++_loadSequence;
    _activeReturnId = resolvedReturnId;

    _ensureAuthorizationHeader(_ref.read(appDioProvider), session);
    state = state.copyWith(
      loadStatus: ReturnSuccessLoadStatus.loading,
      clearLoadMessage: true,
      clearReceipt: true,
      printStatus: ReturnSuccessPrintStatus.idle,
      clearPrintMessage: true,
      auditPendingAfterPrint: false,
    );

    try {
      final receipt = await _ref
          .read(returnsRefundRemoteDatasourceProvider)
          .getCompletion(
            deviceId: deviceContext.deviceId,
            returnId: resolvedReturnId,
            cancelToken: cancelToken,
          );

      if (!_isCurrentLoad(sequence, resolvedReturnId)) {
        return;
      }

      if (!_canViewReceiptBranch(granted, receipt)) {
        state = state.copyWith(
          loadStatus: ReturnSuccessLoadStatus.permissionDenied,
          loadMessage: 'Permission Denied',
          clearReceipt: true,
        );
        return;
      }

      if (!isValidCompletedReceipt(receipt)) {
        state = state.copyWith(
          loadStatus: ReturnSuccessLoadStatus.notReady,
          loadMessage: 'The return completion is not ready to display.',
          clearReceipt: true,
        );
        return;
      }

      state = state.copyWith(
        loadStatus: ReturnSuccessLoadStatus.loaded,
        receipt: receipt,
        clearLoadMessage: true,
      );
    } on DioException catch (error) {
      if (cancelToken.isCancelled ||
          !_isCurrentLoad(sequence, resolvedReturnId)) {
        return;
      }
      state = _mapLoadError(error);
    } catch (_) {
      if (!_isCurrentLoad(sequence, resolvedReturnId)) {
        return;
      }
      state = state.copyWith(
        loadStatus: ReturnSuccessLoadStatus.failed,
        loadMessage: 'Unable to load the completed receipt.',
        clearReceipt: true,
      );
    }
  }

  Future<void> requestPrint({bool auditOnly = false}) async {
    if (state.printStatus == ReturnSuccessPrintStatus.inProgress ||
        state.isNavigating) {
      return;
    }

    final session = _ref.read(authSessionProvider);
    final granted = session?.permissionCodes.toSet() ?? const <String>{};
    if (!PosPermissionAccess.canPrintReceipts(granted)) {
      state = state.copyWith(
        printStatus: ReturnSuccessPrintStatus.failed,
        printMessage: 'Permission Denied',
      );
      return;
    }

    final receipt = state.receipt;
    if (!isValidCompletedReceipt(receipt) ||
        receipt == null ||
        !receipt.canPrint) {
      state = state.copyWith(
        printStatus: ReturnSuccessPrintStatus.failed,
        printMessage: 'Receipt data is unavailable for printing.',
      );
      return;
    }

    final saleId = receipt.originalSaleId?.trim() ?? '';
    if (saleId.isEmpty) {
      state = state.copyWith(
        printStatus: ReturnSuccessPrintStatus.failed,
        printMessage: 'Receipt data is unavailable for printing.',
      );
      return;
    }

    final deviceContext = _ref.read(deviceActivationProvider).deviceContext;
    if (session == null ||
        !session.isAuthenticated ||
        deviceContext == null) {
      state = state.copyWith(
        printStatus: ReturnSuccessPrintStatus.failed,
        printMessage: 'Device context is required for printing.',
      );
      return;
    }

    final skipPhysical = auditOnly || state.auditPendingAfterPrint;
    _ensureAuthorizationHeader(_ref.read(appDioProvider), session);
    state = state.copyWith(
      printStatus: ReturnSuccessPrintStatus.inProgress,
      clearPrintMessage: true,
    );

    var physicallyPrinted = skipPhysical;
    try {
      if (!skipPhysical) {
        final printer = _ref.read(posReceiptPrinterServiceProvider);
        await printer.printCompletionReceipt(
          deviceId: deviceContext.deviceId,
          receipt: receipt,
        );
        physicallyPrinted = true;
      }

      await _ref.read(returnsRefundRemoteDatasourceProvider).recordReceiptPrint(
            saleId: saleId,
          );

      state = state.copyWith(
        printStatus: ReturnSuccessPrintStatus.succeeded,
        printMessage: skipPhysical && auditOnly
            ? 'Print audit recorded.'
            : 'Receipt printed.',
        receipt: receipt.copyWith(
          printCount: skipPhysical ? receipt.printCount : receipt.printCount + 1,
          hasBeenPrinted: true,
        ),
        auditPendingAfterPrint: false,
      );
    } on PrinterException catch (error) {
      state = state.copyWith(
        printStatus: ReturnSuccessPrintStatus.failed,
        printMessage: error.message,
        auditPendingAfterPrint: false,
      );
    } on DioException catch (error) {
      if (physicallyPrinted) {
        state = state.copyWith(
          printStatus: ReturnSuccessPrintStatus.auditFailed,
          printMessage:
              'Receipt printed, but print audit could not be recorded.',
          auditPendingAfterPrint: true,
          receipt: receipt.copyWith(hasBeenPrinted: true),
        );
        return;
      }

      final status = error.response?.statusCode;
      if (status == 503) {
        state = state.copyWith(
          printStatus: ReturnSuccessPrintStatus.unavailable,
          printMessage:
              'Return receipt printing is not available yet on this device.',
        );
        return;
      }
      if (status == 403) {
        state = state.copyWith(
          printStatus: ReturnSuccessPrintStatus.failed,
          printMessage: 'Permission Denied',
        );
        return;
      }
      state = state.copyWith(
        printStatus: ReturnSuccessPrintStatus.failed,
        printMessage: _readApiError(error) ??
            'Unable to print the receipt. Please try again.',
      );
    } catch (_) {
      if (physicallyPrinted) {
        state = state.copyWith(
          printStatus: ReturnSuccessPrintStatus.auditFailed,
          printMessage:
              'Receipt printed, but print audit could not be recorded.',
          auditPendingAfterPrint: true,
          receipt: receipt.copyWith(hasBeenPrinted: true),
        );
        return;
      }
      state = state.copyWith(
        printStatus: ReturnSuccessPrintStatus.failed,
        printMessage: 'Unable to print the receipt. Please try again.',
      );
    }
  }

  Future<void> retryAuditOnly() => requestPrint(auditOnly: true);

  void resetReturnExchangeDraft() {
    _loadCancelToken?.cancel('reset');
    _loadCancelToken = null;
    _activeReturnId = null;
    _loadSequence++;
    resetReturnExchangeFlow(_ref);
    state = const ReturnSuccessState();
  }

  bool beginNavigation() {
    if (state.isNavigating) {
      return false;
    }
    state = state.copyWith(isNavigating: true);
    return true;
  }

  bool _isCurrentLoad(int sequence, String returnId) {
    return !_disposed &&
        sequence == _loadSequence &&
        _activeReturnId == returnId;
  }

  bool _canViewReceiptBranch(Set<String> granted, ReturnReceipt receipt) {
    if (receipt.isExchange) {
      return PosPermissionAccess.canViewExchangeSuccess(granted);
    }
    return PosPermissionAccess.canViewRefundSuccess(granted);
  }

  ReturnSuccessState _mapLoadError(DioException error) {
    final status = error.response?.statusCode;
    final code = _readApiCode(error);
    if (status == 401) {
      return state.copyWith(
        loadStatus: ReturnSuccessLoadStatus.failed,
        loadMessage: 'Session expired.',
        clearReceipt: true,
      );
    }
    if (status == 403) {
      return state.copyWith(
        loadStatus: ReturnSuccessLoadStatus.permissionDenied,
        loadMessage: 'Permission Denied',
        clearReceipt: true,
      );
    }
    if (status == 404 || code == 'pos_returns.completion_not_found') {
      return state.copyWith(
        loadStatus: ReturnSuccessLoadStatus.notFound,
        loadMessage: 'Completed return or receipt not found.',
        clearReceipt: true,
      );
    }
    if (status == 409 || code == 'pos_returns.completion_not_ready') {
      return state.copyWith(
        loadStatus: ReturnSuccessLoadStatus.notReady,
        loadMessage: 'The return completion is not ready to display.',
        clearReceipt: true,
      );
    }
    if (status == 422 || code == 'pos_returns.exchange_incomplete') {
      return state.copyWith(
        loadStatus: ReturnSuccessLoadStatus.exchangeIncomplete,
        loadMessage:
            'Exchange completion records are not available for this return.',
        clearReceipt: true,
      );
    }
    return state.copyWith(
      loadStatus: ReturnSuccessLoadStatus.failed,
      loadMessage: _readApiError(error) ??
          'Unable to load the completed receipt.',
      clearReceipt: true,
    );
  }

  @override
  void dispose() {
    _disposed = true;
    _loadCancelToken?.cancel('disposed');
    super.dispose();
  }
}

void _ensureAuthorizationHeader(Dio dio, AuthSession session) {
  final token = session.accessToken.trim();
  if (token.isEmpty) {
    return;
  }
  dio.options.headers['Authorization'] = 'Bearer $token';
}

String? _readApiError(DioException error) {
  final data = error.response?.data;
  if (data is Map) {
    final message = data['message'];
    if (message != null && message.toString().trim().isNotEmpty) {
      return message.toString().trim();
    }
  }
  return null;
}

String? _readApiCode(DioException error) {
  final data = error.response?.data;
  if (data is Map) {
    final code = data['code'];
    if (code != null && code.toString().trim().isNotEmpty) {
      return code.toString().trim();
    }
  }
  return null;
}

final returnSuccessProvider =
    StateNotifierProvider.autoDispose<ReturnSuccessController, ReturnSuccessState>(
  (ref) => ReturnSuccessController(ref),
);

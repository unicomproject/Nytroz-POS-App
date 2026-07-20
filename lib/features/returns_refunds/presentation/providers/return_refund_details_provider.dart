import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/access/pos_permission_access.dart';
import '../../../../core/network/dio_error_message.dart';
import '../../../../core/network/dio_provider.dart';
import '../../../auth/domain/entities/auth_session.dart';
import '../../../auth/presentation/providers/session_provider.dart';
import '../../../device_activation/presentation/providers/device_activation_provider.dart';
import '../../domain/entities/refund_method_type.dart';
import '../../domain/entities/return_credit_preview.dart';
import '../../domain/entities/return_refund_method.dart';
import 'return_flow_provider.dart';
import 'return_resolution_provider.dart';
import 'return_search_provider.dart';

class ReturnRefundDetailsState {
  const ReturnRefundDetailsState({
    this.preview,
    this.methods = const [],
    this.defaultMethodCode,
    this.selectedMethodCode,
    this.methodPersisted = false,
    this.isLoadingPreview = false,
    this.isLoadingMethods = false,
    this.isSavingMethod = false,
    this.errorMessage,
    this.isForbidden = false,
  });

  final ReturnCreditPreview? preview;
  final List<ReturnRefundMethodOption> methods;
  final String? defaultMethodCode;
  final String? selectedMethodCode;
  final bool methodPersisted;
  final bool isLoadingPreview;
  final bool isLoadingMethods;
  final bool isSavingMethod;
  final String? errorMessage;
  final bool isForbidden;

  bool get isLoading => isLoadingPreview || isLoadingMethods;

  ReturnRefundMethodOption? get selectedMethod {
    final code = selectedMethodCode?.trim() ?? '';
    if (code.isEmpty) {
      return null;
    }
    for (final method in methods) {
      if (method.code.trim().toUpperCase() == code.toUpperCase()) {
        return method;
      }
    }
    return null;
  }

  bool get canConfirm {
    final currentPreview = preview;
    if (currentPreview == null || !currentPreview.canProceed) {
      return false;
    }
    final method = selectedMethod;
    if (method == null || !method.enabled) {
      return false;
    }
    if (!methodPersisted) {
      return false;
    }
    if (isLoading || isSavingMethod) {
      return false;
    }
    return currentPreview.calculation.netCreditAmount > 0;
  }

  ReturnRefundDetailsState copyWith({
    ReturnCreditPreview? preview,
    List<ReturnRefundMethodOption>? methods,
    String? defaultMethodCode,
    String? selectedMethodCode,
    bool? methodPersisted,
    bool? isLoadingPreview,
    bool? isLoadingMethods,
    bool? isSavingMethod,
    String? errorMessage,
    bool? isForbidden,
    bool clearPreview = false,
    bool clearMethods = false,
    bool clearSelection = false,
    bool clearError = false,
  }) {
    return ReturnRefundDetailsState(
      preview: clearPreview ? null : preview ?? this.preview,
      methods: clearMethods ? const [] : methods ?? this.methods,
      defaultMethodCode:
          clearMethods ? null : defaultMethodCode ?? this.defaultMethodCode,
      selectedMethodCode: clearSelection
          ? null
          : selectedMethodCode ?? this.selectedMethodCode,
      methodPersisted: clearSelection ? false : methodPersisted ?? this.methodPersisted,
      isLoadingPreview: isLoadingPreview ?? this.isLoadingPreview,
      isLoadingMethods: isLoadingMethods ?? this.isLoadingMethods,
      isSavingMethod: isSavingMethod ?? this.isSavingMethod,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      isForbidden: isForbidden ?? this.isForbidden,
    );
  }
}

class ReturnRefundDetailsController
    extends StateNotifier<ReturnRefundDetailsState> {
  ReturnRefundDetailsController(this._ref)
      : super(const ReturnRefundDetailsState()) {
    _ref.onDispose(() {
      _disposed = true;
      _previewToken?.cancel('Refund provider disposed.');
      _methodsToken?.cancel('Refund provider disposed.');
      _saveToken?.cancel('Refund provider disposed.');
    });
  }

  final Ref _ref;
  CancelToken? _previewToken;
  CancelToken? _methodsToken;
  CancelToken? _saveToken;
  var _previewSequence = 0;
  var _methodsSequence = 0;
  var _saveSequence = 0;
  var _disposed = false;

  Future<void> load() async {
    final granted =
        _ref.read(authSessionProvider)?.permissionCodes.toSet() ?? const {};
    if (!PosPermissionAccess.canProcessRefund(granted)) {
      state = state.copyWith(
        isForbidden: true,
        errorMessage: 'You do not have permission to process refunds.',
      );
      return;
    }

    await Future.wait([
      _loadPreview(),
      _loadMethods(),
    ]);
  }

  Future<void> selectMethod(ReturnRefundMethodOption method) async {
    if (!method.enabled) {
      return;
    }
    state = state.copyWith(
      selectedMethodCode: method.code,
      methodPersisted: false,
      clearError: true,
    );
    await persistSelectedMethod();
  }

  Future<bool> persistSelectedMethod() async {
    if (state.isSavingMethod) return false;
    final granted =
        _ref.read(authSessionProvider)?.permissionCodes.toSet() ?? const {};
    if (!PosPermissionAccess.canProcessRefund(granted)) {
      state = state.copyWith(
        isForbidden: true,
        errorMessage: 'You do not have permission to process refunds.',
      );
      return false;
    }

    final method = state.selectedMethod;
    if (method == null || !method.enabled) {
      state = state.copyWith(
        errorMessage: 'Select an enabled refund method to continue.',
      );
      return false;
    }

    final saleId =
        _ref.read(returnFlowProvider).selectedSale?.saleId.trim() ?? '';
    if (saleId.isEmpty) {
      state = state.copyWith(
        errorMessage: 'Complete earlier return steps before confirming refund.',
      );
      return false;
    }

    final session = _ref.read(authSessionProvider);
    final deviceContext = _ref.read(deviceActivationProvider).deviceContext;
    if (session == null || !session.isAuthenticated || deviceContext == null) {
      state = state.copyWith(
        errorMessage: 'Device context is required to save the refund method.',
      );
      return false;
    }

    _ensureAuthorizationHeader(_ref.read(appDioProvider), session);
    final sequence = ++_saveSequence;
    _saveToken?.cancel('Superseded refund method save.');
    final cancelToken = CancelToken();
    _saveToken = cancelToken;
    state = state.copyWith(isSavingMethod: true, clearError: true);

    try {
      final saved = await _ref
          .read(returnsRefundRemoteDatasourceProvider)
          .saveRefundMethod(
            deviceId: deviceContext.deviceId,
            saleId: saleId,
            methodCode: method.code,
            cancelToken: cancelToken,
          );

      if (!_acceptSave(sequence)) return false;
      final refundMethodType = method.refundMethodType;
      if (refundMethodType != null) {
        _ref
            .read(returnFlowProvider.notifier)
            .setSelectedRefundMethod(refundMethodType);
      }

      state = state.copyWith(
        isSavingMethod: false,
        selectedMethodCode: saved.methodCode,
        methodPersisted: true,
      );
      await _ref
          .read(returnResolutionProvider.notifier)
          .loadSavedResolution();
      return true;
    } on DioException catch (error) {
      if (!_acceptSave(sequence) || CancelToken.isCancel(error)) return false;
      if (error.response?.statusCode == 403) {
        state = state.copyWith(
          isSavingMethod: false,
          isForbidden: true,
          errorMessage: 'You do not have permission to save the refund method.',
        );
        return false;
      }
      state = state.copyWith(
        isSavingMethod: false,
        methodPersisted: false,
        errorMessage: messageFromDioException(
          error,
          contextPrefix: 'Unable to save refund method',
          fallback: 'Unable to save refund method. Please try again.',
        ),
      );
      return false;
    } catch (_) {
      if (!_acceptSave(sequence)) return false;
      state = state.copyWith(
        isSavingMethod: false,
        methodPersisted: false,
        errorMessage: 'Unable to save refund method. Please try again.',
      );
      return false;
    }
  }

  Future<void> _loadPreview() async {
    final flowState = _ref.read(returnFlowProvider);
    final sale = flowState.selectedSale;
    final reasonCode = flowState.selectedReasonCode;
    final lines = flowState.selectedReturnLines;

    if (sale == null || reasonCode == null || lines.isEmpty) {
      state = state.copyWith(
        isLoadingPreview: false,
        clearPreview: true,
        errorMessage: 'Complete earlier return steps before loading refund details.',
      );
      return;
    }

    final session = _ref.read(authSessionProvider);
    final deviceContext = _ref.read(deviceActivationProvider).deviceContext;
    if (session == null || !session.isAuthenticated || deviceContext == null) {
      state = state.copyWith(
        isLoadingPreview: false,
        clearPreview: true,
        errorMessage: 'Device context is required to load refund preview.',
      );
      return;
    }

    _ensureAuthorizationHeader(_ref.read(appDioProvider), session);
    final sequence = ++_previewSequence;
    _previewToken?.cancel('Superseded refund preview.');
    final cancelToken = CancelToken();
    _previewToken = cancelToken;
    state = state.copyWith(isLoadingPreview: true, clearError: true);

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
            cancelToken: cancelToken,
          );

      if (!_acceptPreview(sequence)) return;
      state = state.copyWith(isLoadingPreview: false, preview: preview);
      _ref.read(returnFlowProvider.notifier).setRefundPreview(preview);
    } on DioException catch (error) {
      if (!_acceptPreview(sequence) || CancelToken.isCancel(error)) return;
      if (error.response?.statusCode == 403) {
        state = state.copyWith(
          isLoadingPreview: false,
          clearPreview: true,
          isForbidden: true,
          errorMessage: 'You do not have permission to load refund preview.',
        );
        return;
      }
      state = state.copyWith(
        isLoadingPreview: false,
        clearPreview: true,
        errorMessage: messageFromDioException(
          error,
          contextPrefix: 'Unable to load refund preview',
          fallback: 'Unable to load refund preview. Please try again.',
        ),
      );
    } catch (_) {
      if (!_acceptPreview(sequence)) return;
      state = state.copyWith(
        isLoadingPreview: false,
        clearPreview: true,
        errorMessage: 'Unable to load refund preview. Please try again.',
      );
    }
  }

  Future<void> _loadMethods() async {
    final saleId =
        _ref.read(returnFlowProvider).selectedSale?.saleId.trim() ?? '';
    if (saleId.isEmpty) {
      state = state.copyWith(
        isLoadingMethods: false,
        clearMethods: true,
        errorMessage: 'Complete earlier return steps before loading refund methods.',
      );
      return;
    }

    final session = _ref.read(authSessionProvider);
    final deviceContext = _ref.read(deviceActivationProvider).deviceContext;
    if (session == null || !session.isAuthenticated || deviceContext == null) {
      state = state.copyWith(
        isLoadingMethods: false,
        clearMethods: true,
        errorMessage: 'Device context is required to load refund methods.',
      );
      return;
    }

    _ensureAuthorizationHeader(_ref.read(appDioProvider), session);
    final sequence = ++_methodsSequence;
    _methodsToken?.cancel('Superseded refund methods load.');
    final cancelToken = CancelToken();
    _methodsToken = cancelToken;
    state = state.copyWith(isLoadingMethods: true, clearError: true);

    try {
      final response = await _ref
          .read(returnsRefundRemoteDatasourceProvider)
          .getRefundMethods(
            deviceId: deviceContext.deviceId,
            saleId: saleId,
            cancelToken: cancelToken,
          );

      if (!_acceptMethods(sequence)) return;
      final savedCode = response.selectedMethodCode?.trim();
      final defaultCode = response.defaultMethodCode?.trim();
      String? initialSelection;
      var persisted = false;

      if (savedCode != null && savedCode.isNotEmpty) {
        initialSelection = savedCode;
        persisted = response.items.any(
          (item) =>
              item.enabled &&
              item.code.trim().toUpperCase() == savedCode.toUpperCase(),
        );
      } else if (defaultCode != null && defaultCode.isNotEmpty) {
        ReturnRefundMethodOption? defaultMethod;
        for (final item in response.items) {
          if (item.enabled &&
              item.code.trim().toUpperCase() == defaultCode.toUpperCase()) {
            defaultMethod = item;
            break;
          }
        }
        if (defaultMethod != null) {
          initialSelection = defaultMethod.code;
        }
      }

      state = state.copyWith(
        isLoadingMethods: false,
        methods: response.items,
        defaultMethodCode: response.defaultMethodCode,
        selectedMethodCode: initialSelection,
        methodPersisted: persisted,
        clearSelection: initialSelection == null,
      );

      if (persisted && initialSelection != null) {
        RefundMethodType? methodType;
        for (final item in response.items) {
          if (item.code.trim().toUpperCase() ==
              initialSelection.toUpperCase()) {
            methodType = item.refundMethodType;
            break;
          }
        }
        if (methodType != null) {
          _ref.read(returnFlowProvider.notifier).setSelectedRefundMethod(methodType);
        }
      }
    } on DioException catch (error) {
      if (!_acceptMethods(sequence) || CancelToken.isCancel(error)) return;
      if (error.response?.statusCode == 403) {
        state = state.copyWith(
          isLoadingMethods: false,
          clearMethods: true,
          isForbidden: true,
          errorMessage: 'You do not have permission to load refund methods.',
        );
        return;
      }
      state = state.copyWith(
        isLoadingMethods: false,
        clearMethods: true,
        errorMessage: messageFromDioException(
          error,
          contextPrefix: 'Unable to load refund methods',
          fallback: 'Unable to load refund methods. Please try again.',
        ),
      );
    } catch (_) {
      if (!_acceptMethods(sequence)) return;
      state = state.copyWith(
        isLoadingMethods: false,
        clearMethods: true,
        errorMessage: 'Unable to load refund methods. Please try again.',
      );
    }
  }

  bool _acceptPreview(int sequence) =>
      !_disposed && sequence == _previewSequence;
  bool _acceptMethods(int sequence) =>
      !_disposed && sequence == _methodsSequence;
  bool _acceptSave(int sequence) => !_disposed && sequence == _saveSequence;
}

void _ensureAuthorizationHeader(Dio dio, AuthSession session) {
  final currentValue = dio.options.headers['Authorization'];
  if (currentValue is String && currentValue.trim().isNotEmpty) {
    return;
  }

  dio.options.headers['Authorization'] = 'Bearer ${session.accessToken}';
}

final returnRefundDetailsProvider = StateNotifierProvider.autoDispose<
    ReturnRefundDetailsController, ReturnRefundDetailsState>(
  (ref) => ReturnRefundDetailsController(ref),
);

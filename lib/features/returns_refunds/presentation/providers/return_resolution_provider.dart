import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_error_message.dart';
import '../../../../core/network/dio_provider.dart';
import '../../../auth/domain/entities/auth_session.dart';
import '../../../auth/presentation/providers/session_provider.dart';
import '../../../device_activation/presentation/providers/device_activation_provider.dart';
import '../../domain/entities/return_resolution.dart';
import '../../domain/entities/return_resolution_type.dart';
import 'return_flow_provider.dart';
import 'return_search_provider.dart';

class ReturnResolutionState {
  const ReturnResolutionState({
    this.savedResolution,
    this.isLoading = false,
    this.isSaving = false,
    this.errorMessage,
    this.isForbidden = false,
  });

  final ReturnResolution? savedResolution;
  final bool isLoading;
  final bool isSaving;
  final String? errorMessage;
  final bool isForbidden;

  ReturnResolutionState copyWith({
    ReturnResolution? savedResolution,
    bool? isLoading,
    bool? isSaving,
    String? errorMessage,
    bool? isForbidden,
    bool clearSavedResolution = false,
    bool clearError = false,
  }) {
    return ReturnResolutionState(
      savedResolution:
          clearSavedResolution ? null : savedResolution ?? this.savedResolution,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      isForbidden: isForbidden ?? this.isForbidden,
    );
  }
}

class ReturnResolutionController extends StateNotifier<ReturnResolutionState> {
  ReturnResolutionController(this._ref) : super(const ReturnResolutionState()) {
    _ref.onDispose(() {
      _disposed = true;
      _loadToken?.cancel('Resolution provider disposed.');
      _saveToken?.cancel('Resolution provider disposed.');
    });
  }

  final Ref _ref;
  CancelToken? _loadToken;
  CancelToken? _saveToken;
  var _sequence = 0;
  var _disposed = false;

  Future<bool> loadSavedResolution({String? authoritativeSaleId}) async {
    final saleId = authoritativeSaleId?.trim().isNotEmpty == true
        ? authoritativeSaleId!.trim()
        : _ref.read(returnFlowProvider).selectedSale?.saleId.trim() ?? '';
    if (saleId.isEmpty) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'A sale is required to restore this return workflow.',
      );
      return false;
    }

    final session = _ref.read(authSessionProvider);
    final deviceContext = _ref.read(deviceActivationProvider).deviceContext;
    if (session == null || !session.isAuthenticated || deviceContext == null) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Device context is required to restore this workflow.',
      );
      return false;
    }

    _ensureAuthorizationHeader(_ref.read(appDioProvider), session);
    final sequence = ++_sequence;
    _loadToken?.cancel('Superseded resolution load.');
    final cancelToken = CancelToken();
    _loadToken = cancelToken;
    state = state.copyWith(
      isLoading: true,
      isSaving: false,
      clearError: true,
    );

    try {
      final saved =
          await _ref.read(returnsRefundRemoteDatasourceProvider).getResolution(
                deviceId: deviceContext.deviceId,
                saleId: saleId,
                cancelToken: cancelToken,
              );

      if (!_accept(sequence)) return false;
      state = state.copyWith(isLoading: false, savedResolution: saved);
      final resolutionType = saved.resolutionType;
      if (resolutionType != null) {
        _ref.read(returnFlowProvider.notifier).applyPersistedResolution(
              resolution: resolutionType,
              persisted: true,
            );
      } else {
        _ref.read(returnFlowProvider.notifier).clearPersistedResolution();
      }
      return true;
    } on DioException catch (error) {
      if (CancelToken.isCancel(error)) {
        if (_accept(sequence)) {
          state = state.copyWith(isLoading: false);
        }
        return false;
      }
      if (!_accept(sequence)) return false;
      if (error.response?.statusCode == 403) {
        state = state.copyWith(
          isLoading: false,
          isForbidden: true,
          errorMessage:
              'You do not have permission to view the saved resolution.',
        );
        return false;
      }
      state = state.copyWith(
        isLoading: false,
        errorMessage: messageFromDioException(
          error,
          contextPrefix: 'Unable to load saved resolution',
          fallback: 'Unable to load saved resolution. Please try again.',
        ),
      );
      return false;
    } catch (_) {
      if (!_accept(sequence)) return false;
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Unable to load saved resolution. Please try again.',
      );
      return false;
    }
  }

  Future<bool> saveResolution(ReturnResolutionType resolution) async {
    if (state.isSaving) return false;

    final saleId =
        _ref.read(returnFlowProvider).selectedSale?.saleId.trim() ?? '';
    if (saleId.isEmpty) {
      state = state.copyWith(
        errorMessage:
            'Complete earlier return steps before choosing an option.',
      );
      return false;
    }

    final session = _ref.read(authSessionProvider);
    final deviceContext = _ref.read(deviceActivationProvider).deviceContext;
    if (session == null || !session.isAuthenticated || deviceContext == null) {
      state = state.copyWith(
        errorMessage: 'Device context is required to save the selected option.',
      );
      return false;
    }

    final current = state.savedResolution;
    if (current == null || current.version < 1 || !current.isValidated) {
      final loaded = await loadSavedResolution();
      if (!loaded) return false;
    }
    final authoritative = state.savedResolution;
    if (authoritative == null || authoritative.version < 1) return false;

    _ensureAuthorizationHeader(_ref.read(appDioProvider), session);
    final sequence = ++_sequence;
    _loadToken?.cancel('Resolution mutation started.');
    _saveToken?.cancel('Superseded resolution mutation.');
    final cancelToken = CancelToken();
    _saveToken = cancelToken;
    state = state.copyWith(
      isSaving: true,
      isLoading: false,
      clearError: true,
      isForbidden: false,
    );

    final apiValue =
        resolution == ReturnResolutionType.exchange ? 'EXCHANGE' : 'REFUND';

    try {
      final saved =
          await _ref.read(returnsRefundRemoteDatasourceProvider).saveResolution(
                deviceId: deviceContext.deviceId,
                saleId: saleId,
                resolution: apiValue,
                expectedVersion: authoritative.version,
                cancelToken: cancelToken,
              );

      if (!_accept(sequence)) return false;
      state = state.copyWith(isSaving: false, savedResolution: saved);
      final savedType = saved.resolutionType;
      if (savedType == null) return false;
      _ref.read(returnFlowProvider.notifier).applyPersistedResolution(
            resolution: savedType,
            persisted: true,
          );
      return true;
    } on DioException catch (error) {
      if (CancelToken.isCancel(error)) {
        if (_accept(sequence)) {
          state = state.copyWith(isSaving: false);
        }
        return false;
      }
      if (!_accept(sequence)) return false;
      if (error.response?.statusCode == 409) {
        state = state.copyWith(isSaving: false, clearError: true);
        await loadSavedResolution();
        if (!_disposed) {
          state = state.copyWith(
            errorMessage:
                'This return changed on another request. Review the latest option.',
          );
        }
        return false;
      }
      if (error.response?.statusCode == 403) {
        state = state.copyWith(
          isSaving: false,
          isForbidden: true,
          errorMessage:
              'You do not have permission to save the selected option.',
        );
        return false;
      }
      state = state.copyWith(
        isSaving: false,
        errorMessage: messageFromDioException(
          error,
          contextPrefix: 'Unable to save selected option',
          fallback: 'Unable to save selected option. Please try again.',
        ),
      );
      return false;
    } catch (_) {
      if (!_accept(sequence)) return false;
      state = state.copyWith(
        isSaving: false,
        errorMessage: 'Unable to save selected option. Please try again.',
      );
      return false;
    }
  }

  bool _accept(int sequence) => !_disposed && sequence == _sequence;
}

void _ensureAuthorizationHeader(Dio dio, AuthSession session) {
  final currentValue = dio.options.headers['Authorization'];
  if (currentValue is String && currentValue.trim().isNotEmpty) {
    return;
  }

  dio.options.headers['Authorization'] = 'Bearer ${session.accessToken}';
}

final returnResolutionProvider = StateNotifierProvider.autoDispose<
    ReturnResolutionController, ReturnResolutionState>(
  (ref) => ReturnResolutionController(ref),
);

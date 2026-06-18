import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_provider.dart';
import '../../../../core/storage/secure_storage_provider.dart';
import '../../../device_activation/domain/entities/pos_device_context.dart';
import '../../application/usecases/open_till.dart';
import '../../data/datasources/till_remote_datasource.dart';
import '../../data/datasources/till_session_storage.dart';
import '../../data/repositories/till_repository_impl.dart';
import '../../domain/entities/open_till.dart';
import '../../domain/repositories/till_repository.dart';

class TillState {
  const TillState({
    this.session,
    this.isRefreshing = false,
    this.isSubmitting = false,
    this.errorMessage,
  });

  final TillSession? session;
  final bool isRefreshing;
  final bool isSubmitting;
  final String? errorMessage;

  bool get hasOpenSession => session?.status == 'open';

  TillState copyWith({
    TillSession? session,
    bool? isRefreshing,
    bool? isSubmitting,
    String? errorMessage,
    bool clearError = false,
  }) {
    return TillState(
      session: session ?? this.session,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}

class TillController extends StateNotifier<TillState> {
  TillController(this._openTill, this._storage) : super(const TillState()) {
    _restoreTillSession();
  }

  final OpenTill _openTill;
  final TillSessionStorage _storage;

  Future<bool> refreshCurrentSession({
    required PosDeviceContext deviceContext,
  }) async {
    if (state.isRefreshing || state.hasOpenSession) {
      return state.hasOpenSession;
    }

    state = state.copyWith(isRefreshing: true, clearError: true);

    try {
      final session = await _openTill.currentSession(
        OpenTillForm(
          deviceContext: deviceContext,
          openingFloat: 0,
          openingNote: '',
        ),
      );

      if (session == null) {
        state = state.copyWith(isRefreshing: false);
        return false;
      }

      await _storage.save(session);
      state = TillState(session: session);
      return true;
    } on TillException catch (error) {
      state = state.copyWith(
        isRefreshing: false,
        errorMessage: error.message,
      );
      return false;
    } catch (error) {
      state = state.copyWith(
        isRefreshing: false,
        errorMessage: 'Current till session failed unexpectedly: $error',
      );
      return false;
    }
  }

  Future<bool> openTill({
    required PosDeviceContext deviceContext,
    required double openingFloat,
    required String openingNote,
  }) async {
    if (state.isSubmitting) {
      return false;
    }

    state = state.copyWith(isSubmitting: true, clearError: true);

    try {
      final session = await _openTill(
        OpenTillForm(
          deviceContext: deviceContext,
          openingFloat: openingFloat,
          openingNote: openingNote,
        ),
      );
      await _storage.save(session);
      state = TillState(session: session);
      return true;
    } on TillException catch (error) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: error.message,
      );
      return false;
    } catch (_) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: 'Till could not be opened. Try again.',
      );
      return false;
    }
  }

  Future<void> clear() async {
    await _storage.clear();
    state = const TillState();
  }

  /// Loads persisted till session into state if not already present.
  Future<void> ensureHydrated() async {
    if (state.session != null) {
      return;
    }

    final session = await _storage.read();
    if (session != null) {
      state = TillState(session: session);
    }
  }

  Future<void> _restoreTillSession() async {
    await ensureHydrated();
  }
}

final tillRemoteDatasourceProvider = Provider<TillRemoteDatasource>((ref) {
  return TillRemoteDatasource(ref.watch(appDioProvider));
});

final tillRepositoryProvider = Provider<TillRepository>((ref) {
  return TillRepositoryImpl(ref.watch(tillRemoteDatasourceProvider));
});

final openTillProvider = Provider<OpenTill>((ref) {
  return OpenTill(ref.watch(tillRepositoryProvider));
});

final tillSessionStorageProvider = Provider<TillSessionStorage>((ref) {
  return TillSessionStorage(ref.watch(secureStorageProvider));
});

final tillProvider = StateNotifierProvider<TillController, TillState>((ref) {
  return TillController(
    ref.watch(openTillProvider),
    ref.watch(tillSessionStorageProvider),
  );
});

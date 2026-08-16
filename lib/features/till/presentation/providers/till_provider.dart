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
    _hydrationFuture = _hydrateFromStorage();
  }

  final OpenTill _openTill;
  final TillSessionStorage _storage;
  late final Future<void> _hydrationFuture;

  Future<bool> refreshCurrentSession({
    required PosDeviceContext deviceContext,
    bool force = false,
  }) async {
    await ensureHydrated();

    if (state.isRefreshing) {
      return state.hasOpenSession;
    }

    if (!force && state.hasOpenSession) {
      return true;
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
        await _storage.clear();
        state = const TillState();
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
    await ensureHydrated();

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

  Future<ClosedTillSession?> closeTill({
    required PosDeviceContext deviceContext,
    required double countedCash,
    required double expectedCash,
    String? mismatchReason,
    String? closingNote,
  }) async {
    await ensureHydrated();

    if (state.isSubmitting) {
      return null;
    }

    state = state.copyWith(isSubmitting: true, clearError: true);

    try {
      final closedSession = await _openTill.closeTill(
        CloseTillForm(
          deviceContext: deviceContext,
          countedCash: countedCash,
          expectedCash: expectedCash,
          mismatchReason: mismatchReason,
          closingNote: closingNote,
        ),
      );
      await _storage.clear();
      state = const TillState();
      return closedSession;
    } on TillException catch (error) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: error.message,
      );
      return null;
    } catch (_) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: 'Till could not be closed. Try again.',
      );
      return null;
    }
  }

  Future<void> clear() async {
    await ensureHydrated();
    await _storage.clear();
    state = const TillState();
  }

  /// Loads persisted till session into state if not already present.
  Future<void> ensureHydrated() async {
    await _hydrationFuture;
  }

  Future<void> _hydrateFromStorage() async {
    final session = await _storage.read();
    if (session != null && state.session == null) {
      state = TillState(session: session);
    }
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

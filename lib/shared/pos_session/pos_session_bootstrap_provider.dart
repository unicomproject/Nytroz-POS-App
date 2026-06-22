import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/domain/entities/auth_session.dart';
import '../../features/auth/presentation/providers/session_provider.dart';
import '../../features/device_activation/presentation/providers/device_activation_provider.dart';
import '../../features/till/presentation/providers/till_provider.dart';

const posSessionBootRoute = '/pos/boot';

class PosSessionBootstrapState {
  const PosSessionBootstrapState({
    this.isLoading = false,
    this.isReady = false,
    this.errorMessage,
    this.failedStep,
  });

  final bool isLoading;
  final bool isReady;
  final String? errorMessage;
  final String? failedStep;

  bool get hasError => errorMessage != null;
}

class PosSessionBootstrapNotifier
    extends StateNotifier<PosSessionBootstrapState> {
  PosSessionBootstrapNotifier(this._ref, {bool autoStart = true})
      : super(const PosSessionBootstrapState()) {
    if (autoStart) {
      _listenAuth();
    }
  }

  final Ref _ref;
  Future<void>? _bootstrapFuture;

  void _listenAuth() {
    _ref.listen<AuthSession?>(
      authSessionProvider,
      (previous, next) {
        if (next == null || !next.isAuthenticated) {
          state = const PosSessionBootstrapState();
          return;
        }

        if (previous?.accessToken == next.accessToken && state.isReady) {
          return;
        }

        unawaited(bootstrap());
      },
      fireImmediately: true,
    );
  }

  Future<void> bootstrap({bool force = false}) async {
    if (!force && state.isReady) {
      return;
    }

    if (_bootstrapFuture != null) {
      return _bootstrapFuture;
    }

    _bootstrapFuture = _runBootstrap(force: force);
    try {
      await _bootstrapFuture;
    } finally {
      _bootstrapFuture = null;
    }
  }

  Future<void> _runBootstrap({bool force = false}) async {
    if (!force && state.isLoading) {
      return;
    }

    state = const PosSessionBootstrapState(isLoading: true);
    final stopwatch = Stopwatch()..start();
    developer.log(
      'POS session bootstrap started.',
      name: 'pos.session',
    );

    try {
      final session = _ref.read(authSessionProvider);
      if (session == null ||
          !session.isAuthenticated ||
          !session.requiresPosDeviceBootstrap) {
        developer.log(
          'POS session bootstrap skipped: no POS device/till permissions.',
          name: 'pos.session',
        );
        state = const PosSessionBootstrapState(isReady: true);
        stopwatch.stop();
        developer.log(
          'POS session bootstrap finished. success=true durationMs=${stopwatch.elapsedMilliseconds}',
          name: 'pos.session',
        );
        return;
      }

      await _runStep(
        'hydrate-device-context',
        () => _ref.read(deviceActivationProvider.notifier).ensureHydrated(),
      );
      var device = _ref.read(deviceActivationProvider).deviceContext;

      if (session.canActivatePosDevice &&
          (device == null || !device.isTrusted)) {
        final refreshed = await _runStep(
          'refresh-current-device',
          () =>
              _ref.read(deviceActivationProvider.notifier).refreshCurrentDevice(
                    deviceName: device?.deviceName ?? 'Web POS',
                  ),
        );
        device = _ref.read(deviceActivationProvider).deviceContext;
        final deviceError = _ref.read(deviceActivationProvider).errorMessage;
        if (!refreshed && deviceError != null) {
          throw PosSessionBootstrapException(
            'refresh-current-device',
            deviceError,
          );
        }
      }

      if (session.canOpenPosTill && device != null && device.isTrusted) {
        await _runStep(
          'hydrate-till-session',
          () => _ref.read(tillProvider.notifier).ensureHydrated(),
        );
        var tillSession = _ref.read(tillProvider).session;

        if (tillSession == null || tillSession.status != 'open') {
          final refreshed = await _runStep(
            'refresh-current-till-session',
            () => _ref.read(tillProvider.notifier).refreshCurrentSession(
                  deviceContext: device!,
                ),
          );
          final tillError = _ref.read(tillProvider).errorMessage;
          if (!refreshed && tillError != null) {
            throw PosSessionBootstrapException(
              'refresh-current-till-session',
              tillError,
            );
          }
        }
      }
      state = const PosSessionBootstrapState(isReady: true);
      stopwatch.stop();
      developer.log(
        'POS session bootstrap finished. success=true durationMs=${stopwatch.elapsedMilliseconds}',
        name: 'pos.session',
      );
    } on PosSessionBootstrapException catch (error) {
      stopwatch.stop();
      state = PosSessionBootstrapState(
        errorMessage: error.message,
        failedStep: error.step,
      );
      developer.log(
        'POS session bootstrap finished. success=false step=${error.step} durationMs=${stopwatch.elapsedMilliseconds} message=${error.message}',
        name: 'pos.session',
      );
    } catch (error) {
      stopwatch.stop();
      state = PosSessionBootstrapState(
        errorMessage: 'POS session could not be prepared. $error',
        failedStep: 'bootstrap',
      );
      developer.log(
        'POS session bootstrap finished. success=false step=bootstrap durationMs=${stopwatch.elapsedMilliseconds} message=$error',
        name: 'pos.session',
      );
    }
  }

  Future<T> _runStep<T>(String step, Future<T> Function() action) async {
    final stopwatch = Stopwatch()..start();
    developer.log(
      'POS bootstrap step started. step=$step',
      name: 'pos.session',
    );

    try {
      final result = await action();
      stopwatch.stop();
      developer.log(
        'POS bootstrap step succeeded. step=$step durationMs=${stopwatch.elapsedMilliseconds}',
        name: 'pos.session',
      );
      return result;
    } catch (error) {
      stopwatch.stop();
      developer.log(
        'POS bootstrap step failed. step=$step durationMs=${stopwatch.elapsedMilliseconds} message=$error',
        name: 'pos.session',
      );
      rethrow;
    }
  }
}

class PosSessionBootstrapException implements Exception {
  const PosSessionBootstrapException(this.step, this.message);

  final String step;
  final String message;

  @override
  String toString() => '$step: $message';
}

final posSessionBootstrapProvider = StateNotifierProvider<
    PosSessionBootstrapNotifier, PosSessionBootstrapState>((ref) {
  return PosSessionBootstrapNotifier(ref);
});

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
  });

  final bool isLoading;
  final bool isReady;
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
    _ref.listen<AuthSession?>(authSessionProvider, (previous, next) {
      if (next == null || !next.isAuthenticated) {
        state = const PosSessionBootstrapState();
        return;
      }

      if (previous?.accessToken == next.accessToken && state.isReady) {
        return;
      }

      unawaited(bootstrap());
    });
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
    developer.log('POS session bootstrap started.', name: 'pos.session');

    try {
      await _ref.read(deviceActivationProvider.notifier).ensureHydrated();
      var device = _ref.read(deviceActivationProvider).deviceContext;

      if (device == null || !device.isTrusted) {
        await _ref.read(deviceActivationProvider.notifier).refreshCurrentDevice(
              deviceName: device?.deviceName ?? 'Web POS',
            );
        device = _ref.read(deviceActivationProvider).deviceContext;
      }

      if (device != null && device.isTrusted) {
        await _ref.read(tillProvider.notifier).ensureHydrated();
        var tillSession = _ref.read(tillProvider).session;

        if (tillSession == null || tillSession.status != 'open') {
          await _ref.read(tillProvider.notifier).refreshCurrentSession(
                deviceContext: device,
              );
        }
      }
    } finally {
      state = const PosSessionBootstrapState(isReady: true);
      developer.log('POS session bootstrap finished.', name: 'pos.session');
    }
  }
}

final posSessionBootstrapProvider = StateNotifierProvider<
    PosSessionBootstrapNotifier, PosSessionBootstrapState>((ref) {
  return PosSessionBootstrapNotifier(ref);
});

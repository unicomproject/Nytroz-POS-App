import 'dart:developer' as developer;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_provider.dart';
import '../../../../core/storage/secure_storage_provider.dart';
import '../../application/usecases/activate_device.dart';
import '../../data/device_fingerprint.dart';
import '../../data/datasources/device_context_storage.dart';
import '../../data/datasources/device_activation_remote_datasource.dart';
import '../../data/repositories/device_activation_repository_impl.dart';
import '../../domain/entities/pos_device_context.dart';
import '../../domain/repositories/device_activation_repository.dart';

class DeviceActivationState {
  const DeviceActivationState({
    this.deviceContext,
    this.isRefreshing = false,
    this.isSubmitting = false,
    this.errorMessage,
  });

  final PosDeviceContext? deviceContext;
  final bool isRefreshing;
  final bool isSubmitting;
  final String? errorMessage;

  bool get isTrusted => deviceContext?.isTrusted ?? false;

  DeviceActivationState copyWith({
    PosDeviceContext? deviceContext,
    bool? isRefreshing,
    bool? isSubmitting,
    String? errorMessage,
    bool clearError = false,
  }) {
    return DeviceActivationState(
      deviceContext: deviceContext ?? this.deviceContext,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}

class DeviceActivationController extends StateNotifier<DeviceActivationState> {
  DeviceActivationController(this._activateDevice, this._storage)
      : super(const DeviceActivationState()) {
    _restoreDeviceContext();
  }

  final ActivateDevice _activateDevice;
  final DeviceContextStorage _storage;

  Future<bool> refreshCurrentDevice({required String deviceName}) async {
    if (state.isRefreshing) {
      return state.isTrusted;
    }

    state = state.copyWith(isRefreshing: true, clearError: true);

    try {
      final candidates = uniqueFingerprints([
        ...await _storage.readDeviceFingerprintCandidates(),
        await _storage.readOrCreateDeviceFingerprint(),
      ]);
      PosDeviceContext? device;

      for (final fingerprint in candidates) {
        developer.log(
          'Checking current device for fingerprint=$fingerprint',
          name: 'pos.session',
        );

        device = await _activateDevice.currentDevice(
          DeviceActivationForm(
            activationCode: '',
            deviceName: deviceName,
            deviceFingerprint: fingerprint,
            deviceType: 'fixed_pos_tablet',
            platform: currentDevicePlatform(),
            appVersion: 'dev',
          ),
        );

        if (device != null) {
          break;
        }
      }

      if (device == null) {
        developer.log(
          'No trusted device found on server for known fingerprints.',
          name: 'pos.session',
        );

        final cachedDevice = await _storage.read();
        if (cachedDevice != null) {
          developer.log(
            'Keeping locally cached trusted device context after server miss.',
            name: 'pos.session',
          );
          state = DeviceActivationState(deviceContext: cachedDevice);
          return cachedDevice.isTrusted;
        }

        try {
          await _storage.clear();
        } catch (_) {
          // Ignore secure-storage cleanup failures on web.
        }
        state = const DeviceActivationState();
        return false;
      }

      if (!device.isTrusted || device.deviceId.trim().isEmpty) {
        developer.log(
          'Current device response was not trusted or missing deviceId.',
          name: 'pos.session',
        );
        try {
          await _storage.clear();
        } catch (_) {
          // Ignore secure-storage cleanup failures on web.
        }
        state = const DeviceActivationState();
        return false;
      }

      await _storage.save(device);
      state = DeviceActivationState(deviceContext: device);
      return true;
    } on DeviceActivationException catch (error) {
      developer.log(
        'Current device restore failed: ${error.message}',
        name: 'pos.session',
      );
      state = state.copyWith(
        isRefreshing: false,
        errorMessage: error.message,
      );
      return false;
    } catch (error) {
      final message = 'Current device restore failed unexpectedly: $error';
      developer.log(
        message,
        name: 'pos.session',
      );
      state = state.copyWith(
        isRefreshing: false,
        errorMessage: message,
      );
      return false;
    }
  }

  Future<bool> activate({
    required String activationCode,
    required String deviceName,
  }) async {
    if (state.isSubmitting) {
      return false;
    }

    state = state.copyWith(isSubmitting: true, clearError: true);

    try {
      final fingerprint = await _storage.readOrCreateDeviceFingerprint();
      final device = await _activateDevice(
        DeviceActivationForm(
          activationCode: activationCode,
          deviceName: deviceName,
          deviceFingerprint: fingerprint,
          deviceType: 'fixed_pos_tablet',
          platform: currentDevicePlatform(),
          appVersion: 'dev',
        ),
      );
      await _storage.save(device);
      state = DeviceActivationState(deviceContext: device);
      return true;
    } on DeviceActivationException catch (error) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: error.message,
      );
      return false;
    } catch (_) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: 'Device activation failed. Try again.',
      );
      return false;
    }
  }

  Future<void> clear() async {
    await _storage.clear();
    state = const DeviceActivationState();
  }

  /// Loads persisted device context into state if not already present.
  Future<void> ensureHydrated() async {
    if (state.deviceContext != null) {
      return;
    }

    try {
      final device = await _storage.read();
      if (device != null) {
        state = DeviceActivationState(deviceContext: device);
      }
    } catch (error, stackTrace) {
      developer.log(
        'Device context hydration failed.',
        name: 'pos.session',
        error: error,
        stackTrace: stackTrace,
      );
      try {
        await _storage.clear();
      } catch (_) {
        // Ignore secure-storage cleanup failures on web.
      }
      state = const DeviceActivationState();
    }
  }

  Future<void> _restoreDeviceContext() async {
    await ensureHydrated();
  }
}

final deviceActivationRemoteDatasourceProvider =
    Provider<DeviceActivationRemoteDatasource>((ref) {
  return DeviceActivationRemoteDatasource(ref.watch(appDioProvider));
});

final deviceActivationRepositoryProvider =
    Provider<DeviceActivationRepository>((ref) {
  return DeviceActivationRepositoryImpl(
    ref.watch(deviceActivationRemoteDatasourceProvider),
  );
});

final activateDeviceProvider = Provider<ActivateDevice>((ref) {
  return ActivateDevice(ref.watch(deviceActivationRepositoryProvider));
});

final deviceContextStorageProvider = Provider<DeviceContextStorage>((ref) {
  return DeviceContextStorage(ref.watch(secureStorageProvider));
});

final deviceActivationProvider =
    StateNotifierProvider<DeviceActivationController, DeviceActivationState>(
        (ref) {
  return DeviceActivationController(
    ref.watch(activateDeviceProvider),
    ref.watch(deviceContextStorageProvider),
  );
});

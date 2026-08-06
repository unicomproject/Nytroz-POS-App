import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_provider.dart';
import '../../../auth/presentation/providers/session_provider.dart';
import '../../../device_activation/presentation/providers/device_activation_provider.dart';
import '../../data/datasources/pos_telemetry_remote_datasource.dart';

final posTelemetryRemoteDataSourceProvider =
    Provider<PosTelemetryRemoteDataSource>((ref) {
  return PosTelemetryRemoteDataSource(ref.watch(appDioProvider));
});

class HardwareTelemetryNotifier extends StateNotifier<void> {
  HardwareTelemetryNotifier(this.ref) : super(null) {
    _startTimer();
  }

  final Ref ref;
  Timer? _timer;

  void _startTimer() {
    _timer?.cancel();
    _timer =
        Timer.periodic(const Duration(seconds: 30), (_) => _sendHeartbeat());
    // Send immediate heartbeat
    _sendHeartbeat();
  }

  Future<void> _sendHeartbeat() async {
    final session = ref.read(authSessionProvider);
    if (session == null || !session.isAuthenticated) return;

    final deviceContext = ref.read(deviceActivationProvider).deviceContext;
    if (deviceContext == null || !deviceContext.isTrusted) return;

    final posDeviceId = deviceContext.deviceId;
    if (posDeviceId.isEmpty) return;

    try {
      final payload = {
        'observedAt': DateTime.now().toIso8601String(),
        'hardware':
            [], // Empty for now, wait until hardware sync is implemented
      };

      await ref
          .read(posTelemetryRemoteDataSourceProvider)
          .sendHardwareHeartbeat(
            posDeviceId,
            payload,
          );
    } catch (e) {
      // Ignore network errors for heartbeat
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

final hardwareTelemetryProvider =
    StateNotifierProvider<HardwareTelemetryNotifier, void>((ref) {
  return HardwareTelemetryNotifier(ref);
});

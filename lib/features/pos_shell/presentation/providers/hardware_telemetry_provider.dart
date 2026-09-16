import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_provider.dart';
import '../../../auth/presentation/providers/session_provider.dart';
import '../../../device_activation/presentation/providers/device_activation_provider.dart';
import '../../data/datasources/pos_telemetry_remote_datasource.dart';
import '../../../hardware/receipt_printer/config/pos_device_printer_config_store.dart';
import '../../../hardware/receipt_printer/pos_receipt_printer_service.dart';
import '../../../hardware/receipt_printer/models/pos_device_printer_config.dart';
import '../../../hardware/receipt_printer/platform/android_receipt_printer_platform.dart';
import '../../../hardware/device_configuration/hardware_observation_events.dart';
import '../../../hardware/receipt_printer/presentation/providers/local_print_agent_controller.dart';

final posTelemetryRemoteDataSourceProvider =
    Provider<PosTelemetryRemoteDataSource>((ref) {
  return PosTelemetryRemoteDataSource(ref.watch(appDioProvider));
});

class HardwareTelemetryNotifier extends StateNotifier<void> {
  HardwareTelemetryNotifier(this.ref) : super(null) {
    _startTimer();
    _inputs = hardwareInputObservations.listen(_observeInput);
  }

  final Ref ref;
  Timer? _timer;
  bool _sending = false;
  StreamSubscription<HardwareInputObservation>? _inputs;
  DateTime? _lastInputSent;
  bool _inputSending = false;

  Future<void> _observeInput(HardwareInputObservation event) async {
    if (kIsWeb || _inputSending || !mounted) return;
    final context = ref.read(deviceActivationProvider).deviceContext;
    if (context == null ||
        !context.isTrusted ||
        ref.read(authSessionProvider)?.isAuthenticated != true) {
      return;
    }
    if (_lastInputSent != null &&
        event.observedAt.difference(_lastInputSent!) <
            const Duration(seconds: 30)) {
      return;
    }
    _inputSending = true;
    _lastInputSent = event.observedAt;
    try {
      final configurations = await ref
          .read(posHardwareRepositoryProvider)
          .getConfigurations(context.deviceId);
      final matching = configurations
          .where((c) =>
              c.enabled &&
              c.hardwareType == 'barcodeScanner' &&
              (event.mode == 'camera'
                  ? c.settings['mode'] == 'camera'
                  : ['hid', 'usbHid', 'bluetoothHid']
                      .contains(c.settings['mode'])))
          .toList();
      // Keyboard input cannot distinguish multiple assigned HID devices.
      if (matching.length != 1) return;
      final scanner = matching.single;
      await ref
          .read(posTelemetryRemoteDataSourceProvider)
          .sendHardwareHeartbeat(context.deviceId, {
        'observedAt': event.observedAt.toIso8601String(),
        'hardware': [
          {
            'hardwareDeviceId': scanner.configurationId,
            'configurationVersion': scanner.configurationVersion,
            'connectionStatus': 'CONNECTED',
            'healthStatus': 'HEALTHY'
          }
        ],
      });
      _lastInputSent = event.observedAt;
    } catch (_) {
      // Observability cannot interrupt a scan or product lookup.
    } finally {
      _inputSending = false;
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer =
        Timer.periodic(const Duration(seconds: 30), (_) => _sendHeartbeat());
    // Send immediate heartbeat
    _sendHeartbeat();
  }

  Future<void> _sendHeartbeat() async {
    if (kIsWeb || _sending) return;
    final session = ref.read(authSessionProvider);
    if (session == null || !session.isAuthenticated) return;

    final deviceContext = ref.read(deviceActivationProvider).deviceContext;
    if (deviceContext == null || !deviceContext.isTrusted) return;

    final posDeviceId = deviceContext.deviceId;
    if (posDeviceId.isEmpty) return;

    _sending = true;
    try {
      final config =
          await ref.read(posDevicePrinterConfigStoreProvider).load(posDeviceId);
      if (config == null ||
          !config.enabled ||
          config.configurationId == null ||
          config.deviceId != posDeviceId) {
        return;
      }
      if (config.connectionType == PrinterConnectionType.bluetooth) {
        final observed = await MethodChannelAndroidReceiptPrinter()
            .bluetoothLastWriteObservation(config.bluetoothAddress ?? '');
        // Preserve the real write time; idle polling never manufactures freshness.
        if (observed == null ||
            DateTime.now().toUtc().difference(observed) >
                const Duration(seconds: 90)) {
          return;
        }
        await ref
            .read(posTelemetryRemoteDataSourceProvider)
            .sendHardwareHeartbeat(posDeviceId, {
          'observedAt': observed.toIso8601String(),
          'hardware': [
            {
              'hardwareDeviceId': config.configurationId,
              'configurationVersion': config.configurationVersion,
              'connectionStatus': 'CONNECTED',
              'healthStatus': 'HEALTHY',
            }
          ],
        });
        return;
      }
      final service =
          PosReceiptPrinterService(loadConfiguration: (_) async => config);
      final adapter = service.selectAdapter(config);
      var connected = false;
      try {
        if (config.connectionType == PrinterConnectionType.usb) {
          // Enumeration never opens the device or displays a permission prompt during checkout.
          final devices = await MethodChannelAndroidReceiptPrinter()
              .usbListDevices()
              .timeout(const Duration(seconds: 8));
          connected = devices.any((device) =>
              device.vendorId == config.usbVendorId &&
              device.productId == config.usbProductId &&
              device.hasPermission &&
              (config.usbDeviceIdentifier == null ||
                  config.usbDeviceIdentifier == device.deviceName ||
                  config.usbDeviceIdentifier == device.serialNumber));
        } else {
          await adapter.checkStatus(config).timeout(const Duration(seconds: 8));
          connected = true;
        }
      } catch (_) {
        connected = false;
      } finally {
        await adapter.disconnect();
      }
      final payload = {
        'observedAt': DateTime.now().toUtc().toIso8601String(),
        'hardware': [
          {
            'hardwareDeviceId': config.configurationId,
            'configurationVersion': config.configurationVersion,
            'connectionStatus': connected ? 'CONNECTED' : 'DISCONNECTED',
            'healthStatus': connected ? 'HEALTHY' : 'FAILED',
            if (!connected) 'warningCode': 'TRANSPORT_UNAVAILABLE',
          }
        ],
      };

      await ref
          .read(posTelemetryRemoteDataSourceProvider)
          .sendHardwareHeartbeat(
            posDeviceId,
            payload,
          );
    } catch (e) {
      // Ignore network errors for heartbeat
    } finally {
      _sending = false;
    }
  }

  @override
  void dispose() {
    _inputs?.cancel();
    _timer?.cancel();
    super.dispose();
  }
}

final hardwareTelemetryProvider =
    StateNotifierProvider<HardwareTelemetryNotifier, void>((ref) {
  return HardwareTelemetryNotifier(ref);
});

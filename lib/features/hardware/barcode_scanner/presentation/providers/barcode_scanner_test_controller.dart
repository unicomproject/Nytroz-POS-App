import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../device_activation/presentation/providers/device_activation_provider.dart';
import '../../../device_configuration/models/pos_hardware_models.dart';
import '../../../receipt_printer/presentation/providers/local_print_agent_controller.dart';

enum BarcodeScannerTestStatus {
  loading,
  ready,
  saving,
  listening,
  awaitingConfirmation,
  finalizing,
  passed,
  failed,
  backendUnavailable,
  notConfigured,
}

class BarcodeScannerTestState {
  const BarcodeScannerTestState({
    this.status = BarcodeScannerTestStatus.loading,
    this.configuration,
    this.settings = const PosBarcodeScannerConfiguration(),
    this.pendingOperation,
    this.detectedBarcode,
    this.detectedAt,
    this.history = const [],
    this.message = 'Loading scanner configuration…',
  });

  final BarcodeScannerTestStatus status;
  final PosHardwareConfiguration? configuration;
  final PosBarcodeScannerConfiguration settings;
  final HardwareTestOperation? pendingOperation;
  final String? detectedBarcode;
  final DateTime? detectedAt;
  final List<HardwareTestOperation> history;
  final String message;

  bool get isListening => status == BarcodeScannerTestStatus.listening;
  bool get isBusy =>
      status == BarcodeScannerTestStatus.loading ||
      status == BarcodeScannerTestStatus.saving ||
      status == BarcodeScannerTestStatus.finalizing;

  BarcodeScannerTestState copyWith({
    BarcodeScannerTestStatus? status,
    PosHardwareConfiguration? configuration,
    bool clearConfiguration = false,
    PosBarcodeScannerConfiguration? settings,
    HardwareTestOperation? pendingOperation,
    bool clearPendingOperation = false,
    String? detectedBarcode,
    bool clearDetectedBarcode = false,
    DateTime? detectedAt,
    bool clearDetectedAt = false,
    List<HardwareTestOperation>? history,
    String? message,
  }) =>
      BarcodeScannerTestState(
        status: status ?? this.status,
        configuration:
            clearConfiguration ? null : configuration ?? this.configuration,
        settings: settings ?? this.settings,
        pendingOperation: clearPendingOperation
            ? null
            : pendingOperation ?? this.pendingOperation,
        detectedBarcode: clearDetectedBarcode
            ? null
            : detectedBarcode ?? this.detectedBarcode,
        detectedAt: clearDetectedAt ? null : detectedAt ?? this.detectedAt,
        history: history ?? this.history,
        message: message ?? this.message,
      );
}

final barcodeScannerTestControllerProvider =
    NotifierProvider<BarcodeScannerTestController, BarcodeScannerTestState>(
  BarcodeScannerTestController.new,
);

class BarcodeScannerTestController extends Notifier<BarcodeScannerTestState> {
  final Random _random = Random.secure();

  @override
  BarcodeScannerTestState build() => const BarcodeScannerTestState();

  Future<void> load() async {
    final device = ref.read(deviceActivationProvider).deviceContext;
    if (device == null || device.deviceId.trim().isEmpty) {
      state = const BarcodeScannerTestState(
        status: BarcodeScannerTestStatus.notConfigured,
        message: 'Activate this POS device before configuring a scanner.',
      );
      return;
    }
    try {
      final repository = ref.read(posHardwareRepositoryProvider);
      final configurations =
          await repository.getConfigurations(device.deviceId);
      final scanner = configurations
          .where((item) => item.hardwareType == 'barcodeScanner')
          .firstOrNull;
      final history = (await repository.getHistory(device.deviceId))
          .where((item) => item.hardwareType == 'barcodeScanner')
          .toList(growable: false);
      state = BarcodeScannerTestState(
        status: scanner == null
            ? BarcodeScannerTestStatus.notConfigured
            : BarcodeScannerTestStatus.ready,
        configuration: scanner,
        settings: scanner == null
            ? const PosBarcodeScannerConfiguration()
            : PosBarcodeScannerConfiguration.fromHardware(scanner),
        history: history,
        message: scanner == null
            ? 'Save an authoritative scanner configuration before testing.'
            : 'Scanner configuration version '
                '${scanner.configurationVersion} loaded.',
      );
    } on PosHardwareApiException catch (error) {
      state = state.copyWith(
        status: BarcodeScannerTestStatus.backendUnavailable,
        message: error.message,
      );
    }
  }

  Future<List<String>> save({
    required String displayName,
    required bool enabled,
    required String mode,
    required String inputSuffix,
    required int scanTimeout,
    required int minimumBarcodeLength,
    required int maximumBarcodeLength,
    required bool allowRapidScan,
    required bool cameraEnabled,
    String? changeReason,
  }) async {
    final errors = <String>[];
    if (displayName.trim().isEmpty || displayName.trim().length > 150) {
      errors
          .add('Scanner name is required and must be at most 150 characters.');
    }
    if (mode != 'usbHid' && mode != 'camera') {
      errors.add('Select USB HID or Camera mode.');
    }
    if (scanTimeout < 20 || scanTimeout > 1000) {
      errors.add('Scan timeout must be 20–1000 ms.');
    }
    if (minimumBarcodeLength < 1 ||
        maximumBarcodeLength > 512 ||
        minimumBarcodeLength > maximumBarcodeLength) {
      errors.add('Barcode length range must be between 1 and 512.');
    }
    if (mode == 'camera' && !cameraEnabled) {
      errors.add('Camera must be enabled for camera mode.');
    }
    final device = ref.read(deviceActivationProvider).deviceContext;
    if (device == null) errors.add('Activate this POS device before saving.');
    if (errors.isNotEmpty) return errors;

    state = state.copyWith(
      status: BarcodeScannerTestStatus.saving,
      message: 'Saving scanner configuration…',
    );
    try {
      final configuration =
          await ref.read(posHardwareRepositoryProvider).saveConfiguration({
        'posDeviceId': device!.deviceId,
        'outletId': device.outletId,
        'tillId': device.tillId.isEmpty ? null : device.tillId,
        'hardwareType': 'barcodeScanner',
        'transportType': mode,
        'displayName': displayName.trim(),
        'enabled': enabled,
        'expectedVersion': state.configuration?.configurationVersion ?? 0,
        'changeReason':
            changeReason?.trim().isEmpty == true ? null : changeReason?.trim(),
        'receiptPrinter': null,
        'barcodeScanner': {
          'mode': mode,
          'enabledFormats': const [
            'ean13',
            'ean8',
            'upcA',
            'code128',
            'code39',
          ],
          'enterSuffixEnabled': true,
          'inputSuffix': inputSuffix,
          'scanTimeout': scanTimeout,
          'minimumBarcodeLength': minimumBarcodeLength,
          'maximumBarcodeLength': maximumBarcodeLength,
          'allowRapidScan': allowRapidScan,
          'cameraEnabled': cameraEnabled,
        },
        'cashDrawer': null,
        'cardTerminal': null,
      });
      state = state.copyWith(
        status: BarcodeScannerTestStatus.ready,
        configuration: configuration,
        settings: PosBarcodeScannerConfiguration.fromHardware(configuration),
        message:
            'Scanner configuration version ${configuration.configurationVersion} saved.',
      );
      return const [];
    } on PosHardwareApiException catch (error) {
      state = state.copyWith(
        status: error.code == 'pos_hardware.version_conflict'
            ? BarcodeScannerTestStatus.failed
            : BarcodeScannerTestStatus.backendUnavailable,
        message: error.message,
      );
      return [error.message];
    }
  }

  Future<bool> startTest(String testType) async {
    final configuration = state.configuration;
    final device = ref.read(deviceActivationProvider).deviceContext;
    if (configuration == null || device == null || !configuration.enabled) {
      state = state.copyWith(
        status: BarcodeScannerTestStatus.notConfigured,
        message: 'Save and enable the scanner configuration first.',
      );
      return false;
    }
    try {
      final operation =
          await ref.read(posHardwareRepositoryProvider).createTest({
        'requestId': _newUuid(),
        'posDeviceId': device.deviceId,
        'tillId': device.tillId.isEmpty ? null : device.tillId,
        'hardwareConfigurationId': configuration.configurationId,
        'hardwareType': 'barcodeScanner',
        'testType': testType,
        'configurationVersion': configuration.configurationVersion,
      });
      state = state.copyWith(
        status: BarcodeScannerTestStatus.listening,
        pendingOperation: operation,
        clearDetectedBarcode: true,
        clearDetectedAt: true,
        message: state.settings.mode == 'camera'
            ? 'Camera test registered. Scan a physical barcode.'
            : 'HID test registered. Scan a physical barcode now.',
      );
      return true;
    } on PosHardwareApiException catch (error) {
      state = state.copyWith(
        status: BarcodeScannerTestStatus.backendUnavailable,
        message: error.message,
      );
      return false;
    }
  }

  void acceptDetectedBarcode(String barcode) {
    if (!state.isListening || state.pendingOperation == null) return;
    final normalized = barcode.trim();
    if (normalized.length < state.settings.minimumBarcodeLength ||
        normalized.length > state.settings.maximumBarcodeLength) {
      state = state.copyWith(
        status: BarcodeScannerTestStatus.failed,
        message: 'Scanner input was detected but its length is invalid.',
      );
      return;
    }
    state = state.copyWith(
      status: BarcodeScannerTestStatus.awaitingConfirmation,
      detectedBarcode: normalized,
      detectedAt: DateTime.now().toUtc(),
      message:
          'Scanner input detected. Product lookup is not required for this hardware pass.',
    );
  }

  Future<void> finalize({required bool physicalConfirmation}) async {
    final operation = state.pendingOperation;
    final barcode = state.detectedBarcode;
    final detectedAt = state.detectedAt;
    if (operation == null || barcode == null || detectedAt == null) return;
    state = state.copyWith(
      status: BarcodeScannerTestStatus.finalizing,
      message: 'Submitting scanner test result…',
    );
    final latency = detectedAt
        .difference(operation.initiatedAt ?? detectedAt)
        .inMilliseconds;
    try {
      final result = await ref.read(posHardwareRepositoryProvider).submitResult(
        operation.testId,
        {
          'status': physicalConfirmation ? 'Passed' : 'Failed',
          'resultCategory': physicalConfirmation
              ? 'scanner_input_detected'
              : 'scanner_not_detected',
          'safeMessage': physicalConfirmation
              ? 'Scanner input detected and physically confirmed.'
              : 'Scanner input detected but physical result was not confirmed.',
          'physicalConfirmation': physicalConfirmation,
          'detectedAt': detectedAt.toIso8601String(),
          'automaticResult': 'inputDetected',
          'scannerEvidence': {
            'scannerMode': state.settings.mode,
            'barcodeLength': barcode.length,
            'barcodeHash': sha256.convert(utf8.encode(barcode)).toString(),
            'eventCount': 1,
            'expectedEventCount': 1,
            'droppedScans': 0,
            'duplicateScans': 0,
            'averageLatencyMs': latency < 0 ? 0 : latency.toDouble(),
            'maximumLatencyMs': latency < 0 ? 0 : latency.toDouble(),
          },
        },
      );
      state = state.copyWith(
        status: physicalConfirmation
            ? BarcodeScannerTestStatus.passed
            : BarcodeScannerTestStatus.failed,
        history: [result, ...state.history],
        clearPendingOperation: true,
        clearDetectedBarcode: true,
        clearDetectedAt: true,
        message: physicalConfirmation
            ? 'Scanner hardware test passed.'
            : 'Scanner hardware test failed physical confirmation.',
      );
    } on PosHardwareApiException catch (error) {
      state = state.copyWith(
        status: BarcodeScannerTestStatus.backendUnavailable,
        message: 'Scan detected, but audit submission failed: ${error.message}',
      );
    }
  }

  Future<void> finalizeFailure({
    required String category,
    required String message,
  }) async {
    final operation = state.pendingOperation;
    if (operation == null) return;
    final now = DateTime.now().toUtc();
    state = state.copyWith(
      status: BarcodeScannerTestStatus.finalizing,
      message: message,
    );
    try {
      final result = await ref.read(posHardwareRepositoryProvider).submitResult(
        operation.testId,
        {
          'status': 'Failed',
          'resultCategory': category,
          'safeMessage': message,
          'physicalConfirmation': false,
          'detectedAt': now.toIso8601String(),
          'automaticResult': category,
          'scannerEvidence': {
            'scannerMode': state.settings.mode,
            'barcodeLength': 0,
            'barcodeHash': null,
            'eventCount': 0,
            'expectedEventCount': 1,
            'droppedScans': 1,
            'duplicateScans': 0,
            'averageLatencyMs': null,
            'maximumLatencyMs': null,
          },
        },
      );
      state = state.copyWith(
        status: BarcodeScannerTestStatus.failed,
        history: [result, ...state.history],
        clearPendingOperation: true,
        clearDetectedBarcode: true,
        clearDetectedAt: true,
        message: message,
      );
    } on PosHardwareApiException catch (error) {
      state = state.copyWith(
        status: BarcodeScannerTestStatus.backendUnavailable,
        message: 'Scanner failed and audit submission failed: ${error.message}',
      );
    }
  }

  void cancelListening() {
    state = state.copyWith(
      status: BarcodeScannerTestStatus.ready,
      clearPendingOperation: true,
      clearDetectedBarcode: true,
      clearDetectedAt: true,
      message: 'Scanner test cancelled locally.',
    );
  }

  String _newUuid() {
    final bytes = List<int>.generate(16, (_) => _random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    final hex =
        bytes.map((value) => value.toRadixString(16).padLeft(2, '0')).join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
        '${hex.substring(12, 16)}-${hex.substring(16, 20)}-'
        '${hex.substring(20)}';
  }
}

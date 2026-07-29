import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/network/dio_provider.dart';
import '../../../../device_activation/presentation/providers/device_activation_provider.dart';
import '../../../../pos_shell/presentation/providers/pos_home_dashboard_provider.dart';
import '../../../device_configuration/data/pos_hardware_remote_datasource.dart';
import '../../../device_configuration/models/pos_hardware_models.dart';
import '../../../device_configuration/repositories/pos_hardware_repository.dart';
import '../../adapters/local_print_agent_adapter.dart';
import '../../clients/local_print_agent_client.dart';
import '../../config/local_print_agent_config.dart';
import '../../config/pos_device_printer_config_store.dart';
import '../../models/local_print_agent_models.dart';
import '../../models/pos_device_printer_config.dart';
import '../../testing/local_print_agent_test_receipt.dart';

enum LocalPrintAgentUiStatus {
  notConfigured,
  idle,
  saving,
  checking,
  reachable,
  printerReady,
  printerOffline,
  unreachable,
  authenticationFailed,
  invalidResponse,
  printing,
  printSuccessful,
  printFailed,
}

LocalPrintAgentUiStatus localPrintAgentStatusForFailure(
  LocalPrintAgentFailureType type, {
  bool printing = false,
}) {
  return switch (type) {
    LocalPrintAgentFailureType.authentication =>
      LocalPrintAgentUiStatus.authenticationFailed,
    LocalPrintAgentFailureType.printerUnavailable =>
      LocalPrintAgentUiStatus.printerOffline,
    LocalPrintAgentFailureType.unreachable ||
    LocalPrintAgentFailureType.timeout =>
      LocalPrintAgentUiStatus.unreachable,
    LocalPrintAgentFailureType.invalidResponse => printing
        ? LocalPrintAgentUiStatus.printFailed
        : LocalPrintAgentUiStatus.invalidResponse,
    _ => printing
        ? LocalPrintAgentUiStatus.printFailed
        : LocalPrintAgentUiStatus.unreachable,
  };
}

LocalPrintAgentUiStatus localPrintAgentStatusForHealth(
  LocalPrintAgentHealth health,
) {
  if (!health.printerExists) return LocalPrintAgentUiStatus.reachable;
  return health.printerReady
      ? LocalPrintAgentUiStatus.printerReady
      : LocalPrintAgentUiStatus.printerOffline;
}

class LocalPrintAgentState {
  const LocalPrintAgentState({
    this.config,
    this.status = LocalPrintAgentUiStatus.notConfigured,
    this.message = 'Local Print Agent is not configured.',
    this.health,
    this.authoritativeConfiguration,
    this.testHistory = const [],
    this.pendingPhysicalTest,
    this.backendAvailable = true,
  });

  final PosDevicePrinterConfig? config;
  final LocalPrintAgentUiStatus status;
  final String message;
  final LocalPrintAgentHealth? health;
  final PosHardwareConfiguration? authoritativeConfiguration;
  final List<HardwareTestOperation> testHistory;
  final HardwareTestOperation? pendingPhysicalTest;
  final bool backendAvailable;

  bool get isBusy =>
      status == LocalPrintAgentUiStatus.saving ||
      status == LocalPrintAgentUiStatus.checking ||
      status == LocalPrintAgentUiStatus.printing;

  LocalPrintAgentState copyWith({
    PosDevicePrinterConfig? config,
    bool configSet = false,
    LocalPrintAgentUiStatus? status,
    String? message,
    LocalPrintAgentHealth? health,
    bool healthSet = false,
    PosHardwareConfiguration? authoritativeConfiguration,
    bool authoritativeConfigurationSet = false,
    List<HardwareTestOperation>? testHistory,
    HardwareTestOperation? pendingPhysicalTest,
    bool pendingPhysicalTestSet = false,
    bool? backendAvailable,
  }) {
    return LocalPrintAgentState(
      config: configSet ? config : this.config,
      status: status ?? this.status,
      message: message ?? this.message,
      health: healthSet ? health : this.health,
      authoritativeConfiguration: authoritativeConfigurationSet
          ? authoritativeConfiguration
          : this.authoritativeConfiguration,
      testHistory: testHistory ?? this.testHistory,
      pendingPhysicalTest: pendingPhysicalTestSet
          ? pendingPhysicalTest
          : this.pendingPhysicalTest,
      backendAvailable: backendAvailable ?? this.backendAvailable,
    );
  }
}

final localPrintAgentClientProvider = Provider<LocalPrintAgentClient>((ref) {
  return LocalPrintAgentClient();
});

final posHardwareRepositoryProvider = Provider<PosHardwareRepository>((ref) {
  return PosHardwareRepository(
    PosHardwareRemoteDatasource(ref.watch(appDioProvider)),
  );
});

final localPrintAgentControllerProvider =
    NotifierProvider<LocalPrintAgentController, LocalPrintAgentState>(
  LocalPrintAgentController.new,
);

PosDevicePrinterConfig mergeLocalPrintAgentConfig({
  required String deviceId,
  required String agentBaseUrl,
  required String apiKey,
  required int timeoutMs,
  required String printerName,
  bool enabled = true,
  PrinterPaperWidth paperWidth = PrinterPaperWidth.mm80,
  bool autoCutEnabled = true,
  int feedLinesBeforeCut = 5,
  bool? printCustomerCopy,
  int? customerCopyCount,
  bool? printMerchantCopy,
  int? merchantCopyCount,
  PosDevicePrinterConfig? existing,
}) {
  final normalizedPrinterName = printerName.trim();
  return PosDevicePrinterConfig(
    deviceId: deviceId,
    enabled: enabled,
    connectionType: PrinterConnectionType.localPrintAgent,
    displayName: normalizedPrinterName.isEmpty
        ? existing?.displayName ?? 'Windows Local Print Agent'
        : normalizedPrinterName,
    paperWidth: paperWidth,
    autoCutEnabled: autoCutEnabled,
    feedLinesBeforeCut: feedLinesBeforeCut,
    connectionTimeoutMs: timeoutMs,
    agentBaseUrl: normalizeLocalPrintAgentUrl(agentBaseUrl),
    localApiKey: apiKey.isEmpty ? existing?.localApiKey : apiKey,
    agentPrinterName: normalizedPrinterName.isEmpty
        ? existing?.agentPrinterName
        : normalizedPrinterName,
    configurationId: existing?.configurationId,
    configurationVersion: existing?.configurationVersion,
    supportedPurposes: existing?.supportedPurposes ??
        const {
          'customerReceipt',
          'merchantReceipt',
          'returnReceipt',
          'exchangeReceipt',
          'refundReceipt',
          'testReceipt',
        },
    printCustomerCopy: printCustomerCopy ?? existing?.printCustomerCopy ?? true,
    customerCopyCount: customerCopyCount ?? existing?.customerCopyCount ?? 1,
    printMerchantCopy:
        printMerchantCopy ?? existing?.printMerchantCopy ?? false,
    merchantCopyCount: merchantCopyCount ?? existing?.merchantCopyCount ?? 0,
  );
}

class LocalPrintAgentController extends Notifier<LocalPrintAgentState> {
  @override
  LocalPrintAgentState build() => const LocalPrintAgentState();

  Future<void> load() async {
    final deviceId = _deviceId;
    if (deviceId.isEmpty) {
      state = const LocalPrintAgentState(
        status: LocalPrintAgentUiStatus.notConfigured,
        message: 'Activate this POS device before configuring a printer.',
      );
      return;
    }
    final localConfig =
        await ref.read(posDevicePrinterConfigStoreProvider).load(deviceId);
    try {
      final configurations = await ref
          .read(posHardwareRepositoryProvider)
          .getConfigurations(deviceId);
      final authoritative = configurations
          .where((item) => item.hardwareType == 'receiptPrinter')
          .firstOrNull;
      final resolved = authoritative == null
          ? localConfig
          : _mergeAuthoritative(authoritative, localConfig);
      final history =
          await ref.read(posHardwareRepositoryProvider).getHistory(deviceId);
      state = LocalPrintAgentState(
        config: resolved,
        authoritativeConfiguration: authoritative,
        testHistory: history,
        status: resolved == null
            ? LocalPrintAgentUiStatus.notConfigured
            : LocalPrintAgentUiStatus.idle,
        message: resolved == null
            ? 'Local Print Agent is not configured.'
            : 'Authoritative device configuration loaded.',
      );
    } on PosHardwareApiException catch (error) {
      state = LocalPrintAgentState(
        config: localConfig,
        backendAvailable: false,
        status: localConfig == null
            ? LocalPrintAgentUiStatus.notConfigured
            : LocalPrintAgentUiStatus.idle,
        message: localConfig == null
            ? error.message
            : 'Backend unavailable. Cached configuration is read-only.',
      );
    }
  }

  Future<List<String>> save({
    required String agentBaseUrl,
    required String apiKey,
    required int timeoutMs,
    required String printerName,
    required bool enabled,
    required PrinterPaperWidth paperWidth,
    required bool autoCutEnabled,
    required int feedLinesBeforeCut,
    required bool printCustomerCopy,
    required int customerCopyCount,
    required bool printMerchantCopy,
    required int merchantCopyCount,
    String? changeReason,
  }) async {
    final existing = state.config ??
        await ref.read(posDevicePrinterConfigStoreProvider).load(_deviceId);
    final config = mergeLocalPrintAgentConfig(
      deviceId: _deviceId,
      agentBaseUrl: normalizeLocalPrintAgentUrl(agentBaseUrl),
      apiKey: apiKey,
      timeoutMs: timeoutMs,
      printerName: printerName,
      enabled: enabled,
      paperWidth: paperWidth,
      autoCutEnabled: autoCutEnabled,
      feedLinesBeforeCut: feedLinesBeforeCut,
      printCustomerCopy: printCustomerCopy,
      customerCopyCount: customerCopyCount,
      printMerchantCopy: printMerchantCopy,
      merchantCopyCount: merchantCopyCount,
      existing: existing,
    );
    final errors = validateLocalPrintAgentConfig(config);
    if (_deviceId.isEmpty) {
      errors.insert(0, 'Activate this POS device before saving.');
    }
    if (errors.isNotEmpty) return errors;

    state = state.copyWith(
      status: LocalPrintAgentUiStatus.saving,
      message: 'Saving secure device configuration…',
    );
    try {
      final context = ref.read(deviceActivationProvider).deviceContext!;
      final authoritative =
          await ref.read(posHardwareRepositoryProvider).saveConfiguration({
        'posDeviceId': context.deviceId,
        'outletId': context.outletId,
        'tillId': context.tillId.isEmpty ? null : context.tillId,
        'hardwareType': 'receiptPrinter',
        'transportType': 'localPrintAgent',
        'displayName': config.displayName,
        'enabled': config.enabled,
        'expectedVersion':
            state.authoritativeConfiguration?.configurationVersion ?? 0,
        'changeReason':
            changeReason?.trim().isEmpty == true ? null : changeReason?.trim(),
        'receiptPrinter': {
          'agentBaseUrl': config.agentBaseUrl,
          'printerName': config.agentPrinterName ?? config.displayName,
          'paperWidth':
              config.paperWidth == PrinterPaperWidth.mm58 ? '58mm' : '80mm',
          'autoCut': config.autoCutEnabled,
          'requestTimeout': config.connectionTimeoutMs,
          'feedBeforeCut': config.feedLinesBeforeCut,
          'localApiKeyPresent': config.localApiKey?.isNotEmpty == true,
          'supportedPurposes': config.supportedPurposes.toList(growable: false),
          'printCustomerCopy': config.printCustomerCopy,
          'customerCopyCount': config.customerCopyCount,
          'printMerchantCopy': config.printMerchantCopy,
          'merchantCopyCount': config.merchantCopyCount,
        },
        'barcodeScanner': null,
        'cashDrawer': null,
        'cardTerminal': null,
      });
      final persistedConfig = _mergeAuthoritative(authoritative, config);
      await ref.read(posDevicePrinterConfigStoreProvider).save(persistedConfig);
      state = LocalPrintAgentState(
        config: persistedConfig,
        authoritativeConfiguration: authoritative,
        testHistory: state.testHistory,
        status: LocalPrintAgentUiStatus.idle,
        message:
            'Configuration version ${authoritative.configurationVersion} saved securely.',
      );
      return const [];
    } on PosHardwareApiException catch (error) {
      state = state.copyWith(
        status: error.code == 'pos_hardware.version_conflict'
            ? LocalPrintAgentUiStatus.invalidResponse
            : LocalPrintAgentUiStatus.unreachable,
        message: error.message,
        backendAvailable: false,
      );
      return [error.message];
    }
  }

  Future<void> checkConnection() async {
    final config = state.config;
    if (config == null) return;
    HardwareTestOperation operation;
    try {
      operation = await _createTest('agentHealth');
    } on PosHardwareApiException catch (error) {
      state = state.copyWith(
        status: LocalPrintAgentUiStatus.unreachable,
        message: error.message,
      );
      return;
    }
    state = state.copyWith(
      status: LocalPrintAgentUiStatus.checking,
      message: 'Checking Local Print Agent…',
      healthSet: true,
    );
    try {
      final health =
          await LocalPrintAgentAdapter(ref.read(localPrintAgentClientProvider))
              .getHealth(config);
      state = state.copyWith(
        status: localPrintAgentStatusForHealth(health),
        message: health.printerReady
            ? 'Agent reachable. Printer is ready.'
            : health.detail ??
                (health.printerExists
                    ? 'Agent reachable, but the printer is offline.'
                    : 'Agent reachable, but the configured printer was not found.'),
        health: health,
        healthSet: true,
      );
      await _submitTestResult(
        operation,
        status: health.printerReady ? 'Passed' : 'Failed',
        category:
            health.printerReady ? 'printer_ready' : 'hardware_unavailable',
        message: health.detail,
        physicalConfirmation: false,
      );
    } on LocalPrintAgentException catch (error) {
      state = state.copyWith(
        status: localPrintAgentStatusForFailure(error.type),
        message: error.message,
        healthSet: true,
      );
      await _submitFailure(operation, error);
    }
  }

  Future<void> printTestReceipt() async {
    final config = state.config;
    if (config == null) return;
    HardwareTestOperation operation;
    try {
      operation = await _createTest('testPrint');
    } on PosHardwareApiException catch (error) {
      state = state.copyWith(
        status: LocalPrintAgentUiStatus.unreachable,
        message: error.message,
      );
      return;
    }
    state = state.copyWith(
      status: LocalPrintAgentUiStatus.printing,
      message: 'Sending printer test…',
    );
    try {
      final dashboard = ref.read(posHomeDashboardProvider).asData?.value;
      final request = const LocalPrintAgentTestReceiptBuilder().build(
        merchantName: dashboard?.businessDisplayName ?? 'TM-EPOS',
        outletName: dashboard?.outletName,
        tillName: dashboard?.tillDisplayLabel,
        cashierName: dashboard?.fallbackUserDisplayName,
      );
      await LocalPrintAgentAdapter(ref.read(localPrintAgentClientProvider))
          .printStructuredReceipt(config, request);
      state = state.copyWith(
        status: LocalPrintAgentUiStatus.printSuccessful,
        message:
            'Test submitted to the Windows spooler. Confirm the physical paper output.',
        pendingPhysicalTest: operation,
        pendingPhysicalTestSet: true,
      );
    } on LocalPrintAgentException catch (error) {
      state = state.copyWith(
        status: localPrintAgentStatusForFailure(error.type, printing: true),
        message: error.message,
      );
      await _submitFailure(operation, error);
    }
  }

  Future<void> confirmPhysicalPrint(bool printed) async {
    final operation = state.pendingPhysicalTest;
    if (operation == null) return;
    await _submitTestResult(
      operation,
      status: printed ? 'Passed' : 'Failed',
      category: printed ? 'test_print_submitted' : 'test_print_failed',
      message: printed
          ? 'Operator confirmed physical test receipt output.'
          : 'Operator confirmed no complete physical test receipt output.',
      physicalConfirmation: printed,
    );
    state = state.copyWith(
      status: printed
          ? LocalPrintAgentUiStatus.printSuccessful
          : LocalPrintAgentUiStatus.printFailed,
      message: printed
          ? 'Physical printer test confirmed and audited.'
          : 'Physical printer test failed and was audited.',
      pendingPhysicalTestSet: true,
    );
  }

  Future<HardwareTestOperation> _createTest(String testType) async {
    final context = ref.read(deviceActivationProvider).deviceContext!;
    return ref.read(posHardwareRepositoryProvider).createTest({
      'requestId': _uuidV4(),
      'posDeviceId': context.deviceId,
      'tillId': context.tillId.isEmpty ? null : context.tillId,
      'hardwareConfigurationId':
          state.authoritativeConfiguration?.configurationId,
      'hardwareType': 'receiptPrinter',
      'testType': testType,
      'configurationVersion':
          state.authoritativeConfiguration?.configurationVersion ?? 0,
    });
  }

  Future<void> _submitFailure(
    HardwareTestOperation operation,
    LocalPrintAgentException error,
  ) async {
    final category = switch (error.type) {
      LocalPrintAgentFailureType.timeout => 'timeout',
      LocalPrintAgentFailureType.authentication => 'unauthorized',
      LocalPrintAgentFailureType.printerUnavailable => 'hardware_unavailable',
      _ => 'unknown',
    };
    await _submitTestResult(
      operation,
      status: error.type == LocalPrintAgentFailureType.timeout
          ? 'Unknown'
          : 'Failed',
      category: category,
      message: error.message,
      physicalConfirmation: false,
    );
  }

  Future<void> _submitTestResult(
    HardwareTestOperation operation, {
    required String status,
    required String category,
    required String? message,
    required bool? physicalConfirmation,
  }) async {
    try {
      final completed =
          await ref.read(posHardwareRepositoryProvider).submitResult(
        operation.testId,
        {
          'status': status,
          'resultCategory': category,
          'safeMessage': message,
          'physicalConfirmation': physicalConfirmation,
        },
      );
      state = state.copyWith(testHistory: [
        completed,
        ...state.testHistory.where((item) => item.testId != completed.testId),
      ]);
    } on PosHardwareApiException catch (error) {
      state = state.copyWith(
        status: LocalPrintAgentUiStatus.invalidResponse,
        message:
            'Physical action was not repeated. Audit submission failed: ${error.message}',
      );
    }
  }

  PosDevicePrinterConfig _mergeAuthoritative(
    PosHardwareConfiguration authoritative,
    PosDevicePrinterConfig? local,
  ) {
    final settings = authoritative.settings;
    return PosDevicePrinterConfig(
      deviceId: authoritative.posDeviceId,
      enabled: authoritative.enabled,
      connectionType: PrinterConnectionType.localPrintAgent,
      displayName: authoritative.displayName,
      paperWidth: settings['paperWidth']?.toString() == '58mm'
          ? PrinterPaperWidth.mm58
          : PrinterPaperWidth.mm80,
      autoCutEnabled: settings['autoCut'] != false,
      feedLinesBeforeCut: _readInt(settings['feedBeforeCut'], 5),
      connectionTimeoutMs: _readInt(settings['requestTimeout'], 5000),
      agentBaseUrl: settings['agentBaseUrl']?.toString(),
      localApiKey: local?.localApiKey,
      agentPrinterName: settings['printerName']?.toString(),
      configurationId: authoritative.configurationId,
      configurationVersion: authoritative.configurationVersion,
      supportedPurposes: (settings['supportedPurposes'] is List)
          ? (settings['supportedPurposes'] as List)
              .map((item) => item.toString())
              .toSet()
          : const {
              'customerReceipt',
              'merchantReceipt',
              'returnReceipt',
              'exchangeReceipt',
              'refundReceipt',
              'testReceipt',
            },
      printCustomerCopy: settings['printCustomerCopy'] != false,
      customerCopyCount: _readInt(settings['customerCopyCount'], 1).clamp(0, 5),
      printMerchantCopy: settings['printMerchantCopy'] == true,
      merchantCopyCount: _readInt(settings['merchantCopyCount'], 0).clamp(0, 5),
    );
  }

  String get _deviceId =>
      ref.read(deviceActivationProvider).deviceContext?.deviceId.trim() ?? '';
}

int _readInt(Object? value, int fallback) =>
    value is num ? value.toInt() : int.tryParse('$value') ?? fallback;

String _uuidV4() {
  final random = Random.secure();
  final bytes = List<int>.generate(16, (_) => random.nextInt(256));
  bytes[6] = (bytes[6] & 0x0f) | 0x40;
  bytes[8] = (bytes[8] & 0x3f) | 0x80;
  final hex =
      bytes.map((value) => value.toRadixString(16).padLeft(2, '0')).join();
  return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
      '${hex.substring(12, 16)}-${hex.substring(16, 20)}-'
      '${hex.substring(20)}';
}

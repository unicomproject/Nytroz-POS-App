import 'dart:math' as math;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';

import '../../../../../core/network/api_endpoints.dart';
import '../../../../../core/network/dio_provider.dart';
import '../../../../device_activation/presentation/providers/device_activation_provider.dart';
import '../../../device_configuration/models/pos_hardware_models.dart';
import '../../config/pos_device_printer_config_store.dart';
import '../../models/local_print_agent_models.dart';
import '../../recovery/drawer_operation.dart';
import '../../recovery/drawer_operation_store.dart';
import 'dart:developer' as developer;
import 'local_print_agent_controller.dart';

enum CashDrawerUiStatus {
  notConfigured,
  idle,
  loading,
  saving,
  registering,
  opening,
  agentAccepted,
  awaitingPhysicalConfirmation,
  success,
  failed,
  unknown,
  error,
}

class CashDrawerState {
  const CashDrawerState({
    this.config,
    this.status = CashDrawerUiStatus.notConfigured,
    this.message = 'Cash drawer is not configured.',
    this.authoritativeConfiguration,
    this.testHistory = const [],
    this.drawerHistory = const [],
    this.activeTest,
    this.activeDrawerOpId,
    this.recoveryOperations = const [],
  });

  final PosCashDrawerConfiguration? config;
  final CashDrawerUiStatus status;
  final String message;
  final PosHardwareConfiguration? authoritativeConfiguration;
  final List<HardwareTestOperation> testHistory;
  final List<Map<String, dynamic>> drawerHistory;
  final HardwareTestOperation? activeTest;
  final String? activeDrawerOpId;
  final List<DrawerOperation> recoveryOperations;

  bool get isBusy =>
      status == CashDrawerUiStatus.loading ||
      status == CashDrawerUiStatus.saving ||
      status == CashDrawerUiStatus.registering ||
      status == CashDrawerUiStatus.opening;

  CashDrawerState copyWith({
    PosCashDrawerConfiguration? config,
    bool configSet = false,
    CashDrawerUiStatus? status,
    String? message,
    PosHardwareConfiguration? authoritativeConfiguration,
    bool authoritativeConfigurationSet = false,
    List<HardwareTestOperation>? testHistory,
    List<Map<String, dynamic>>? drawerHistory,
    HardwareTestOperation? activeTest,
    bool activeTestSet = false,
    String? activeDrawerOpId,
    bool activeDrawerOpIdSet = false,
    List<DrawerOperation>? recoveryOperations,
  }) {
    return CashDrawerState(
      config: configSet ? config : this.config,
      status: status ?? this.status,
      message: message ?? this.message,
      authoritativeConfiguration: authoritativeConfigurationSet
          ? authoritativeConfiguration
          : this.authoritativeConfiguration,
      testHistory: testHistory ?? this.testHistory,
      drawerHistory: drawerHistory ?? this.drawerHistory,
      activeTest: activeTestSet ? activeTest : this.activeTest,
      activeDrawerOpId:
          activeDrawerOpIdSet ? activeDrawerOpId : this.activeDrawerOpId,
      recoveryOperations: recoveryOperations ?? this.recoveryOperations,
    );
  }
}

class CashDrawerController extends Notifier<CashDrawerState> {
  String get _deviceId =>
      ref.read(deviceActivationProvider).deviceContext?.deviceId.trim() ?? '';

  @override
  CashDrawerState build() {
    return const CashDrawerState();
  }

  Future<void> load() async {
    if (_deviceId.isEmpty) {
      state = state.copyWith(
        status: CashDrawerUiStatus.notConfigured,
        message: 'Activate this POS device first.',
      );
      return;
    }

    state = state.copyWith(
        status: CashDrawerUiStatus.loading,
        message: 'Loading cash drawer settings…');

    try {
      final repo = ref.read(posHardwareRepositoryProvider);
      final configs = await repo.getConfigurations(_deviceId);
      final authoritative = configs.firstWhere(
        (x) => x.hardwareType == 'cashDrawer',
        orElse: () => throw const PosHardwareApiException(
            'not_configured', 'Cash drawer configuration missing'),
      );

      final drawerConfig =
          PosCashDrawerConfiguration.fromHardware(authoritative);

      // Load histories
      final testHistory = await repo.getHistory(_deviceId);
      final drawerHistory = await _getDrawerHistory();
      final recoveryOps = await ref.read(drawerOperationStoreProvider).load();

      state = CashDrawerState(
        config: drawerConfig,
        authoritativeConfiguration: authoritative,
        testHistory:
            testHistory.where((x) => x.hardwareType == 'cashDrawer').toList(),
        drawerHistory: drawerHistory,
        recoveryOperations: recoveryOps,
        status: authoritative.enabled
            ? CashDrawerUiStatus.idle
            : CashDrawerUiStatus.notConfigured,
        message: authoritative.enabled
            ? 'Cash drawer is ready.'
            : 'Cash drawer is disabled.',
      );
    } on PosHardwareApiException catch (e) {
      if (e.code == 'not_configured') {
        state = const CashDrawerState(
          status: CashDrawerUiStatus.notConfigured,
          message: 'Cash drawer is not configured.',
        );
      } else {
        state = CashDrawerState(
          status: CashDrawerUiStatus.error,
          message: e.message,
        );
      }
    } catch (e) {
      state = CashDrawerState(
        status: CashDrawerUiStatus.error,
        message: 'Failed to load cash drawer config: $e',
      );
    }
  }

  Future<List<String>> save({
    required String? linkedReceiptPrinterId,
    required String drawerPort,
    required int pulseOnMilliseconds,
    required int pulseOffMilliseconds,
    required String policy,
    required bool openOnCashSale,
    required bool openOnCashRefund,
    required bool openOnCashSplit,
    required bool manualOpenEnabled,
    required bool enabled,
    String? changeReason,
  }) async {
    final errors = <String>[];
    if (_deviceId.isEmpty) {
      errors.add('Activate this POS device before saving.');
      return errors;
    }
    if (linkedReceiptPrinterId == null || linkedReceiptPrinterId.isEmpty) {
      errors.add('A linked receipt printer is required.');
    }
    if (drawerPort != 'drawerPin2' && drawerPort != 'drawerPin5') {
      errors.add('Invalid drawer port.');
    }
    if (pulseOnMilliseconds < 2 || pulseOnMilliseconds > 510) {
      errors.add('Pulse ON duration must be between 2 and 510 ms.');
    }
    if (pulseOffMilliseconds < 2 || pulseOffMilliseconds > 510) {
      errors.add('Pulse OFF duration must be between 2 and 510 ms.');
    }
    if (errors.isNotEmpty) return errors;

    state = state.copyWith(
        status: CashDrawerUiStatus.saving,
        message: 'Saving cash drawer settings…');

    try {
      final context = ref.read(deviceActivationProvider).deviceContext!;
      final repo = ref.read(posHardwareRepositoryProvider);

      final authoritative = await repo.saveConfiguration({
        'posDeviceId': context.deviceId,
        'outletId': context.outletId,
        'tillId': context.tillId.isEmpty ? null : context.tillId,
        'hardwareType': 'cashDrawer',
        'transportType': 'localPrintAgent',
        'displayName': 'RJ11 Cash Drawer',
        'enabled': enabled,
        'expectedVersion':
            state.authoritativeConfiguration?.configurationVersion ?? 0,
        'changeReason':
            changeReason?.trim().isEmpty == true ? null : changeReason?.trim(),
        'receiptPrinter': null,
        'barcodeScanner': null,
        'cashDrawer': {
          'linkedReceiptPrinterId': linkedReceiptPrinterId,
          'drawerPort': drawerPort,
          'pulseOnMilliseconds': pulseOnMilliseconds,
          'pulseOffMilliseconds': pulseOffMilliseconds,
          'policy': policy,
          'openOnCashSale': openOnCashSale,
          'openOnCashRefund': openOnCashRefund,
          'openOnCashSplit': openOnCashSplit,
          'manualOpenEnabled': manualOpenEnabled,
        },
        'cardTerminal': null,
      });

      final drawerConfig =
          PosCashDrawerConfiguration.fromHardware(authoritative);

      state = state.copyWith(
        config: drawerConfig,
        authoritativeConfiguration: authoritative,
        status: enabled
            ? CashDrawerUiStatus.idle
            : CashDrawerUiStatus.notConfigured,
        message: enabled
            ? 'Cash drawer configuration saved successfully.'
            : 'Cash drawer disabled.',
      );
      await load();
    } catch (e) {
      state = state.copyWith(
        status: CashDrawerUiStatus.error,
        message: 'Failed to save configuration: $e',
      );
      errors.add(e.toString());
    }
    return errors;
  }

  Future<void> testPulse() async {
    final config = state.config;
    if (config == null || !config.enabled) {
      state = state.copyWith(
          status: CashDrawerUiStatus.error,
          message: 'Cash drawer is not configured or disabled.');
      return;
    }

    state = state.copyWith(
      status: CashDrawerUiStatus.registering,
      message: 'Registering test operation…',
    );

    try {
      // 1. Create Hardware Test Operation in backend
      final repo = ref.read(posHardwareRepositoryProvider);
      final testOp = await repo.createTest({
        'posDeviceId': _deviceId,
        'hardwareType': 'cashDrawer',
        'testType': 'drawerPulse',
      });

      // 2. Register Drawer Operation in backend
      final dio = ref.read(appDioProvider);
      final registerRes = await dio.post<Map<String, dynamic>>(
        ApiEndpoints.posDrawerOperations,
        data: {
          'requestId': testOp.requestId,
          'posDeviceId': _deviceId,
          'drawerPurpose': 'hardwareTest',
          'reason': 'Hardware test pulse',
        },
      );

      final drawerOp = registerRes.data?['data'] as Map<String, dynamic>;
      final drawerOpId = drawerOp['operationId']?.toString() ?? '';

      state = state.copyWith(
        status: CashDrawerUiStatus.opening,
        message: 'Sending pulse to Local Print Agent…',
        activeTest: testOp,
        activeDrawerOpId: drawerOpId,
        activeTestSet: true,
        activeDrawerOpIdSet: true,
      );

      // 3. Load linked printer config to get Agent URL/Key
      final printerConfig =
          await ref.read(posDevicePrinterConfigStoreProvider).load(_deviceId);
      if (printerConfig == null ||
          printerConfig.agentBaseUrl == null ||
          printerConfig.localApiKey == null) {
        throw Exception(
            'Linked printer is not configured or missing Agent URL/Key.');
      }

      // 4. Pulse the drawer via Local Print Agent client
      final client = ref.read(localPrintAgentClientProvider);
      await client.openDrawer(
        printerConfig,
        LocalPrintAgentDrawerOpenRequest(
          requestId: testOp.requestId,
          drawerOperationId: drawerOpId,
          purpose: LocalPrintAgentDrawerPurpose.hardwareTest,
          printerName: printerConfig.agentPrinterName ?? 'POSPrinter',
          drawerPort: config.drawerPort,
          pulseOnMilliseconds: config.pulseOnMilliseconds,
          pulseOffMilliseconds: config.pulseOffMilliseconds,
          configurationId: state.authoritativeConfiguration?.configurationId,
          configurationVersion:
              state.authoritativeConfiguration?.configurationVersion,
          posDeviceId: _deviceId,
        ),
      );

      state = state.copyWith(
        status: CashDrawerUiStatus.agentAccepted,
        message: 'Agent accepted request. Did the drawer physically open?',
      );

      // 5. Finalize Cash Drawer Operation on backend
      await dio.put<dynamic>(
        ApiEndpoints.posDrawerFinalize(drawerOpId),
        data: {
          'status': 'OPENED',
          'resultCategory': 'SUCCESS',
          'agentAccepted': true,
          'physicalConfirmation': null,
        },
      );

      state = state.copyWith(
        status: CashDrawerUiStatus.awaitingPhysicalConfirmation,
        message: 'Awaiting user physical confirmation…',
      );
    } catch (e) {
      state = state.copyWith(
        status: CashDrawerUiStatus.error,
        message: 'Test pulse failed: $e',
      );
    }
  }

  Future<void> _persist(DrawerOperation operation) async {
    await ref.read(drawerOperationStoreProvider).upsert(operation);
    final list = await ref.read(drawerOperationStoreProvider).load();
    state = state.copyWith(recoveryOperations: list);
  }

  DrawerOperationState _durableFailureState(Object error) {
    if (error is LocalPrintAgentException &&
        (error.type == LocalPrintAgentFailureType.timeout ||
            error.type == LocalPrintAgentFailureType.unknown)) {
      return DrawerOperationState.unknown;
    }
    return DrawerOperationState.failed;
  }

  String _safeFailureCategory(Object? error) {
    if (error is LocalPrintAgentException) return error.type.name;
    return error == null ? 'none' : 'unknown';
  }

  String _messageFor(Object? error) {
    if (error is LocalPrintAgentException) return error.message;
    return error?.toString() ?? 'Drawer pulse failed.';
  }

  Future<void> confirmPhysicalOpen(bool success) async {
    final activeTest = state.activeTest;
    final drawerOpId = state.activeDrawerOpId;

    if (activeTest == null || drawerOpId == null) {
      state = state.copyWith(
          status: CashDrawerUiStatus.error,
          message: 'No active test operation to confirm.');
      return;
    }

    try {
      final repo = ref.read(posHardwareRepositoryProvider);
      final dio = ref.read(appDioProvider);

      // 1. Submit final drawer operation physical status
      await dio.put<dynamic>(
        ApiEndpoints.posDrawerFinalize(drawerOpId),
        data: {
          'status': success ? 'OPENED' : 'FAILED',
          'resultCategory': success ? 'SUCCESS' : 'FAILED',
          'agentAccepted': true,
          'physicalConfirmation': success,
        },
      );

      // 2. Submit hardware test log result
      await repo.submitResult(activeTest.testId, {
        'status': success ? 'PASSED' : 'FAILED',
        'resultCategory': success ? 'SUCCESS' : 'FAILURE',
        'safeMessage':
            success ? 'Physical open confirmed.' : 'Physical open failed.',
        'physicalConfirmation': success,
      });

      state = state.copyWith(
        status:
            success ? CashDrawerUiStatus.success : CashDrawerUiStatus.failed,
        message: success ? 'Hardware test passed!' : 'Hardware test failed.',
        activeTestSet: true,
        activeDrawerOpIdSet: true,
      );

      await load();
    } catch (e) {
      state = state.copyWith(
        status: CashDrawerUiStatus.error,
        message: 'Failed to submit physical confirmation: $e',
      );
    }
  }

  Future<void> confirmRecoveryOpen(String operationId, bool success) async {
    try {
      final store = ref.read(drawerOperationStoreProvider);
      final ops = await store.load();
      final index = ops.indexWhere((x) => x.operationId == operationId);
      if (index < 0) return;

      var op = ops[index];
      op = op.copyWith(
        state:
            success ? DrawerOperationState.opened : DrawerOperationState.failed,
        physicalAttemptCount: op.physicalAttemptCount + 1,
      );
      await _persist(op);

      final dio = ref.read(appDioProvider);
      await dio.put<dynamic>(
        ApiEndpoints.posDrawerFinalize(operationId),
        data: {
          'status': success ? 'OPENED' : 'FAILED',
          'resultCategory': success ? 'SUCCESS' : 'FAILED',
          'agentAccepted': success,
          'physicalConfirmation': success,
        },
      );

      await load();
    } catch (e) {
      developer.log('Failed to confirm recovery open: $e', name: 'pos.drawer');
    }
  }

  Future<bool> triggerManualNoSaleOpen({
    required String reason,
    String? managerEmail,
    String? managerPassword,
  }) async {
    state = state.copyWith(
        status: CashDrawerUiStatus.registering,
        message: 'Requesting manual no-sale open…');

    try {
      final dio = ref.read(appDioProvider);
      final requestId = GuidGenerator.generate();

      final response = await dio.post<Map<String, dynamic>>(
        '${ApiEndpoints.posDrawerOperations}/manual-open',
        data: {
          'requestId': requestId,
          'posDeviceId': _deviceId,
          'reason': reason,
          'managerEmail': managerEmail,
          'managerPassword': managerPassword,
        },
      );

      final drawerOp = response.data?['data'] as Map<String, dynamic>;
      final drawerOpId = drawerOp['operationId']?.toString() ?? '';

      state = state.copyWith(
          status: CashDrawerUiStatus.opening, message: 'Opening drawer…');

      // Load printer config
      final printerConfig =
          await ref.read(posDevicePrinterConfigStoreProvider).load(_deviceId);
      final config = state.config;

      if (config == null ||
          printerConfig == null ||
          printerConfig.agentBaseUrl == null ||
          printerConfig.localApiKey == null) {
        throw Exception(
            'Receipt printer or cash drawer configuration missing.');
      }

      var operation = DrawerOperation(
        operationId: drawerOpId,
        requestId: requestId,
        posDeviceId: _deviceId,
        drawerPurpose: 'manualNoSale',
        state: DrawerOperationState.opening,
        createdAt: DateTime.now().toUtc(),
        updatedAt: DateTime.now().toUtc(),
        reason: reason,
        drawerPort: config.drawerPort,
        pulseOnMilliseconds: config.pulseOnMilliseconds,
        pulseOffMilliseconds: config.pulseOffMilliseconds,
      );
      await _persist(operation);

      // Pulse drawer via Print Agent
      final client = ref.read(localPrintAgentClientProvider);
      await client.openDrawer(
        printerConfig,
        LocalPrintAgentDrawerOpenRequest(
          requestId: requestId,
          drawerOperationId: drawerOpId,
          purpose: LocalPrintAgentDrawerPurpose.manualNoSale,
          printerName: printerConfig.agentPrinterName ?? 'POSPrinter',
          drawerPort: config.drawerPort,
          pulseOnMilliseconds: config.pulseOnMilliseconds,
          pulseOffMilliseconds: config.pulseOffMilliseconds,
          configurationId: state.authoritativeConfiguration?.configurationId,
          configurationVersion:
              state.authoritativeConfiguration?.configurationVersion,
          posDeviceId: _deviceId,
        ),
      );

      operation = operation.copyWith(state: DrawerOperationState.opened);
      await _persist(operation);

      // Finalize Cash Drawer Operation on backend
      await dio.put<dynamic>(
        ApiEndpoints.posDrawerFinalize(drawerOpId),
        data: {
          'status': 'OPENED',
          'resultCategory': 'SUCCESS',
          'agentAccepted': true,
          'physicalConfirmation': true,
        },
      );

      state = state.copyWith(
          status: CashDrawerUiStatus.success,
          message: 'Drawer opened successfully.');
      await load();
      return true;
    } on DioException catch (e) {
      final body = e.response?.data;
      final map = body is Map ? Map<String, dynamic>.from(body) : const {};
      final message = map['message']?.toString() ?? 'Failed to open drawer: $e';
      state =
          state.copyWith(status: CashDrawerUiStatus.error, message: message);
      return false;
    } catch (e) {
      state = state.copyWith(
          status: CashDrawerUiStatus.error,
          message: 'Failed to open drawer: $e');
      return false;
    }
  }

  // Trigger auto-open drawer for completed cash checkout
  Future<void> triggerAutoOpenForCheckout({
    required String drawerOperationId,
    required String purposeStr,
    required Map<String, dynamic> drawerSettingsJson,
    required String businessReferenceId,
  }) async {
    final store = ref.read(drawerOperationStoreProvider);
    final existing =
        (await store.load()).where((x) => x.operationId == drawerOperationId);
    if (existing.isNotEmpty) {
      final localState = existing.first.state;
      if (localState == DrawerOperationState.opened ||
          localState == DrawerOperationState.cancelled ||
          localState == DrawerOperationState.unknown) {
        developer.log(
            'Cash drawer auto-trigger already processed. operationId=$drawerOperationId, state=${localState.name}',
            name: 'pos.drawer');
        return;
      }
    }

    final purpose = LocalPrintAgentDrawerPurpose.values.firstWhere(
      (x) => x.name == purposeStr,
      orElse: () => LocalPrintAgentDrawerPurpose.cashSale,
    );

    final drawerPort =
        drawerSettingsJson['drawerPort']?.toString() ?? 'drawerPin2';
    final pulseOn = drawerSettingsJson['pulseOnMilliseconds'] is num
        ? (drawerSettingsJson['pulseOnMilliseconds'] as num).toInt()
        : 100;
    final pulseOff = drawerSettingsJson['pulseOffMilliseconds'] is num
        ? (drawerSettingsJson['pulseOffMilliseconds'] as num).toInt()
        : 200;

    var operation = DrawerOperation(
      operationId: drawerOperationId,
      requestId: drawerOperationId, // Idempotent!
      posDeviceId: _deviceId,
      drawerPurpose: purposeStr,
      state: DrawerOperationState.opening,
      createdAt: DateTime.now().toUtc(),
      updatedAt: DateTime.now().toUtc(),
      businessReferenceId: businessReferenceId,
      drawerPort: drawerPort,
      pulseOnMilliseconds: pulseOn,
      pulseOffMilliseconds: pulseOff,
    );
    await _persist(operation);

    try {
      final printerConfig =
          await ref.read(posDevicePrinterConfigStoreProvider).load(_deviceId);
      if (printerConfig == null ||
          printerConfig.agentBaseUrl == null ||
          printerConfig.localApiKey == null) {
        throw const LocalPrintAgentException(
          LocalPrintAgentFailureType.invalidConfiguration,
          'Receipt printer or cash drawer configuration missing.',
        );
      }

      final client = ref.read(localPrintAgentClientProvider);
      await client.openDrawer(
        printerConfig,
        LocalPrintAgentDrawerOpenRequest(
          requestId: drawerOperationId, // Idempotent!
          drawerOperationId: drawerOperationId,
          purpose: purpose,
          printerName: printerConfig.agentPrinterName ?? 'POSPrinter',
          drawerPort: drawerPort,
          pulseOnMilliseconds: pulseOn,
          pulseOffMilliseconds: pulseOff,
          posDeviceId: _deviceId,
        ),
      );

      operation = operation.copyWith(state: DrawerOperationState.opened);
      await _persist(operation);

      final dio = ref.read(appDioProvider);
      await dio.put<dynamic>(
        ApiEndpoints.posDrawerFinalize(drawerOperationId),
        data: {
          'status': 'OPENED',
          'resultCategory': 'SUCCESS',
          'agentAccepted': true,
          'physicalConfirmation': true,
        },
      );
    } catch (error) {
      final failureState = _durableFailureState(error);
      operation = operation.copyWith(
        state: failureState,
        failureCategory: _safeFailureCategory(error),
        failureMessage: _messageFor(error),
      );
      await _persist(operation);

      // Finalize on backend if possible
      try {
        final dio = ref.read(appDioProvider);
        await dio.put<dynamic>(
          ApiEndpoints.posDrawerFinalize(drawerOperationId),
          data: {
            'status': failureState == DrawerOperationState.unknown
                ? 'UNKNOWN'
                : 'FAILED',
            'resultCategory': 'FAILED',
            'agentAccepted': false,
            'physicalConfirmation': null,
            'failureCategory': operation.failureCategory,
          },
        );
      } catch (_) {
        // Ignore backend finalization API failure, sale remains complete.
      }
    }
  }

  Future<List<Map<String, dynamic>>> _getDrawerHistory() async {
    try {
      final dio = ref.read(appDioProvider);
      final response = await dio.get<Map<String, dynamic>>(
        ApiEndpoints.posDrawerHistory,
        queryParameters: {'posDeviceId': _deviceId, 'take': 25},
      );
      final data = response.data?['data'];
      return data is List
          ? data.map((x) => Map<String, dynamic>.from(x as Map)).toList()
          : const [];
    } catch (_) {
      return const [];
    }
  }
}

final cashDrawerControllerProvider =
    NotifierProvider<CashDrawerController, CashDrawerState>(
  CashDrawerController.new,
);

class GuidGenerator {
  static String generate() {
    final random = math.Random();
    final bytes = List<int>.generate(16, (i) => random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40; // Version 4
    bytes[8] = (bytes[8] & 0x3f) | 0x80; // Variant is 10xxxxxx
    return bytes
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join()
        .replaceFirst(
            RegExp(r'^(.{8})(.{4})(.{4})(.{4})(.{12})$'), r'$1-$2-$3-$4-$5');
  }
}

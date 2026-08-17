import 'dart:math' as math;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';

import '../../../../../core/network/api_endpoints.dart';
import '../../../../../core/network/dio_provider.dart';
import '../../../../device_activation/presentation/providers/device_activation_provider.dart';
import '../../../device_configuration/models/pos_hardware_models.dart';
import '../../config/pos_device_printer_config_store.dart';
import '../../models/local_print_agent_models.dart';
import '../../models/pos_device_printer_config.dart';
import '../../models/printer_exception.dart';
import '../../recovery/drawer_operation.dart';
import '../../recovery/drawer_operation_store.dart';
import '../../transports/cash_drawer_transport.dart';
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
  final Set<String> _inFlightAutoOpenIds = <String>{};

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
      final config = state.config;
      final authoritative = state.authoritativeConfiguration;
      if (config == null || authoritative == null) {
        state = state.copyWith(
          status: CashDrawerUiStatus.error,
          message:
              'Save an authoritative cash drawer configuration before testing.',
        );
        return;
      }

      // 1. Create Hardware Test Operation in backend (typed contract)
      final repo = ref.read(posHardwareRepositoryProvider);
      final testRequestId = GuidGenerator.generate();
      final testOp = await repo.createTest({
        'requestId': testRequestId,
        'posDeviceId': _deviceId,
        'hardwareConfigurationId': authoritative.configurationId,
        'hardwareType': 'cashDrawer',
        'testType': 'drawerPulse',
        'configurationVersion': authoritative.configurationVersion,
      });

      // 2. Register Drawer Operation in backend (non-financial hardwareTest)
      final dio = ref.read(appDioProvider);
      Map<String, dynamic>? drawerOp;
      try {
        final registerRes = await dio.post<Map<String, dynamic>>(
          ApiEndpoints.posDrawerOperations,
          data: {
            'requestId': testOp.requestId,
            'posDeviceId': _deviceId,
            'drawerPurpose': 'hardwareTest',
            'reason': 'Hardware test pulse',
          },
        );
        drawerOp = registerRes.data?['data'] as Map<String, dynamic>?;
      } on DioException catch (error) {
        final code = error.response?.data is Map
            ? (error.response!.data as Map)['code']?.toString()
            : null;
        if (code == 'pos_drawer.till_session_not_open' ||
            code == 'pos_drawer.till_not_assigned') {
          throw const PosHardwareApiException(
            'pos_drawer.till_session_not_open',
            'Open an active till session before running the cash drawer hardware test.',
          );
        }
        rethrow;
      }

      final drawerOpId = drawerOp?['operationId']?.toString() ?? '';
      if (drawerOpId.isEmpty) {
        throw const PosHardwareApiException(
          'pos_drawer.register_failed',
          'Cash drawer test could not be registered.',
        );
      }

      final recoveryOp = DrawerOperation(
        operationId: drawerOpId,
        requestId: testOp.requestId,
        posDeviceId: _deviceId,
        drawerPurpose: 'hardwareTest',
        state: DrawerOperationState.opening,
        createdAt: DateTime.now().toUtc(),
        updatedAt: DateTime.now().toUtc(),
        reason: 'Hardware test pulse',
        drawerPort: config.drawerPort,
        pulseOnMilliseconds: config.pulseOnMilliseconds,
        pulseOffMilliseconds: config.pulseOffMilliseconds,
        linkedReceiptPrinterId: config.linkedReceiptPrinterId,
      );
      await _persist(recoveryOp);

      state = state.copyWith(
        status: CashDrawerUiStatus.opening,
        message: 'Sending drawer pulse…',
        activeTest: testOp,
        activeDrawerOpId: drawerOpId,
        activeTestSet: true,
        activeDrawerOpIdSet: true,
      );

      // 3. Load linked printer config (USB / Bluetooth / LocalPrintAgent)
      final printerConfig =
          await ref.read(posDevicePrinterConfigStoreProvider).load(_deviceId);
      if (!_printerSupportsDrawerPulse(printerConfig)) {
        throw const PosHardwareApiException(
          'pos_drawer.printer_unavailable',
          'Linked receipt printer is not configured for cash drawer pulse.',
        );
      }

      // 4. Pulse via typed CashDrawerTransport (never via receipt print)
      await _pulseConfiguredDrawer(
        printerConfig: printerConfig!,
        request: CashDrawerPulseRequest(
          requestId: testOp.requestId,
          drawerOperationId: drawerOpId,
          purpose: LocalPrintAgentDrawerPurpose.hardwareTest,
          printerName:
              printerConfig.agentPrinterName ?? printerConfig.displayName,
          drawerPort: config.drawerPort,
          pulseOnMilliseconds: config.pulseOnMilliseconds,
          pulseOffMilliseconds: config.pulseOffMilliseconds,
          configurationId: state.authoritativeConfiguration?.configurationId,
          configurationVersion:
              state.authoritativeConfiguration?.configurationVersion,
          posDeviceId: _deviceId,
        ),
      );

      await _persist(
        recoveryOp.copyWith(state: DrawerOperationState.agentAccepted),
      );

      state = state.copyWith(
        status: CashDrawerUiStatus.agentAccepted,
        message:
            'Transport accepted pulse. Did the cash drawer physically open?',
      );

      // 5. Non-terminal finalize — physical confirmation still required
      await dio.put<dynamic>(
        ApiEndpoints.posDrawerFinalize(drawerOpId),
        data: {
          'status': 'AGENT_ACCEPTED',
          'resultCategory': 'SUCCESS',
          'agentAccepted': true,
          'physicalConfirmation': null,
        },
      );

      state = state.copyWith(
        status: CashDrawerUiStatus.awaitingPhysicalConfirmation,
        message: 'Awaiting operator physical confirmation…',
      );
    } catch (e) {
      final drawerOpId = state.activeDrawerOpId;
      final activeTest = state.activeTest;
      if (drawerOpId != null && drawerOpId.isNotEmpty) {
        try {
          final dio = ref.read(appDioProvider);
          final failureState = _durableFailureState(e);
          await dio.put<dynamic>(
            ApiEndpoints.posDrawerFinalize(drawerOpId),
            data: {
              'status': failureState == DrawerOperationState.unknown
                  ? 'UNKNOWN'
                  : 'FAILED',
              'resultCategory': 'FAILED',
              'agentAccepted': false,
              'physicalConfirmation': null,
              'failureCategory': _safeFailureCategory(e),
            },
          );
        } catch (_) {}
      }
      if (activeTest != null) {
        try {
          await ref.read(posHardwareRepositoryProvider).submitResult(
            activeTest.testId,
            {
              'status': 'FAILED',
              'resultCategory': 'drawer_unknown',
              'safeMessage': _safeApiError(e),
              'physicalConfirmation': false,
            },
          );
        } catch (_) {}
      }
      state = state.copyWith(
        status: CashDrawerUiStatus.error,
        message: 'Test pulse failed: ${_safeApiError(e)}',
      );
    }
  }

  Future<void> _persist(DrawerOperation operation) async {
    await ref.read(drawerOperationStoreProvider).upsert(operation);
    final list = await ref.read(drawerOperationStoreProvider).load();
    state = state.copyWith(recoveryOperations: list);
  }

  String _safeApiError(Object error) {
    if (error is PosHardwareApiException) {
      return error.message.trim().isEmpty
          ? 'Cash drawer hardware request failed.'
          : error.message;
    }
    if (error is LocalPrintAgentException) return error.message;
    if (error is PrinterException) return error.message;
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map) {
        final code = data['code']?.toString();
        final message = data['message']?.toString();
        if (message != null && message.trim().isNotEmpty) {
          return code == null || code.isEmpty ? message : '$code: $message';
        }
      }
      final status = error.response?.statusCode;
      if (status == 400) {
        return 'Drawer request was rejected. Check configuration and try again.';
      }
      if (status == 403) {
        return 'Permission denied for cash drawer operation.';
      }
      if (status == 409) {
        return 'This drawer operation was already completed.';
      }
      if (status == 422) {
        return 'Drawer operation is not allowed for the current till/policy.';
      }
      return 'Drawer request failed (HTTP $status).';
    }
    return error.toString();
  }

  Future<CashDrawerPulseResult> _pulseConfiguredDrawer({
    required PosDevicePrinterConfig printerConfig,
    required CashDrawerPulseRequest request,
  }) {
    final transport = CashDrawerTransport(
      localPrintAgentClient: ref.read(localPrintAgentClientProvider),
    );
    return transport.open(printerConfig, request);
  }

  bool _printerSupportsDrawerPulse(PosDevicePrinterConfig? config) {
    if (config == null || !config.enabled) return false;
    return switch (config.connectionType) {
      PrinterConnectionType.localPrintAgent =>
        (config.agentBaseUrl?.trim().isNotEmpty ?? false) &&
            (config.localApiKey?.trim().isNotEmpty ?? false),
      PrinterConnectionType.usb =>
        config.usbVendorId != null && config.usbProductId != null,
      PrinterConnectionType.bluetooth =>
        (config.bluetoothAddress?.trim().isNotEmpty ?? false),
      _ => false,
    };
  }

  DrawerOperationState _durableFailureState(Object error) {
    if (error is LocalPrintAgentException &&
        (error.type == LocalPrintAgentFailureType.timeout ||
            error.type == LocalPrintAgentFailureType.unknown)) {
      return DrawerOperationState.unknown;
    }
    if (error is PrinterException &&
        (error.code == 'TIMEOUT' || error.code == 'PARTIAL_WRITE')) {
      return DrawerOperationState.unknown;
    }
    return DrawerOperationState.failed;
  }

  String _safeFailureCategory(Object? error) {
    if (error is LocalPrintAgentException) return error.type.name;
    if (error is PrinterException) return error.code;
    return error == null ? 'none' : 'unknown';
  }

  String _messageFor(Object? error) {
    if (error is LocalPrintAgentException) return error.message;
    if (error is PrinterException) return error.message;
    return error?.toString() ?? 'Drawer pulse failed.';
  }

  bool _isTerminalPulseState(DrawerOperationState state) =>
      state == DrawerOperationState.opened ||
      state == DrawerOperationState.agentAccepted ||
      state == DrawerOperationState.cancelled ||
      state == DrawerOperationState.unknown ||
      state == DrawerOperationState.failed;

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

      // 2. Submit hardware test log result (canonical result categories)
      await repo.submitResult(activeTest.testId, {
        'status': success ? 'PASSED' : 'FAILED',
        'resultCategory': success ? 'drawer_opened' : 'drawer_did_not_open',
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
        message: 'Failed to submit physical confirmation: ${_safeApiError(e)}',
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

      final printerConfig =
          await ref.read(posDevicePrinterConfigStoreProvider).load(_deviceId);
      final config = state.config;

      if (config == null || !_printerSupportsDrawerPulse(printerConfig)) {
        throw Exception(
          'Receipt printer or cash drawer configuration missing.',
        );
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

      await _pulseConfiguredDrawer(
        printerConfig: printerConfig!,
        request: CashDrawerPulseRequest(
          requestId: requestId,
          drawerOperationId: drawerOpId,
          purpose: LocalPrintAgentDrawerPurpose.manualNoSale,
          printerName:
              printerConfig.agentPrinterName ?? printerConfig.displayName,
          drawerPort: config.drawerPort,
          pulseOnMilliseconds: config.pulseOnMilliseconds,
          pulseOffMilliseconds: config.pulseOffMilliseconds,
          configurationId: state.authoritativeConfiguration?.configurationId,
          configurationVersion:
              state.authoritativeConfiguration?.configurationVersion,
          posDeviceId: _deviceId,
        ),
      );

      // Transport accept ≠ physical open confirmation.
      operation = operation.copyWith(state: DrawerOperationState.agentAccepted);
      await _persist(operation);

      await dio.put<dynamic>(
        ApiEndpoints.posDrawerFinalize(drawerOpId),
        data: {
          'status': 'AGENT_ACCEPTED',
          'resultCategory': 'SUCCESS',
          'agentAccepted': true,
          'physicalConfirmation': null,
        },
      );

      state = state.copyWith(
        status: CashDrawerUiStatus.success,
        message:
            'Drawer pulse accepted by transport. Confirm physical open if required.',
      );
      await load();
      return true;
    } on DioException catch (e) {
      state = state.copyWith(
          status: CashDrawerUiStatus.error, message: _safeApiError(e));
      return false;
    } catch (e) {
      state = state.copyWith(
          status: CashDrawerUiStatus.error,
          message: 'Failed to open drawer: ${_safeApiError(e)}');
      return false;
    }
  }

  Future<void> triggerAutoOpenForCheckout({
    required String drawerOperationId,
    required String purposeStr,
    required Map<String, dynamic> drawerSettingsJson,
    required String businessReferenceId,
    String? drawerRequestId,
  }) async {
    if (!_inFlightAutoOpenIds.add(drawerOperationId)) {
      developer.log(
        'Cash drawer auto-trigger already in flight. operationId=$drawerOperationId',
        name: 'pos.drawer',
      );
      return;
    }

    try {
      await _triggerAutoOpenForCheckoutBody(
        drawerOperationId: drawerOperationId,
        drawerRequestId: drawerRequestId,
        purposeStr: purposeStr,
        drawerSettingsJson: drawerSettingsJson,
        businessReferenceId: businessReferenceId,
      );
    } finally {
      _inFlightAutoOpenIds.remove(drawerOperationId);
    }
  }

  Future<void> _triggerAutoOpenForCheckoutBody({
    required String drawerOperationId,
    required String purposeStr,
    required Map<String, dynamic> drawerSettingsJson,
    required String businessReferenceId,
    String? drawerRequestId,
  }) async {
    final store = ref.read(drawerOperationStoreProvider);
    final existing =
        (await store.load()).where((x) => x.operationId == drawerOperationId);
    if (existing.isNotEmpty) {
      final localState = existing.first.state;
      if (_isTerminalPulseState(localState)) {
        developer.log(
            'Cash drawer auto-trigger already processed. operationId=$drawerOperationId, state=${localState.name}',
            name: 'pos.drawer');
        return;
      }
      if (localState == DrawerOperationState.opening) {
        // Prior attempt left uncertain state — never blind replay.
        await _persist(
          existing.first.copyWith(
            state: DrawerOperationState.unknown,
            failureCategory: 'uncertain_inflight',
            failureMessage:
                'Prior drawer pulse outcome unknown after restart. Confirm physically; do not auto-replay.',
          ),
        );
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

    final pulseRequestId =
        (drawerRequestId != null && drawerRequestId.trim().isNotEmpty)
            ? drawerRequestId.trim()
            : drawerOperationId;

    var operation = DrawerOperation(
      operationId: drawerOperationId,
      requestId: pulseRequestId,
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
      if (!_printerSupportsDrawerPulse(printerConfig)) {
        throw const LocalPrintAgentException(
          LocalPrintAgentFailureType.invalidConfiguration,
          'Receipt printer or cash drawer configuration missing.',
        );
      }

      await _pulseConfiguredDrawer(
        printerConfig: printerConfig!,
        request: CashDrawerPulseRequest(
          requestId: pulseRequestId,
          drawerOperationId: drawerOperationId,
          purpose: purpose,
          printerName:
              printerConfig.agentPrinterName ?? printerConfig.displayName,
          drawerPort: drawerPort,
          pulseOnMilliseconds: pulseOn,
          pulseOffMilliseconds: pulseOff,
          posDeviceId: _deviceId,
        ),
      );
      // Transport accept is not physical confirmation.
      operation = operation.copyWith(state: DrawerOperationState.agentAccepted);
      await _persist(operation);

      final dio = ref.read(appDioProvider);
      await dio.put<dynamic>(
        ApiEndpoints.posDrawerFinalize(drawerOperationId),
        data: {
          'status': 'AGENT_ACCEPTED',
          'resultCategory': 'SUCCESS',
          'agentAccepted': true,
          'physicalConfirmation': null,
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
    final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
        '${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
  }
}

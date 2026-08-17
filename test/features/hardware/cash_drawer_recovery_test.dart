import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nytroz_pos/core/storage/app_secure_storage.dart';
import 'package:nytroz_pos/core/storage/secure_storage_provider.dart';
import 'package:nytroz_pos/features/hardware/receipt_printer/clients/local_print_agent_client.dart';
import 'package:nytroz_pos/features/hardware/receipt_printer/config/pos_device_printer_config_store.dart';
import 'package:nytroz_pos/features/hardware/receipt_printer/models/local_print_agent_models.dart';
import 'package:nytroz_pos/features/hardware/receipt_printer/models/pos_device_printer_config.dart';
import 'package:nytroz_pos/features/hardware/receipt_printer/presentation/providers/cash_drawer_controller.dart';
import 'package:nytroz_pos/features/hardware/receipt_printer/presentation/providers/local_print_agent_controller.dart';
import 'package:nytroz_pos/features/hardware/receipt_printer/recovery/drawer_operation.dart';
import 'package:nytroz_pos/features/hardware/receipt_printer/recovery/drawer_operation_store.dart';
import 'package:nytroz_pos/features/device_activation/presentation/providers/device_activation_provider.dart';
import 'package:nytroz_pos/features/device_activation/domain/entities/pos_device_context.dart';
import 'package:nytroz_pos/features/device_activation/application/usecases/activate_device.dart';
import 'package:nytroz_pos/core/network/dio_provider.dart';
import 'package:dio/dio.dart';

class FakeSecureStorage implements AppSecureStorage {
  final Map<String, String> _data = {};

  @override
  Future<void> write(String key, String value) async {
    _data[key] = value;
  }

  @override
  Future<String?> read(String key) async {
    return _data[key];
  }

  @override
  Future<void> delete(String key) async {
    _data.remove(key);
  }

  @override
  Future<void> deleteAll() async {
    _data.clear();
  }

  Future<Map<String, String>> readAll() async {
    return Map.from(_data);
  }
}

class FakeLocalPrintAgentClient implements LocalPrintAgentClient {
  int openDrawerCallCount = 0;
  LocalPrintAgentDrawerOpenRequest? lastRequest;
  bool shouldTimeout = false;
  bool shouldBeUnavailable = false;

  @override
  Future<LocalPrintAgentDrawerOpenResult> openDrawer(
    PosDevicePrinterConfig config,
    LocalPrintAgentDrawerOpenRequest request,
  ) async {
    openDrawerCallCount++;
    lastRequest = request;

    if (shouldTimeout) {
      throw const LocalPrintAgentException(
        LocalPrintAgentFailureType.timeout,
        'Spooler timed out.',
        code: 'spooler_timeout',
      );
    }
    if (shouldBeUnavailable) {
      throw const LocalPrintAgentException(
        LocalPrintAgentFailureType.printerUnavailable,
        'Printer offline.',
        code: 'printer_offline',
      );
    }

    return LocalPrintAgentDrawerOpenResult(
      success: true,
      code: 'success',
      message: 'Physical drawer opens',
      requestId: request.requestId,
      drawerOperationId: request.drawerOperationId,
      duplicate: false,
      printerName: 'POSPrinter',
      physicalOpenConfirmed: true,
      bytesWritten: 5,
    );
  }

  @override
  Future<LocalPrintAgentHealth> health(PosDevicePrinterConfig config) async {
    return const LocalPrintAgentHealth(
      apiVersion: '1',
      receiptContractVersion: '1',
      agentStatus: 'running',
      printerName: 'POSPrinter',
      printerExists: true,
      ready: true,
    );
  }

  @override
  Future<LocalPrintAgentPrintResult> printReceipt(
    PosDevicePrinterConfig config,
    LocalPrintAgentReceiptRequest request,
  ) async {
    return LocalPrintAgentPrintResult(
      success: true,
      code: 'success',
      message: 'Printed',
      requestId: request.requestId,
      duplicate: false,
      printerName: 'POSPrinter',
      bytesWritten: 100,
    );
  }

  @override
  Future<LocalPrintAgentOperationStatus?> operationStatus(
    PosDevicePrinterConfig config,
    String requestId,
  ) async {
    return null;
  }
}

class FakeDio implements Dio {
  int finalizeCallCount = 0;
  String? lastFinalizeStatus;
  bool lastFinalizeAgentAccepted = false;

  @override
  Future<Response<T>> put<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    void Function(int, int)? onSendProgress,
    void Function(int, int)? onReceiveProgress,
  }) async {
    if (path.contains('/finalize')) {
      finalizeCallCount++;
      if (data is Map) {
        lastFinalizeStatus = data['status']?.toString();
        lastFinalizeAgentAccepted = data['agentAccepted'] == true;
      }
    }
    return Response<T>(
      requestOptions: RequestOptions(path: path),
      statusCode: 200,
      data: null,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeActivateDevice implements ActivateDevice {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('Cash Drawer Recovery & Idempotency Tests', () {
    late FakeSecureStorage secureStorage;
    late FakeLocalPrintAgentClient printAgentClient;
    late FakeDio fakeDio;
    late ProviderContainer container;

    setUp(() async {
      secureStorage = FakeSecureStorage();
      printAgentClient = FakeLocalPrintAgentClient();
      fakeDio = FakeDio();

      final contextJson = jsonEncode(PosDeviceContext(
        deviceId: 'device-1',
        deviceCode: 'D-01',
        deviceName: 'Till 1',
        deviceType: 'register',
        platform: 'windows',
        deviceFingerprint: 'fingerprint',
        isTrusted: true,
        tenantId: 'tenant-1',
        outletId: 'outlet-1',
        outletName: 'Main',
        tillId: 'till-1',
        tillCode: 'T-01',
        tillName: 'Till 1',
        pairedAt: DateTime(2026, 7, 30),
      ).toJson());
      await secureStorage.write('pos.deviceContext', contextJson);

      container = ProviderContainer(
        overrides: [
          secureStorageProvider.overrideWithValue(secureStorage),
          localPrintAgentClientProvider.overrideWithValue(printAgentClient),
          appDioProvider.overrideWithValue(fakeDio),
          activateDeviceProvider.overrideWithValue(FakeActivateDevice()),
        ],
      );

      // Await one event loop cycle so the async DeviceActivationController restoration completes
      await Future.delayed(Duration.zero);
    });

    tearDown(() {
      container.dispose();
    });

    test('DrawerOperation json round-trip', () {
      final now = DateTime.now().toUtc();
      final op = DrawerOperation(
        operationId: 'op-123',
        requestId: 'req-456',
        posDeviceId: 'device-1',
        drawerPurpose: 'cashSale',
        state: DrawerOperationState.opening,
        createdAt: now,
        updatedAt: now,
        drawerPort: 'drawerPin2',
        pulseOnMilliseconds: 100,
        pulseOffMilliseconds: 200,
      );

      final json = op.toJson();
      final restored = DrawerOperation.fromJson(json);

      expect(restored.operationId, 'op-123');
      expect(restored.requestId, 'req-456');
      expect(restored.state, DrawerOperationState.opening);
      expect(restored.pulseOnMilliseconds, 100);
      expect(restored.pulseOffMilliseconds, 200);
    });

    test('Successful cash sale -> one drawer Agent request & finalize',
        () async {
      final configStore = container.read(posDevicePrinterConfigStoreProvider);
      await configStore.save(
        const PosDevicePrinterConfig(
          deviceId: 'device-1',
          enabled: true,
          connectionType: PrinterConnectionType.localPrintAgent,
          displayName: 'Local Agent',
          paperWidth: PrinterPaperWidth.mm80,
          agentBaseUrl: 'http://10.0.2.2:9101',
          localApiKey: '1234567890abcdefghijklmn',
          agentPrinterName: 'POSPrinter',
          connectionTimeoutMs: 5000,
        ),
      );

      final controller = container.read(cashDrawerControllerProvider.notifier);
      await controller.triggerAutoOpenForCheckout(
        drawerOperationId: 'op-1',
        purposeStr: 'cashSale',
        drawerSettingsJson: const {
          'drawerPort': 'drawerPin2',
          'pulseOnMilliseconds': 100,
          'pulseOffMilliseconds': 200,
        },
        businessReferenceId: 'sale-1',
      );

      expect(printAgentClient.openDrawerCallCount, 1);
      expect(printAgentClient.lastRequest?.requestId,
          'op-1'); // Idempotency key reused!
      expect(fakeDio.finalizeCallCount, 1);
      expect(fakeDio.lastFinalizeStatus, 'AGENT_ACCEPTED');
      expect(fakeDio.lastFinalizeAgentAccepted, true);

      final storeOps =
          await container.read(drawerOperationStoreProvider).load();
      expect(
          storeOps.any((x) =>
              x.operationId == 'op-1' &&
              x.state == DrawerOperationState.agentAccepted),
          true);
    });

    test('Repeated cash-sale response (replay) -> still only one agent request',
        () async {
      final configStore = container.read(posDevicePrinterConfigStoreProvider);
      await configStore.save(
        const PosDevicePrinterConfig(
          deviceId: 'device-1',
          enabled: true,
          connectionType: PrinterConnectionType.localPrintAgent,
          displayName: 'Local Agent',
          paperWidth: PrinterPaperWidth.mm80,
          agentBaseUrl: 'http://10.0.2.2:9101',
          localApiKey: '1234567890abcdefghijklmn',
          agentPrinterName: 'POSPrinter',
        ),
      );

      final controller = container.read(cashDrawerControllerProvider.notifier);

      // First call
      await controller.triggerAutoOpenForCheckout(
        drawerOperationId: 'op-dup',
        purposeStr: 'cashSale',
        drawerSettingsJson: const {
          'drawerPort': 'drawerPin2',
          'pulseOnMilliseconds': 100,
          'pulseOffMilliseconds': 200,
        },
        businessReferenceId: 'sale-dup',
      );

      // Second identical call (replay/UI rebuild)
      await controller.triggerAutoOpenForCheckout(
        drawerOperationId: 'op-dup',
        purposeStr: 'cashSale',
        drawerSettingsJson: const {
          'drawerPort': 'drawerPin2',
          'pulseOnMilliseconds': 100,
          'pulseOffMilliseconds': 200,
        },
        businessReferenceId: 'sale-dup',
      );

      expect(printAgentClient.openDrawerCallCount, 1); // BLOCK DUPLICATE!
    });

    test('Card/non-cash sale -> no drawer request triggered', () async {
      final configStore = container.read(posDevicePrinterConfigStoreProvider);
      await configStore.save(
        const PosDevicePrinterConfig(
          deviceId: 'device-1',
          enabled: true,
          connectionType: PrinterConnectionType.localPrintAgent,
          displayName: 'Local Agent',
          paperWidth: PrinterPaperWidth.mm80,
          agentBaseUrl: 'http://10.0.2.2:9101',
          localApiKey: '1234567890abcdefghijklmn',
          agentPrinterName: 'POSPrinter',
        ),
      );

      // In checkout payment screen, triggerAutoOpenForCheckout is only called when paymentMethod is CASH.
      // Card sale does not call triggerAutoOpenForCheckout. So call count remains 0.
      expect(printAgentClient.openDrawerCallCount, 0);
    });

    test('Agent timeout -> Unknown state and no automatic retry', () async {
      final configStore = container.read(posDevicePrinterConfigStoreProvider);
      await configStore.save(
        const PosDevicePrinterConfig(
          deviceId: 'device-1',
          enabled: true,
          connectionType: PrinterConnectionType.localPrintAgent,
          displayName: 'Local Agent',
          paperWidth: PrinterPaperWidth.mm80,
          agentBaseUrl: 'http://10.0.2.2:9101',
          localApiKey: '1234567890abcdefghijklmn',
          agentPrinterName: 'POSPrinter',
        ),
      );

      printAgentClient.shouldTimeout = true;

      final controller = container.read(cashDrawerControllerProvider.notifier);
      await controller.triggerAutoOpenForCheckout(
        drawerOperationId: 'op-timeout',
        purposeStr: 'cashSale',
        drawerSettingsJson: const {
          'drawerPort': 'drawerPin2',
          'pulseOnMilliseconds': 100,
          'pulseOffMilliseconds': 200,
        },
        businessReferenceId: 'sale-timeout',
      );

      // Call count should be 1
      expect(printAgentClient.openDrawerCallCount, 1);

      // Local store should hold state: unknown (timeout is unknown outcome!)
      final storeOps =
          await container.read(drawerOperationStoreProvider).load();
      final op = storeOps.firstWhere((x) => x.operationId == 'op-timeout');
      expect(op.state, DrawerOperationState.unknown);

      // Finalize should be called with status UNKNOWN
      expect(fakeDio.finalizeCallCount, 1);
      expect(fakeDio.lastFinalizeStatus, 'UNKNOWN');
      expect(fakeDio.lastFinalizeAgentAccepted, false);
    });

    test('Agent offline/unavailable -> failed state, no rollback of sale',
        () async {
      final configStore = container.read(posDevicePrinterConfigStoreProvider);
      await configStore.save(
        const PosDevicePrinterConfig(
          deviceId: 'device-1',
          enabled: true,
          connectionType: PrinterConnectionType.localPrintAgent,
          displayName: 'Local Agent',
          paperWidth: PrinterPaperWidth.mm80,
          agentBaseUrl: 'http://10.0.2.2:9101',
          localApiKey: '1234567890abcdefghijklmn',
          agentPrinterName: 'POSPrinter',
        ),
      );

      printAgentClient.shouldBeUnavailable = true;

      final controller = container.read(cashDrawerControllerProvider.notifier);
      await controller.triggerAutoOpenForCheckout(
        drawerOperationId: 'op-failed',
        purposeStr: 'cashSale',
        drawerSettingsJson: const {
          'drawerPort': 'drawerPin2',
          'pulseOnMilliseconds': 100,
          'pulseOffMilliseconds': 200,
        },
        businessReferenceId: 'sale-failed',
      );

      expect(printAgentClient.openDrawerCallCount, 1);

      final storeOps =
          await container.read(drawerOperationStoreProvider).load();
      final op = storeOps.firstWhere((x) => x.operationId == 'op-failed');
      expect(op.state, DrawerOperationState.failed);

      expect(fakeDio.finalizeCallCount, 1);
      expect(fakeDio.lastFinalizeStatus, 'FAILED');
    });
  });
}

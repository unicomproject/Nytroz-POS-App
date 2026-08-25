import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nytroz_pos/features/hardware/receipt_printer/adapters/bluetooth_receipt_printer_adapter.dart';
import 'package:nytroz_pos/features/hardware/receipt_printer/adapters/usb_receipt_printer_adapter.dart';
import 'package:nytroz_pos/features/hardware/receipt_printer/clients/local_print_agent_client.dart';
import 'package:nytroz_pos/features/hardware/receipt_printer/models/local_print_agent_models.dart';
import 'package:nytroz_pos/features/hardware/receipt_printer/models/pos_device_printer_config.dart';
import 'package:nytroz_pos/features/hardware/receipt_printer/models/printer_exception.dart';
import 'package:nytroz_pos/features/hardware/receipt_printer/pos_receipt_printer_service.dart';
import 'package:nytroz_pos/features/hardware/receipt_printer/testing/local_print_agent_test_receipt.dart';

/// Live Flutter client → LocalPrintAgent remains optional Windows path.
/// Enable with LIVE_PRINT_AGENT=1 + URL/KEY.
void main() {
  final enabled = Platform.environment['LIVE_PRINT_AGENT'] == '1';
  final url = Platform.environment['LIVE_PRINT_AGENT_URL'] ?? '';
  final key = Platform.environment['LIVE_PRINT_AGENT_KEY'] ?? '';
  final printer =
      Platform.environment['LIVE_PRINT_AGENT_PRINTER'] ?? 'POSPrinter POS80';

  Dio buildDio(Duration timeout) {
    final dio = Dio(
      BaseOptions(
        connectTimeout: timeout,
        sendTimeout: timeout,
        receiveTimeout: timeout,
      ),
    );
    dio.httpClientAdapter = IOHttpClientAdapter(
      createHttpClient: () {
        final client = HttpClient();
        client.findProxy = (_) => 'DIRECT';
        client.connectionTimeout = timeout;
        return client;
      },
    );
    return dio;
  }

  group('Adapter selection after Android direct integration', () {
    test('USB/Bluetooth adapters are selected; non-Android connect fails closed',
        () {
      debugDefaultTargetPlatformOverride = TargetPlatform.windows;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      final service = PosReceiptPrinterService(
        loadConfiguration: (_) async => null,
      );
      final usb = service.selectAdapter(
        const PosDevicePrinterConfig(
          deviceId: 'usb',
          enabled: true,
          connectionType: PrinterConnectionType.usb,
          displayName: 'USB',
          paperWidth: PrinterPaperWidth.mm80,
          usbVendorId: 1,
          usbProductId: 2,
        ),
      );
      expect(usb, isA<UsbReceiptPrinterAdapter>());
      expect(
        () => usb.connect(
          const PosDevicePrinterConfig(
            deviceId: 'usb',
            enabled: true,
            connectionType: PrinterConnectionType.usb,
            displayName: 'USB',
            paperWidth: PrinterPaperWidth.mm80,
            usbVendorId: 1,
            usbProductId: 2,
          ),
        ),
        throwsA(isA<PrinterUnsupportedException>()),
      );
      final bt = service.selectAdapter(
        const PosDevicePrinterConfig(
          deviceId: 'bt',
          enabled: true,
          connectionType: PrinterConnectionType.bluetooth,
          displayName: 'BT',
          paperWidth: PrinterPaperWidth.mm80,
          bluetoothAddress: 'AA:BB:CC:DD:EE:FF',
        ),
      );
      expect(bt, isA<BluetoothReceiptPrinterAdapter>());
    });
  });

  group('Live Local Print Agent physical acceptance', () {
    setUp(() {
      debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    });
    tearDown(() {
      debugDefaultTargetPlatformOverride = null;
    });

    test(
      'Flutter client prints one test receipt through Local Print Agent',
      () async {
        expect(key.length, greaterThanOrEqualTo(24),
            reason: 'LIVE_PRINT_AGENT_KEY missing or too short');
        const timeout = Duration(seconds: 20);
        final config = PosDevicePrinterConfig(
          deviceId: 'chunk2-live-acceptance',
          enabled: true,
          connectionType: PrinterConnectionType.localPrintAgent,
          displayName: 'Chunk2 Live',
          paperWidth: PrinterPaperWidth.mm80,
          agentBaseUrl: url,
          localApiKey: key,
          agentPrinterName: printer,
          connectionTimeoutMs: timeout.inMilliseconds,
        );
        final client = LocalPrintAgentClient(dio: buildDio(timeout));
        final health = await client.health(config);
        expect(health.printerExists, isTrue);
        expect(health.ready, isTrue);

        final request = const LocalPrintAgentTestReceiptBuilder().build(
          merchantName: 'OneVerz Chunk2 Flutter Client',
          outletName: 'Main Outlet',
          tillName: 'Front Till 01',
          cashierName: 'Flutter Acceptance',
        );
        final result = await client.printReceipt(config, request);
        expect(result.success, isTrue);
        expect(result.duplicate, isFalse);
        expect(result.bytesWritten, greaterThan(0));

        try {
          await client.printReceipt(config, request);
          fail('Exact duplicate should be rejected as duplicate/conflict');
        } on LocalPrintAgentException catch (error) {
          expect(
            error.type == LocalPrintAgentFailureType.duplicate ||
                error.code == 'duplicate_request' ||
                error.code == 'idempotency_conflict',
            isTrue,
          );
        }
      },
      skip: enabled && url.isNotEmpty && key.length >= 24
          ? false
          : 'Set LIVE_PRINT_AGENT=1 plus URL/KEY to run physical acceptance.',
    );
  });
}

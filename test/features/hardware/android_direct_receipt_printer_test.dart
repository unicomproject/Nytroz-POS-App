import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nytroz_pos/features/hardware/receipt_printer/adapters/bluetooth_receipt_printer_adapter.dart';
import 'package:nytroz_pos/features/hardware/receipt_printer/adapters/usb_receipt_printer_adapter.dart';
import 'package:nytroz_pos/features/hardware/receipt_printer/models/pos_device_printer_config.dart';
import 'package:nytroz_pos/features/hardware/receipt_printer/models/printer_exception.dart';
import 'package:nytroz_pos/features/hardware/receipt_printer/platform/android_receipt_printer_platform.dart';
import 'package:nytroz_pos/features/hardware/receipt_printer/pos_receipt_printer_service.dart';

class _FakeAndroidPlatform implements AndroidReceiptPrinterPlatform {
  _FakeAndroidPlatform({
    this.usbDevices = const [],
    this.bluetoothDevices = const [],
    this.bluetoothEnabled = true,
    this.permissionGranted = true,
    this.writeBytesResult,
    this.throwOnUsbWrite,
    this.throwOnBtWrite,
    this.throwOnBtConnect,
  });

  List<AndroidUsbPrinterDevice> usbDevices;
  List<AndroidBluetoothPrinterDevice> bluetoothDevices;
  bool usbHost = true;
  bool bluetoothClassic = true;
  bool bluetoothEnabled;
  bool permissionGranted;
  int? writeBytesResult;
  PrinterException? throwOnUsbWrite;
  PrinterException? throwOnBtWrite;
  PrinterException? throwOnBtConnect;
  int usbWriteCalls = 0;
  int btWriteCalls = 0;
  final List<int> writtenLengths = [];

  @override
  Future<AndroidReceiptPrinterCapabilities> getCapabilities() async {
    return AndroidReceiptPrinterCapabilities(
      platform: 'android',
      usbHost: usbHost,
      bluetoothClassic: bluetoothClassic,
    );
  }

  @override
  Future<List<AndroidUsbPrinterDevice>> usbListDevices() async => usbDevices;

  @override
  Future<bool> usbHasPermission(String deviceName) async => permissionGranted;

  @override
  Future<bool> usbRequestPermission(String deviceName) async =>
      permissionGranted;

  @override
  Future<int> usbWrite({
    required int vendorId,
    required int productId,
    required List<int> bytes,
    required int timeoutMs,
    String? deviceName,
    String? serialNumber,
  }) async {
    usbWriteCalls++;
    if (throwOnUsbWrite != null) throw throwOnUsbWrite!;
    final written = writeBytesResult ?? bytes.length;
    writtenLengths.add(written);
    return written;
  }

  @override
  Future<bool> bluetoothIsEnabled() async => bluetoothEnabled;

  @override
  Future<List<AndroidBluetoothPrinterDevice>> bluetoothListBonded() async =>
      bluetoothDevices;

  @override
  Future<void> bluetoothConnect({
    required String address,
    required int timeoutMs,
  }) async {
    if (throwOnBtConnect != null) throw throwOnBtConnect!;
  }

  @override
  Future<int> bluetoothWrite({
    required String address,
    required List<int> bytes,
    required int timeoutMs,
  }) async {
    btWriteCalls++;
    if (throwOnBtWrite != null) throw throwOnBtWrite!;
    final written = writeBytesResult ?? bytes.length;
    writtenLengths.add(written);
    return written;
  }

  @override
  Future<void> bluetoothDisconnect() async {}
}

void main() {
  const usbConfig = PosDevicePrinterConfig(
    deviceId: 'dev-1',
    enabled: true,
    connectionType: PrinterConnectionType.usb,
    displayName: 'USB Printer',
    paperWidth: PrinterPaperWidth.mm80,
    usbVendorId: 0x0483,
    usbProductId: 0x5740,
    usbDeviceIdentifier: 'usb-1',
  );

  const btConfig = PosDevicePrinterConfig(
    deviceId: 'dev-1',
    enabled: true,
    connectionType: PrinterConnectionType.bluetooth,
    displayName: 'BT Printer',
    paperWidth: PrinterPaperWidth.mm80,
    bluetoothAddress: 'AA:BB:CC:DD:EE:FF',
  );

  group('PosReceiptPrinterService adapter selection', () {
    test('selects USB and Bluetooth adapters for matching configs', () {
      final usb = UsbReceiptPrinterAdapter(
        platform: _FakeAndroidPlatform(),
      );
      final bt = BluetoothReceiptPrinterAdapter(
        platform: _FakeAndroidPlatform(),
      );
      final service = PosReceiptPrinterService(
        loadConfiguration: (_) async => null,
        usbAdapter: usb,
        bluetoothAdapter: bt,
      );
      expect(service.selectAdapter(usbConfig), same(usb));
      expect(service.selectAdapter(btConfig), same(bt));
      expect(
        service
            .selectAdapter(
              usbConfig.copyWith(
                connectionType: PrinterConnectionType.localPrintAgent,
                agentBaseUrl: 'http://127.0.0.1:9101',
                localApiKey: '123456789012345678901234',
              ),
            )
            .connectionType,
        PrinterConnectionType.localPrintAgent,
      );
    });
  });

  group('USB adapter', () {
    test('unsupported platform fails closed', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.windows;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      final adapter = UsbReceiptPrinterAdapter(
        platform: _FakeAndroidPlatform(),
      );
      expect(
        () => adapter.connect(usbConfig),
        throwsA(isA<PrinterUnsupportedException>()),
      );
    });

    test('device missing fails with DEVICE_NOT_FOUND', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      final adapter = UsbReceiptPrinterAdapter(
        platform: _FakeAndroidPlatform(usbDevices: const []),
      );
      expect(
        () => adapter.connect(usbConfig),
        throwsA(isA<PrinterDeviceNotFoundException>()),
      );
    });

    test('multiple devices without identity fail safely', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      final platform = _FakeAndroidPlatform(
        usbDevices: const [
          AndroidUsbPrinterDevice(
            deviceName: 'a',
            vendorId: 0x0483,
            productId: 0x5740,
            hasPermission: true,
          ),
          AndroidUsbPrinterDevice(
            deviceName: 'b',
            vendorId: 0x0483,
            productId: 0x5740,
            hasPermission: true,
          ),
        ],
      );
      final adapter = UsbReceiptPrinterAdapter(platform: platform);
      const multiConfig = PosDevicePrinterConfig(
        deviceId: 'dev-1',
        enabled: true,
        connectionType: PrinterConnectionType.usb,
        displayName: 'USB Printer',
        paperWidth: PrinterPaperWidth.mm80,
        usbVendorId: 0x0483,
        usbProductId: 0x5740,
      );
      expect(
        () => adapter.connect(multiConfig),
        throwsA(isA<PrinterConnectionException>()),
      );
    });

    test('permission denied fails with PERMISSION_DENIED', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      final platform = _FakeAndroidPlatform(
        permissionGranted: false,
        usbDevices: const [
          AndroidUsbPrinterDevice(
            deviceName: 'usb-1',
            vendorId: 0x0483,
            productId: 0x5740,
            hasPermission: false,
            serialNumber: 'usb-1',
          ),
        ],
      );
      final adapter = UsbReceiptPrinterAdapter(platform: platform);
      expect(
        () => adapter.connect(usbConfig),
        throwsA(isA<PrinterPermissionDeniedException>()),
      );
    });

    test('successful write requires full byte count', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      final platform = _FakeAndroidPlatform(
        usbDevices: const [
          AndroidUsbPrinterDevice(
            deviceName: 'usb-1',
            vendorId: 0x0483,
            productId: 0x5740,
            hasPermission: true,
            serialNumber: 'usb-1',
          ),
        ],
      );
      final adapter = UsbReceiptPrinterAdapter(platform: platform);
      await adapter.connect(usbConfig);
      await adapter.printBytes(usbConfig, [1, 2, 3, 4]);
      expect(platform.usbWriteCalls, 1);
      expect(platform.writtenLengths.single, 4);
    });

    test('partial write is not success', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      final platform = _FakeAndroidPlatform(
        writeBytesResult: 2,
        usbDevices: const [
          AndroidUsbPrinterDevice(
            deviceName: 'usb-1',
            vendorId: 0x0483,
            productId: 0x5740,
            hasPermission: true,
            serialNumber: 'usb-1',
          ),
        ],
      );
      final adapter = UsbReceiptPrinterAdapter(platform: platform);
      await adapter.connect(usbConfig);
      expect(
        () => adapter.printBytes(usbConfig, [1, 2, 3, 4]),
        throwsA(isA<PrinterPartialWriteException>()),
      );
    });

    test('serializes concurrent writes', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      final platform = _FakeAndroidPlatform(
        usbDevices: const [
          AndroidUsbPrinterDevice(
            deviceName: 'usb-1',
            vendorId: 0x0483,
            productId: 0x5740,
            hasPermission: true,
            serialNumber: 'usb-1',
          ),
        ],
      );
      final gate = DirectPrinterWriteGate();
      final adapter = UsbReceiptPrinterAdapter(
        platform: platform,
        writeGate: gate,
      );
      await adapter.connect(usbConfig);
      await Future.wait([
        adapter.printBytes(usbConfig, [1, 2]),
        adapter.printBytes(usbConfig, [3, 4, 5]),
      ]);
      expect(platform.usbWriteCalls, 2);
    });

    test('does not auto-retry after write failure', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      final platform = _FakeAndroidPlatform(
        throwOnUsbWrite: const PrinterSendException('boom'),
        usbDevices: const [
          AndroidUsbPrinterDevice(
            deviceName: 'usb-1',
            vendorId: 0x0483,
            productId: 0x5740,
            hasPermission: true,
            serialNumber: 'usb-1',
          ),
        ],
      );
      final adapter = UsbReceiptPrinterAdapter(platform: platform);
      await adapter.connect(usbConfig);
      await expectLater(
        adapter.printBytes(usbConfig, [1]),
        throwsA(isA<PrinterSendException>()),
      );
      expect(platform.usbWriteCalls, 1);
    });
  });

  group('Bluetooth adapter', () {
    test('unsupported platform fails closed', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      final adapter = BluetoothReceiptPrinterAdapter(
        platform: _FakeAndroidPlatform(),
      );
      expect(
        () => adapter.connect(btConfig),
        throwsA(isA<PrinterUnsupportedException>()),
      );
    });

    test('bluetooth disabled fails safely', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      final adapter = BluetoothReceiptPrinterAdapter(
        platform: _FakeAndroidPlatform(bluetoothEnabled: false),
      );
      expect(
        () => adapter.connect(btConfig),
        throwsA(isA<PrinterConnectionException>()),
      );
    });

    test('unpaired address fails DEVICE_NOT_FOUND', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      final adapter = BluetoothReceiptPrinterAdapter(
        platform: _FakeAndroidPlatform(bluetoothDevices: const []),
      );
      expect(
        () => adapter.connect(btConfig),
        throwsA(isA<PrinterDeviceNotFoundException>()),
      );
    });

    test('connect timeout maps to failure', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      final adapter = BluetoothReceiptPrinterAdapter(
        platform: _FakeAndroidPlatform(
          bluetoothDevices: const [
            AndroidBluetoothPrinterDevice(address: 'AA:BB:CC:DD:EE:FF'),
          ],
          throwOnBtConnect: const PrinterTimeoutException('timeout'),
        ),
      );
      expect(
        () => adapter.connect(btConfig),
        throwsA(isA<PrinterTimeoutException>()),
      );
    });

    test('successful write and disconnect', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      final platform = _FakeAndroidPlatform(
        bluetoothDevices: const [
          AndroidBluetoothPrinterDevice(address: 'AA:BB:CC:DD:EE:FF'),
        ],
      );
      final adapter = BluetoothReceiptPrinterAdapter(platform: platform);
      await adapter.connect(btConfig);
      await adapter.printBytes(btConfig, [9, 8, 7]);
      await adapter.disconnect();
      expect(platform.btWriteCalls, 1);
    });

    test('no blind replay after failure', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      final platform = _FakeAndroidPlatform(
        throwOnBtWrite: const PrinterSendException('drop'),
        bluetoothDevices: const [
          AndroidBluetoothPrinterDevice(address: 'AA:BB:CC:DD:EE:FF'),
        ],
      );
      final adapter = BluetoothReceiptPrinterAdapter(platform: platform);
      await adapter.connect(btConfig);
      await expectLater(
        adapter.printBytes(btConfig, [1, 2]),
        throwsA(isA<PrinterSendException>()),
      );
      expect(platform.btWriteCalls, 1);
    });
  });
}

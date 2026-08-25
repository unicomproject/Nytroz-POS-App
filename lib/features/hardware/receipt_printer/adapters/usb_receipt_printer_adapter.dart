import 'dart:async';

import '../models/pos_device_printer_config.dart';
import '../models/printer_exception.dart';
import '../platform/android_receipt_printer_platform.dart';
import 'receipt_printer_adapter.dart';

/// Serializes direct-device print writes. Never auto-replays failed jobs.
class DirectPrinterWriteGate {
  Future<void> _tail = Future.value();

  Future<T> runExclusive<T>(Future<T> Function() action) {
    final completer = Completer<T>();
    _tail = _tail.catchError((_) {}).then((_) async {
      try {
        completer.complete(await action());
      } catch (error, stack) {
        completer.completeError(error, stack);
      }
    });
    return completer.future;
  }
}

/// Android USB Host ESC/POS transport (USB-C hub / OTG).
class UsbReceiptPrinterAdapter implements ReceiptPrinterAdapter {
  UsbReceiptPrinterAdapter({
    AndroidReceiptPrinterPlatform? platform,
    DirectPrinterWriteGate? writeGate,
  })  : _platform = platform ?? MethodChannelAndroidReceiptPrinter(),
        _writeGate = writeGate ?? DirectPrinterWriteGate();

  final AndroidReceiptPrinterPlatform _platform;
  final DirectPrinterWriteGate _writeGate;
  bool _ready = false;
  String? _resolvedDeviceName;

  @override
  PrinterConnectionType get connectionType => PrinterConnectionType.usb;

  @override
  Future<void> connect(PosDevicePrinterConfig config) async {
    _ensureAndroidUsbSupported();
    final vendorId = config.usbVendorId;
    final productId = config.usbProductId;
    if (vendorId == null || productId == null) {
      throw const PrinterNotConfiguredException(
        'USB printer vendor/product IDs are not configured for this device.',
      );
    }

    final devices = await _platform.usbListDevices();
    final matches = devices
        .where((d) => d.vendorId == vendorId && d.productId == productId)
        .toList(growable: false);
    if (matches.isEmpty) {
      throw const PrinterDeviceNotFoundException(
        'Configured USB receipt printer is not attached.',
      );
    }

    final preferredName = config.usbDeviceIdentifier?.trim();
    final AndroidUsbPrinterDevice selected;
    if (preferredName != null && preferredName.isNotEmpty) {
      selected = matches.firstWhere(
        (d) =>
            d.deviceName == preferredName ||
            d.serialNumber == preferredName,
        orElse: () => throw PrinterDeviceNotFoundException(
          'Configured USB identity "$preferredName" was not found.',
        ),
      );
    } else if (matches.length == 1) {
      selected = matches.first;
    } else {
      throw const PrinterConnectionException(
        'Multiple USB printers match vendor/product. '
        'Select a specific deviceName/serial in configuration.',
      );
    }

    if (!selected.hasPermission) {
      final granted =
          await _platform.usbRequestPermission(selected.deviceName);
      if (!granted) {
        throw const PrinterPermissionDeniedException(
          'USB permission was denied for the receipt printer.',
        );
      }
    }

    _resolvedDeviceName = selected.deviceName;
    _ready = true;
  }

  @override
  Future<void> checkStatus(PosDevicePrinterConfig config) async {
    if (!_ready) {
      await connect(config);
      return;
    }
    final vendorId = config.usbVendorId;
    final productId = config.usbProductId;
    if (vendorId == null || productId == null) {
      throw const PrinterNotConfiguredException(
        'USB printer vendor/product IDs are not configured for this device.',
      );
    }
    final devices = await _platform.usbListDevices();
    final stillPresent = devices.any(
      (d) =>
          d.vendorId == vendorId &&
          d.productId == productId &&
          (_resolvedDeviceName == null || d.deviceName == _resolvedDeviceName),
    );
    if (!stillPresent) {
      _ready = false;
      throw const PrinterDeviceNotFoundException(
        'USB receipt printer disconnected.',
      );
    }
  }

  @override
  Future<void> printBytes(
    PosDevicePrinterConfig config,
    List<int> bytes,
  ) async {
    await checkStatus(config);
    final vendorId = config.usbVendorId;
    final productId = config.usbProductId;
    if (vendorId == null || productId == null) {
      throw const PrinterNotConfiguredException(
        'USB printer vendor/product IDs are not configured for this device.',
      );
    }
    if (bytes.isEmpty) {
      throw const PrinterConfigurationException(
        'Cannot print an empty ESC/POS payload.',
      );
    }

    await _writeGate.runExclusive(() async {
      final written = await _platform.usbWrite(
        vendorId: vendorId,
        productId: productId,
        deviceName: _resolvedDeviceName ?? config.usbDeviceIdentifier,
        serialNumber: config.usbDeviceIdentifier,
        bytes: bytes,
        timeoutMs: config.connectionTimeoutMs.clamp(1000, 60000),
      );
      if (written != bytes.length) {
        throw PrinterPartialWriteException(
          'USB write incomplete: wrote $written of ${bytes.length} bytes.',
        );
      }
    });
  }

  @override
  Future<void> disconnect() async {
    _ready = false;
    _resolvedDeviceName = null;
  }

  void _ensureAndroidUsbSupported() {
    if (!MethodChannelAndroidReceiptPrinter.isAndroidNative) {
      throw const PrinterUnsupportedException(
        'USB receipt printing requires Android USB Host. UNSUPPORTED_PLATFORM',
      );
    }
  }
}

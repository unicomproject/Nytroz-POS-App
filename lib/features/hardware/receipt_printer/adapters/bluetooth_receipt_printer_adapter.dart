import 'package:flutter/foundation.dart';

import '../models/pos_device_printer_config.dart';
import '../models/printer_exception.dart';
import 'receipt_printer_adapter.dart';

/// Bluetooth adapter scaffold. Real BT I/O requires platform plugins and
/// must be verified on physical hardware before production use.
class BluetoothReceiptPrinterAdapter implements ReceiptPrinterAdapter {
  bool _connected = false;

  @override
  PrinterConnectionType get connectionType => PrinterConnectionType.bluetooth;

  @override
  Future<void> connect(PosDevicePrinterConfig config) async {
    if (kIsWeb) {
      throw const PrinterUnsupportedException(
        'Bluetooth receipt printing is not supported on web.',
      );
    }
    if (defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.linux) {
      // Desktop BT support varies widely; keep failure explicit.
    }
    final address = config.bluetoothAddress?.trim() ?? '';
    if (address.isEmpty) {
      throw const PrinterNotConfiguredException(
        'Bluetooth printer address is not configured for this device.',
      );
    }

    throw const PrinterUnsupportedException(
      'Bluetooth receipt printing is configured but not verified on this platform build. '
      'PHYSICAL_PRINTER_VERIFICATION: NOT_VERIFIED',
    );
  }

  @override
  Future<void> checkStatus(PosDevicePrinterConfig config) async {
    if (!_connected) {
      await connect(config);
    }
  }

  @override
  Future<void> printBytes(
    PosDevicePrinterConfig config,
    List<int> bytes,
  ) async {
    await checkStatus(config);
    throw const PrinterSendException(
      'Bluetooth printer send is not available until hardware verification completes.',
    );
  }

  @override
  Future<void> disconnect() async {
    _connected = false;
  }
}

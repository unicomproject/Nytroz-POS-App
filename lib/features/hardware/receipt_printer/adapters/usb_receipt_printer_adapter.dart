import 'package:flutter/foundation.dart';

import '../models/pos_device_printer_config.dart';
import '../models/printer_exception.dart';
import 'receipt_printer_adapter.dart';

/// USB adapter scaffold. Real OTG/spooler I/O requires platform plugins and
/// must be verified on physical hardware before production use.
class UsbReceiptPrinterAdapter implements ReceiptPrinterAdapter {
  bool _connected = false;

  @override
  PrinterConnectionType get connectionType => PrinterConnectionType.usb;

  @override
  Future<void> connect(PosDevicePrinterConfig config) async {
    if (kIsWeb) {
      throw const PrinterUnsupportedException(
        'USB receipt printing is not supported on web.',
      );
    }
    if (config.usbVendorId == null || config.usbProductId == null) {
      throw const PrinterNotConfiguredException(
        'USB printer vendor/product IDs are not configured for this device.',
      );
    }

    // Platform USB transport is not yet bound to a verified plugin.
    // Fail safely rather than claiming a successful hardware send.
    throw const PrinterUnsupportedException(
      'USB receipt printing is configured but not verified on this platform build. '
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
      'USB printer send is not available until hardware verification completes.',
    );
  }

  @override
  Future<void> disconnect() async {
    _connected = false;
  }
}

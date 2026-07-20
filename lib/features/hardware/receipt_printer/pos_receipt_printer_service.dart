import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../returns_refunds/domain/entities/return_receipt.dart';
import 'adapters/bluetooth_receipt_printer_adapter.dart';
import 'adapters/network_receipt_printer_adapter.dart';
import 'adapters/receipt_printer_adapter.dart';
import 'adapters/usb_receipt_printer_adapter.dart';
import 'config/pos_device_printer_config_store.dart';
import 'esc_pos/esc_pos_receipt_generator.dart';
import 'models/pos_device_printer_config.dart';
import 'models/printer_exception.dart';

typedef PosPrinterConfigLoader = Future<PosDevicePrinterConfig?> Function(
  String deviceId,
);

class PosReceiptPrinterService {
  PosReceiptPrinterService({
    required PosPrinterConfigLoader loadConfiguration,
    EscPosReceiptGenerator generator = const EscPosReceiptGenerator(),
    ReceiptPrinterAdapter? usbAdapter,
    ReceiptPrinterAdapter? bluetoothAdapter,
    ReceiptPrinterAdapter? networkAdapter,
  })  : _loadConfiguration = loadConfiguration,
        _generator = generator,
        _usbAdapter = usbAdapter ?? UsbReceiptPrinterAdapter(),
        _bluetoothAdapter =
            bluetoothAdapter ?? BluetoothReceiptPrinterAdapter(),
        _networkAdapter = networkAdapter ?? NetworkReceiptPrinterAdapter();

  final PosPrinterConfigLoader _loadConfiguration;
  final EscPosReceiptGenerator _generator;
  final ReceiptPrinterAdapter _usbAdapter;
  final ReceiptPrinterAdapter _bluetoothAdapter;
  final ReceiptPrinterAdapter _networkAdapter;

  Future<PosDevicePrinterConfig?> loadConfiguration(String deviceId) {
    return _loadConfiguration(deviceId);
  }

  ReceiptPrinterAdapter selectAdapter(PosDevicePrinterConfig config) {
    switch (config.connectionType) {
      case PrinterConnectionType.usb:
        return _usbAdapter;
      case PrinterConnectionType.bluetooth:
        return _bluetoothAdapter;
      case PrinterConnectionType.network:
        return _networkAdapter;
    }
  }

  Future<void> printCompletionReceipt({
    required String deviceId,
    required ReturnReceipt receipt,
  }) async {
    final config = await loadConfiguration(deviceId);
    if (config == null || !config.enabled) {
      throw const PrinterNotConfiguredException();
    }
    if (config.deviceId.trim().isNotEmpty &&
        config.deviceId.trim() != deviceId.trim()) {
      throw const PrinterNotConfiguredException(
        'Printer configuration does not belong to the current POS device.',
      );
    }

    final adapter = selectAdapter(config);
    // Only one transport runs per print action.
    try {
      await adapter.connect(config);
      await adapter.checkStatus(config);
      final bytes = _generator.generate(receipt: receipt, config: config);
      await adapter.printBytes(config, bytes);
    } finally {
      await adapter.disconnect();
    }
  }
}

final posReceiptPrinterServiceProvider = Provider<PosReceiptPrinterService>((ref) {
  final store = ref.watch(posDevicePrinterConfigStoreProvider);
  return PosReceiptPrinterService(
    loadConfiguration: store.load,
  );
});

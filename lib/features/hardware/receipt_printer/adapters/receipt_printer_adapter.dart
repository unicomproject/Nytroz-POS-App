import '../models/pos_device_printer_config.dart';

abstract class ReceiptPrinterAdapter {
  PrinterConnectionType get connectionType;

  Future<void> connect(PosDevicePrinterConfig config);

  Future<void> checkStatus(PosDevicePrinterConfig config);

  Future<void> printBytes(
    PosDevicePrinterConfig config,
    List<int> bytes,
  );

  Future<void> disconnect();
}

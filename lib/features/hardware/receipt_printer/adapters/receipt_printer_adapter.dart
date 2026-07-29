import '../models/pos_device_printer_config.dart';
import '../models/local_print_agent_models.dart';

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

/// Capability implemented only by transports accepting the structured Local
/// Print Agent receipt contract.
abstract interface class StructuredReceiptPrinterAdapter {
  Future<LocalPrintAgentPrintResult> printStructuredReceipt(
    PosDevicePrinterConfig config,
    LocalPrintAgentReceiptRequest request,
  );
}

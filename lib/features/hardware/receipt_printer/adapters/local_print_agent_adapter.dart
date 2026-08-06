import '../clients/local_print_agent_client.dart';
import '../models/local_print_agent_models.dart';
import '../models/pos_device_printer_config.dart';
import '../models/printer_exception.dart';
import 'receipt_printer_adapter.dart';

class LocalPrintAgentAdapter
    implements ReceiptPrinterAdapter, StructuredReceiptPrinterAdapter {
  LocalPrintAgentAdapter(this._client);

  final LocalPrintAgentClient _client;

  @override
  PrinterConnectionType get connectionType =>
      PrinterConnectionType.localPrintAgent;

  Future<LocalPrintAgentHealth> getHealth(PosDevicePrinterConfig config) {
    return _client.health(config);
  }

  @override
  Future<LocalPrintAgentPrintResult> printStructuredReceipt(
    PosDevicePrinterConfig config,
    LocalPrintAgentReceiptRequest request,
  ) {
    return _client.printReceipt(config, request);
  }

  @override
  Future<void> connect(PosDevicePrinterConfig config) async {
    // HTTP requests are connection-scoped; no persistent socket is retained.
  }

  @override
  Future<void> checkStatus(PosDevicePrinterConfig config) async {
    final health = await getHealth(config);
    if (!health.ready) {
      throw PrinterConnectionException(
        health.detail ?? 'The Windows printer is not ready.',
      );
    }
  }

  @override
  Future<void> printBytes(
    PosDevicePrinterConfig config,
    List<int> bytes,
  ) {
    throw const PrinterUnsupportedException(
      'Local Print Agent requires a structured receipt request.',
    );
  }

  @override
  Future<void> disconnect() async {}
}

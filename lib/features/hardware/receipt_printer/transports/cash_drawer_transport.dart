import '../adapters/bluetooth_receipt_printer_adapter.dart';
import '../adapters/usb_receipt_printer_adapter.dart';
import '../clients/local_print_agent_client.dart';
import '../esc_pos/esc_pos_drawer_pulse_builder.dart';
import '../models/local_print_agent_models.dart';
import '../models/pos_device_printer_config.dart';
import '../models/printer_exception.dart';

enum CashDrawerTransportKind {
  androidUsb,
  androidBluetooth,
  localPrintAgent,
  unsupported,
}

class CashDrawerPulseRequest {
  const CashDrawerPulseRequest({
    required this.requestId,
    required this.drawerOperationId,
    required this.purpose,
    required this.drawerPort,
    required this.pulseOnMilliseconds,
    required this.pulseOffMilliseconds,
    this.printerName,
    this.configurationId,
    this.configurationVersion,
    this.posDeviceId,
  });

  final String requestId;
  final String drawerOperationId;
  final LocalPrintAgentDrawerPurpose purpose;
  final String drawerPort;
  final int pulseOnMilliseconds;
  final int pulseOffMilliseconds;
  final String? printerName;
  final String? configurationId;
  final int? configurationVersion;
  final String? posDeviceId;
}

class CashDrawerPulseResult {
  const CashDrawerPulseResult({
    required this.transportKind,
    required this.transportAccepted,
    this.message = '',
  });

  final CashDrawerTransportKind transportKind;
  final bool transportAccepted;
  final String message;
}

/// Routes drawer pulse to the configured receipt-printer transport.
///
/// Business policy/idempotency stay outside this class.
class CashDrawerTransport {
  CashDrawerTransport({
    LocalPrintAgentClient? localPrintAgentClient,
    UsbReceiptPrinterAdapter? usbAdapter,
    BluetoothReceiptPrinterAdapter? bluetoothAdapter,
    EscPosDrawerPulseBuilder pulseBuilder = const EscPosDrawerPulseBuilder(),
  })  : _agent = localPrintAgentClient ?? LocalPrintAgentClient(),
        _usb = usbAdapter ?? UsbReceiptPrinterAdapter(),
        _bluetooth = bluetoothAdapter ?? BluetoothReceiptPrinterAdapter(),
        _pulseBuilder = pulseBuilder;

  final LocalPrintAgentClient _agent;
  final UsbReceiptPrinterAdapter _usb;
  final BluetoothReceiptPrinterAdapter _bluetooth;
  final EscPosDrawerPulseBuilder _pulseBuilder;

  CashDrawerTransportKind resolveKind(PosDevicePrinterConfig config) {
    return switch (config.connectionType) {
      PrinterConnectionType.usb => CashDrawerTransportKind.androidUsb,
      PrinterConnectionType.bluetooth =>
        CashDrawerTransportKind.androidBluetooth,
      PrinterConnectionType.localPrintAgent =>
        CashDrawerTransportKind.localPrintAgent,
      _ => CashDrawerTransportKind.unsupported,
    };
  }

  Future<CashDrawerPulseResult> open(
    PosDevicePrinterConfig printerConfig,
    CashDrawerPulseRequest request,
  ) async {
    final kind = resolveKind(printerConfig);
    switch (kind) {
      case CashDrawerTransportKind.localPrintAgent:
        final result = await _agent.openDrawer(
          printerConfig,
          LocalPrintAgentDrawerOpenRequest(
            requestId: request.requestId,
            drawerOperationId: request.drawerOperationId,
            purpose: request.purpose,
            printerName: request.printerName ??
                printerConfig.agentPrinterName ??
                printerConfig.displayName,
            drawerPort: request.drawerPort,
            pulseOnMilliseconds: request.pulseOnMilliseconds,
            pulseOffMilliseconds: request.pulseOffMilliseconds,
            configurationId: request.configurationId,
            configurationVersion: request.configurationVersion,
            posDeviceId: request.posDeviceId,
          ),
        );
        return CashDrawerPulseResult(
          transportKind: kind,
          transportAccepted: result.success,
          message: result.message,
        );
      case CashDrawerTransportKind.androidUsb:
        return _pulseDirect(
          kind: kind,
          adapterConnect: () => _usb.connect(printerConfig),
          adapterWrite: (bytes) => _usb.printBytes(printerConfig, bytes),
          adapterDisconnect: _usb.disconnect,
          request: request,
        );
      case CashDrawerTransportKind.androidBluetooth:
        return _pulseDirect(
          kind: kind,
          adapterConnect: () => _bluetooth.connect(printerConfig),
          adapterWrite: (bytes) => _bluetooth.printBytes(printerConfig, bytes),
          adapterDisconnect: _bluetooth.disconnect,
          request: request,
        );
      case CashDrawerTransportKind.unsupported:
        throw const PrinterUnsupportedException(
          'Configured receipt printer transport does not support cash drawer pulse.',
        );
    }
  }

  Future<CashDrawerPulseResult> _pulseDirect({
    required CashDrawerTransportKind kind,
    required Future<void> Function() adapterConnect,
    required Future<void> Function(List<int> bytes) adapterWrite,
    required Future<void> Function() adapterDisconnect,
    required CashDrawerPulseRequest request,
  }) async {
    final bytes = _pulseBuilder.build(
      drawerPort: request.drawerPort,
      pulseOnMilliseconds: request.pulseOnMilliseconds,
      pulseOffMilliseconds: request.pulseOffMilliseconds,
    );
    try {
      await adapterConnect();
      await adapterWrite(bytes);
      return CashDrawerPulseResult(
        transportKind: kind,
        transportAccepted: true,
        message:
            'Drawer pulse accepted by printer transport. Confirm physical open.',
      );
    } finally {
      await adapterDisconnect();
    }
  }
}

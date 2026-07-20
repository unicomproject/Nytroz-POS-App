import '../models/pos_device_printer_config.dart';
import '../models/printer_exception.dart';
import 'network_socket.dart' as net;
import 'receipt_printer_adapter.dart';

class NetworkReceiptPrinterAdapter implements ReceiptPrinterAdapter {
  net.NetworkSocket? _socket;

  @override
  PrinterConnectionType get connectionType => PrinterConnectionType.network;

  @override
  Future<void> connect(PosDevicePrinterConfig config) async {
    final host = config.networkHost?.trim() ?? '';
    if (host.isEmpty) {
      throw const PrinterNotConfiguredException(
        'Network printer host/IP is not configured for this device.',
      );
    }

    try {
      await disconnect();
      _socket = await net.NetworkSocket.connect(
        host,
        config.networkPort,
        timeout: Duration(milliseconds: config.connectionTimeoutMs),
      );
    } on UnsupportedError catch (error) {
      throw PrinterUnsupportedException(error.message ?? error.toString());
    } catch (error) {
      throw PrinterConnectionException(
        'Network printer unreachable at $host:${config.networkPort}. $error',
      );
    }
  }

  @override
  Future<void> checkStatus(PosDevicePrinterConfig config) async {
    if (_socket == null) {
      await connect(config);
    }
  }

  @override
  Future<void> printBytes(
    PosDevicePrinterConfig config,
    List<int> bytes,
  ) async {
    await checkStatus(config);
    final socket = _socket;
    if (socket == null) {
      throw const PrinterConnectionException(
        'Network printer is not connected.',
      );
    }

    try {
      socket.add(bytes);
      await socket.flush();
    } catch (error) {
      throw PrinterSendException(
        'Failed to send receipt to network printer. $error',
      );
    }
  }

  @override
  Future<void> disconnect() async {
    final socket = _socket;
    _socket = null;
    if (socket == null) {
      return;
    }
    try {
      await socket.close();
    } catch (_) {
      // Ignore close failures after a successful send.
    }
  }
}

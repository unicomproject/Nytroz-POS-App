import '../models/pos_device_printer_config.dart';
import '../models/printer_exception.dart';
import '../platform/android_receipt_printer_platform.dart';
import 'receipt_printer_adapter.dart';
import 'usb_receipt_printer_adapter.dart';

/// Android Bluetooth Classic (RFCOMM/SPP) ESC/POS transport.
class BluetoothReceiptPrinterAdapter implements ReceiptPrinterAdapter {
  BluetoothReceiptPrinterAdapter({
    AndroidReceiptPrinterPlatform? platform,
    DirectPrinterWriteGate? writeGate,
  })  : _platform = platform ?? MethodChannelAndroidReceiptPrinter(),
        _writeGate = writeGate ?? DirectPrinterWriteGate();

  final AndroidReceiptPrinterPlatform _platform;
  final DirectPrinterWriteGate _writeGate;
  bool _connected = false;
  String? _connectedAddress;

  @override
  PrinterConnectionType get connectionType => PrinterConnectionType.bluetooth;

  @override
  Future<void> connect(PosDevicePrinterConfig config) async {
    _ensureAndroidBluetoothSupported();
    final address = config.bluetoothAddress?.trim().toUpperCase() ?? '';
    if (address.isEmpty) {
      throw const PrinterNotConfiguredException(
        'Bluetooth printer address is not configured for this device.',
      );
    }

    final enabled = await _platform.bluetoothIsEnabled();
    if (!enabled) {
      throw const PrinterConnectionException(
        'Bluetooth is turned off on this device.',
      );
    }

    final bonded = await _platform.bluetoothListBonded();
    final match = bonded.where((d) => d.address == address).toList();
    if (match.isEmpty) {
      throw PrinterDeviceNotFoundException(
        'Bluetooth printer $address is not paired. Pair it in Android settings first.',
      );
    }

    await _platform.bluetoothConnect(
      address: address,
      timeoutMs: config.connectionTimeoutMs.clamp(1000, 60000),
    );
    _connected = true;
    _connectedAddress = address;
  }

  @override
  Future<void> checkStatus(PosDevicePrinterConfig config) async {
    if (!_connected ||
        _connectedAddress !=
            config.bluetoothAddress?.trim().toUpperCase()) {
      await connect(config);
    }
  }

  @override
  Future<void> printBytes(
    PosDevicePrinterConfig config,
    List<int> bytes,
  ) async {
    await checkStatus(config);
    final address = config.bluetoothAddress?.trim().toUpperCase() ?? '';
    if (address.isEmpty) {
      throw const PrinterNotConfiguredException(
        'Bluetooth printer address is not configured for this device.',
      );
    }
    if (bytes.isEmpty) {
      throw const PrinterConfigurationException(
        'Cannot print an empty ESC/POS payload.',
      );
    }

    await _writeGate.runExclusive(() async {
      final written = await _platform.bluetoothWrite(
        address: address,
        bytes: bytes,
        timeoutMs: config.connectionTimeoutMs.clamp(1000, 60000),
      );
      if (written != bytes.length) {
        throw PrinterPartialWriteException(
          'Bluetooth write incomplete: wrote $written of ${bytes.length} bytes.',
        );
      }
    });
  }

  @override
  Future<void> disconnect() async {
    _connected = false;
    _connectedAddress = null;
    await _platform.bluetoothDisconnect();
  }

  void _ensureAndroidBluetoothSupported() {
    if (!MethodChannelAndroidReceiptPrinter.isAndroidNative) {
      throw const PrinterUnsupportedException(
        'Bluetooth receipt printing requires Android. UNSUPPORTED_PLATFORM',
      );
    }
  }
}

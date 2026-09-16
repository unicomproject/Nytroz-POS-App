import '../../../hardware/receipt_printer/platform/android_receipt_printer_platform.dart';

class HardwareDiscoveryResult {
  const HardwareDiscoveryResult(this.devices, this.message);
  final List<DiscoveredHardware> devices;
  final String message;
}

class DiscoveredHardware {
  const DiscoveredHardware(this.name, this.connection, this.identity,
      {this.manufacturer = '', this.model = '', this.usb});
  final String name, connection, manufacturer, model;
  final Map<String, dynamic> identity;
  final AndroidUsbPrinterDevice? usb;
}

/// Discovery is local to this Android host. Enumeration is not a connection test.
class HardwareSetupDiscoveryService {
  HardwareSetupDiscoveryService([MethodChannelAndroidReceiptPrinter? platform])
      : _platform = platform ?? MethodChannelAndroidReceiptPrinter();
  final MethodChannelAndroidReceiptPrinter _platform;

  Future<HardwareDiscoveryResult> discover(
      String type, String connection) async {
    if (type != 'RECEIPT_PRINTER') {
      return const HardwareDiscoveryResult([],
          'Use manual setup for HID scanners and printer-attached drawers. Verify actual input on the assigned POS.');
    }
    final capability = await _platform.getCapabilities();
    if (!capability.isAndroid) {
      return const HardwareDiscoveryResult([],
          'Discovery requires the Android app on the hardware host. Use manual setup here.');
    }
    if (connection == 'USB' && capability.usbHost) {
      final devices = await _platform.usbListDevices();
      return HardwareDiscoveryResult([
        for (final d in devices)
          DiscoveredHardware(
              d.label,
              'USB',
              {
                'usbVendorId': d.vendorId,
                'usbProductId': d.productId,
                'usbDeviceName': d.deviceName,
              },
              manufacturer: d.manufacturerName ?? '',
              model: d.productName ?? '',
              usb: d),
      ], 'USB enumeration completed. Model compatibility still requires verification.');
    }
    if (connection == 'BLUETOOTH' && capability.bluetoothClassic) {
      final devices = await _platform.bluetoothListBonded();
      return HardwareDiscoveryResult([
        for (final d in devices)
          DiscoveredHardware(d.name ?? 'Bluetooth device', 'BLUETOOTH',
              {'bluetoothAddress': d.address}),
      ], 'Already-paired devices only. Pair in Android settings first; no connection is claimed.');
    }
    return const HardwareDiscoveryResult([],
        'Use a manual endpoint for this connection. Automatic discovery is unavailable.');
  }

  Future<bool> select(DiscoveredHardware device) async {
    final usb = device.usb;
    return usb == null ||
        usb.hasPermission ||
        await _platform.usbRequestPermission(usb.deviceName);
  }
}

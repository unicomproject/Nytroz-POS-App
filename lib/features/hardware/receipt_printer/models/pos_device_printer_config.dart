enum PrinterConnectionType {
  usb,
  bluetooth,
  network,
}

enum PrinterPaperWidth {
  mm58,
  mm80,
}

class PosDevicePrinterConfig {
  const PosDevicePrinterConfig({
    required this.deviceId,
    required this.enabled,
    required this.connectionType,
    required this.displayName,
    required this.paperWidth,
    this.escPosProfile = 'default',
    this.autoCutEnabled = true,
    this.usbVendorId,
    this.usbProductId,
    this.usbDeviceIdentifier,
    this.bluetoothAddress,
    this.bluetoothDeviceName,
    this.networkHost,
    this.networkPort = 9100,
    this.connectionTimeoutMs = 5000,
  });

  final String deviceId;
  final bool enabled;
  final PrinterConnectionType connectionType;
  final String displayName;
  final PrinterPaperWidth paperWidth;
  final String escPosProfile;
  final bool autoCutEnabled;
  final int? usbVendorId;
  final int? usbProductId;
  final String? usbDeviceIdentifier;
  final String? bluetoothAddress;
  final String? bluetoothDeviceName;
  final String? networkHost;
  final int networkPort;
  final int connectionTimeoutMs;

  factory PosDevicePrinterConfig.fromJson(Map<String, dynamic> json) {
    return PosDevicePrinterConfig(
      deviceId: (json['deviceId'] ?? '').toString(),
      enabled: json['enabled'] == true,
      connectionType: _parseConnectionType(json['connectionType']?.toString()),
      displayName: (json['displayName'] ?? 'Receipt Printer').toString(),
      paperWidth: _parsePaperWidth(json['paperWidth']?.toString()),
      escPosProfile: (json['escPosProfile'] ?? 'default').toString(),
      autoCutEnabled: json['autoCutEnabled'] != false,
      usbVendorId: _readInt(json['usbVendorId']),
      usbProductId: _readInt(json['usbProductId']),
      usbDeviceIdentifier: _readOptionalString(json['usbDeviceIdentifier']),
      bluetoothAddress: _readOptionalString(json['bluetoothAddress']),
      bluetoothDeviceName: _readOptionalString(json['bluetoothDeviceName']),
      networkHost: _readOptionalString(json['networkHost']),
      networkPort: _readInt(json['networkPort']) ?? 9100,
      connectionTimeoutMs: _readInt(json['connectionTimeoutMs']) ?? 5000,
    );
  }

  Map<String, dynamic> toJson() => {
        'deviceId': deviceId,
        'enabled': enabled,
        'connectionType': connectionType.name.toUpperCase(),
        'displayName': displayName,
        'paperWidth': paperWidth == PrinterPaperWidth.mm58 ? '58mm' : '80mm',
        'escPosProfile': escPosProfile,
        'autoCutEnabled': autoCutEnabled,
        'usbVendorId': usbVendorId,
        'usbProductId': usbProductId,
        'usbDeviceIdentifier': usbDeviceIdentifier,
        'bluetoothAddress': bluetoothAddress,
        'bluetoothDeviceName': bluetoothDeviceName,
        'networkHost': networkHost,
        'networkPort': networkPort,
        'connectionTimeoutMs': connectionTimeoutMs,
      };

  static PrinterConnectionType _parseConnectionType(String? value) {
    switch ((value ?? '').trim().toUpperCase()) {
      case 'BLUETOOTH':
        return PrinterConnectionType.bluetooth;
      case 'NETWORK':
      case 'LAN':
      case 'WIFI':
      case 'WI-FI':
        return PrinterConnectionType.network;
      default:
        return PrinterConnectionType.usb;
    }
  }

  static PrinterPaperWidth _parsePaperWidth(String? value) {
    final normalized = (value ?? '').trim().toLowerCase();
    if (normalized.contains('58')) {
      return PrinterPaperWidth.mm58;
    }
    return PrinterPaperWidth.mm80;
  }

  static int? _readInt(Object? value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    return int.tryParse(value?.toString() ?? '');
  }

  static String? _readOptionalString(Object? value) {
    if (value == null) {
      return null;
    }
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }
}

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../models/printer_exception.dart';

class AndroidUsbPrinterDevice {
  const AndroidUsbPrinterDevice({
    required this.deviceName,
    required this.vendorId,
    required this.productId,
    required this.hasPermission,
    this.manufacturerName,
    this.productName,
    this.serialNumber,
    this.deviceClass,
    this.maxPacketSize,
  });

  final String deviceName;
  final int vendorId;
  final int productId;
  final bool hasPermission;
  final String? manufacturerName;
  final String? productName;
  final String? serialNumber;
  final int? deviceClass;
  final int? maxPacketSize;

  String get label {
    final name = productName?.trim();
    if (name != null && name.isNotEmpty) return name;
    return 'USB ${vendorId.toRadixString(16)}:${productId.toRadixString(16)}';
  }

  factory AndroidUsbPrinterDevice.fromMap(Map<Object?, Object?> map) {
    return AndroidUsbPrinterDevice(
      deviceName: '${map['deviceName'] ?? ''}',
      vendorId: (map['vendorId'] as num?)?.toInt() ?? 0,
      productId: (map['productId'] as num?)?.toInt() ?? 0,
      hasPermission: map['hasPermission'] == true,
      manufacturerName: _opt(map['manufacturerName']),
      productName: _opt(map['productName']),
      serialNumber: _opt(map['serialNumber']),
      deviceClass: (map['deviceClass'] as num?)?.toInt(),
      maxPacketSize: (map['maxPacketSize'] as num?)?.toInt(),
    );
  }
}

class AndroidBluetoothPrinterDevice {
  const AndroidBluetoothPrinterDevice({
    required this.address,
    this.name,
    this.bondState,
    this.type,
  });

  final String address;
  final String? name;
  final int? bondState;
  final int? type;

  String get label {
    final n = name?.trim();
    if (n != null && n.isNotEmpty) return '$n ($address)';
    return address;
  }

  factory AndroidBluetoothPrinterDevice.fromMap(Map<Object?, Object?> map) {
    return AndroidBluetoothPrinterDevice(
      address: '${map['address'] ?? ''}'.toUpperCase(),
      name: _opt(map['name']),
      bondState: (map['bondState'] as num?)?.toInt(),
      type: (map['type'] as num?)?.toInt(),
    );
  }
}

class AndroidReceiptPrinterCapabilities {
  const AndroidReceiptPrinterCapabilities({
    required this.platform,
    required this.usbHost,
    required this.bluetoothClassic,
    this.sdkInt,
  });

  final String platform;
  final bool usbHost;
  final bool bluetoothClassic;
  final int? sdkInt;

  bool get isAndroid => platform == 'android';
}

/// Injectable MethodChannel facade for Android USB Host + Bluetooth Classic SPP.
abstract class AndroidReceiptPrinterPlatform {
  Future<AndroidReceiptPrinterCapabilities> getCapabilities();
  Future<List<AndroidUsbPrinterDevice>> usbListDevices();
  Future<bool> usbHasPermission(String deviceName);
  Future<bool> usbRequestPermission(String deviceName);
  Future<int> usbWrite({
    required int vendorId,
    required int productId,
    required List<int> bytes,
    required int timeoutMs,
    String? deviceName,
    String? serialNumber,
  });
  Future<bool> bluetoothIsEnabled();
  Future<List<AndroidBluetoothPrinterDevice>> bluetoothListBonded();
  Future<void> bluetoothConnect({
    required String address,
    required int timeoutMs,
  });
  Future<int> bluetoothWrite({
    required String address,
    required List<int> bytes,
    required int timeoutMs,
  });
  Future<void> bluetoothDisconnect();
}

class MethodChannelAndroidReceiptPrinter
    implements AndroidReceiptPrinterPlatform {
  MethodChannelAndroidReceiptPrinter({
    MethodChannel? channel,
  }) : _channel = channel ??
            const MethodChannel('com.nytroz.pos/receipt_printer');

  final MethodChannel _channel;

  static bool get isAndroidNative =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  @override
  Future<AndroidReceiptPrinterCapabilities> getCapabilities() async {
    if (!isAndroidNative) {
      return const AndroidReceiptPrinterCapabilities(
        platform: 'unsupported',
        usbHost: false,
        bluetoothClassic: false,
      );
    }
    try {
      final raw = await _channel.invokeMethod<Map<Object?, Object?>>(
        'getCapabilities',
      );
      final map = raw ?? const <Object?, Object?>{};
      return AndroidReceiptPrinterCapabilities(
        platform: '${map['platform'] ?? 'android'}',
        usbHost: map['usbHost'] == true,
        bluetoothClassic: map['bluetoothClassic'] == true,
        sdkInt: (map['sdkInt'] as num?)?.toInt(),
      );
    } on MissingPluginException {
      return const AndroidReceiptPrinterCapabilities(
        platform: 'android',
        usbHost: false,
        bluetoothClassic: false,
      );
    }
  }

  @override
  Future<List<AndroidUsbPrinterDevice>> usbListDevices() async {
    _ensureAndroid();
    final raw = await _invokeList('usbListDevices');
    return raw
        .map(AndroidUsbPrinterDevice.fromMap)
        .where((d) => d.deviceName.isNotEmpty)
        .toList(growable: false);
  }

  @override
  Future<bool> usbHasPermission(String deviceName) async {
    _ensureAndroid();
    final result = await _channel.invokeMethod<bool>(
      'usbHasPermission',
      {'deviceName': deviceName},
    );
    return result == true;
  }

  @override
  Future<bool> usbRequestPermission(String deviceName) async {
    _ensureAndroid();
    try {
      final result = await _channel.invokeMethod<bool>(
        'usbRequestPermission',
        {'deviceName': deviceName},
      );
      return result == true;
    } on PlatformException catch (error) {
      throw _mapPlatformException(error);
    }
  }

  @override
  Future<int> usbWrite({
    required int vendorId,
    required int productId,
    required List<int> bytes,
    required int timeoutMs,
    String? deviceName,
    String? serialNumber,
  }) async {
    _ensureAndroid();
    try {
      final result = await _channel.invokeMethod<Map<Object?, Object?>>(
        'usbWrite',
        {
          'vendorId': vendorId,
          'productId': productId,
          'deviceName': deviceName,
          'serialNumber': serialNumber,
          'timeoutMs': timeoutMs,
          'bytes': Uint8List.fromList(bytes),
        },
      );
      return (result?['bytesWritten'] as num?)?.toInt() ?? 0;
    } on PlatformException catch (error) {
      throw _mapPlatformException(error);
    }
  }

  @override
  Future<bool> bluetoothIsEnabled() async {
    _ensureAndroid();
    final result = await _channel.invokeMethod<bool>('bluetoothIsEnabled');
    return result == true;
  }

  @override
  Future<List<AndroidBluetoothPrinterDevice>> bluetoothListBonded() async {
    _ensureAndroid();
    try {
      final raw = await _invokeList('bluetoothListBonded');
      return raw
          .map(AndroidBluetoothPrinterDevice.fromMap)
          .where((d) => d.address.isNotEmpty)
          .toList(growable: false);
    } on PlatformException catch (error) {
      throw _mapPlatformException(error);
    }
  }

  @override
  Future<void> bluetoothConnect({
    required String address,
    required int timeoutMs,
  }) async {
    _ensureAndroid();
    try {
      await _channel.invokeMethod<Map<Object?, Object?>>(
        'bluetoothConnect',
        {'address': address, 'timeoutMs': timeoutMs},
      );
    } on PlatformException catch (error) {
      throw _mapPlatformException(error);
    }
  }

  @override
  Future<int> bluetoothWrite({
    required String address,
    required List<int> bytes,
    required int timeoutMs,
  }) async {
    _ensureAndroid();
    try {
      final result = await _channel.invokeMethod<Map<Object?, Object?>>(
        'bluetoothWrite',
        {
          'address': address,
          'timeoutMs': timeoutMs,
          'bytes': Uint8List.fromList(bytes),
        },
      );
      return (result?['bytesWritten'] as num?)?.toInt() ?? 0;
    } on PlatformException catch (error) {
      throw _mapPlatformException(error);
    }
  }

  @override
  Future<void> bluetoothDisconnect() async {
    if (!isAndroidNative) return;
    try {
      await _channel.invokeMethod<Map<Object?, Object?>>('bluetoothDisconnect');
    } on PlatformException {
      // Best-effort disconnect.
    } on MissingPluginException {
      // No-op on hosts without the plugin.
    }
  }

  Future<List<Map<Object?, Object?>>> _invokeList(String method) async {
    final raw = await _channel.invokeMethod<List<Object?>>(method);
    return (raw ?? const <Object?>[])
        .whereType<Map>()
        .map((item) => item.cast<Object?, Object?>())
        .toList(growable: false);
  }

  void _ensureAndroid() {
    if (!isAndroidNative) {
      throw const PrinterUnsupportedException(
        'Android USB/Bluetooth receipt printing is not supported on this platform. '
        'UNSUPPORTED_PLATFORM',
      );
    }
  }

  PrinterException _mapPlatformException(PlatformException error) {
    final code = (error.code).trim().toUpperCase();
    final message = error.message?.trim().isNotEmpty == true
        ? error.message!.trim()
        : 'Android printer operation failed ($code).';
    return switch (code) {
      'PERMISSION_DENIED' => PrinterPermissionDeniedException(message),
      'DEVICE_NOT_FOUND' => PrinterDeviceNotFoundException(message),
      'NOT_CONNECTED' ||
      'CONNECTION_FAILED' ||
      'INTERFACE_CLAIM_FAILED' ||
      'ENDPOINT_UNAVAILABLE' ||
      'BLUETOOTH_DISABLED' ||
      'MULTIPLE_DEVICES' =>
        PrinterConnectionException(message),
      'TIMEOUT' => PrinterTimeoutException(message),
      'PARTIAL_WRITE' => PrinterPartialWriteException(message),
      'WRITE_FAILED' => PrinterSendException(message),
      'NOT_CONFIGURED' || 'INVALID_ARGUMENT' =>
        PrinterConfigurationException(message),
      'UNSUPPORTED_PLATFORM' => PrinterUnsupportedException(message),
      _ => PrinterSendException(message),
    };
  }
}

String? _opt(Object? value) {
  if (value == null) return null;
  final text = value.toString().trim();
  return text.isEmpty ? null : text;
}

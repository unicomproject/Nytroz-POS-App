import 'package:flutter/foundation.dart';
import 'package:device_info_plus/device_info_plus.dart';

/// HTTP port from `launchSettings.json` (`applicationUrl`).
const int kBackendHttpPort = 5150;

class ApiConfig {
  static const String _envBaseUrl = String.fromEnvironment('API_BASE_URL');
  static const String _envPcLanIp = String.fromEnvironment('PC_LAN_IP');
  static const String _loopbackBaseUrl = 'http://127.0.0.1:$kBackendHttpPort';
  static const String _androidEmulatorBaseUrl =
      'http://10.0.2.2:$kBackendHttpPort';

  /// Resolves the API base URL for the current platform.
  ///
  /// Development defaults:
  /// - Web/Windows/macOS: `http://127.0.0.1:5052`
  /// - Android emulator: `http://10.0.2.2:5052`
  /// - iOS simulator: `http://127.0.0.1:5052`
  /// - Physical device: provide the PC LAN IP with
  ///   `--dart-define=PC_LAN_IP=<PC_LAN_IP>` or override the whole URL with
  ///   `--dart-define=API_BASE_URL=http://<PC_LAN_IP>:5052`
  static Future<String> resolveBaseUrl({
    DeviceInfoPlugin? deviceInfo,
  }) async {
    final envBaseUrl = _envBaseUrl.trim();
    if (envBaseUrl.isNotEmpty) {
      return envBaseUrl;
    }

    if (kIsWeb) {
      return _loopbackBaseUrl;
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        if (await _isAndroidPhysicalDevice(deviceInfo)) {
          return _androidPhysicalDeviceFallback;
        }
        return _androidEmulatorBaseUrl;
      case TargetPlatform.iOS:
        if (await _isIosPhysicalDevice(deviceInfo)) {
          return _iosPhysicalDeviceFallback;
        }
        return _loopbackBaseUrl;
      case TargetPlatform.windows:
      case TargetPlatform.macOS:
        return _loopbackBaseUrl;
      default:
        return _loopbackBaseUrl;
    }
/// Resolves the API base URL for the current platform.
///
/// Development defaults:
/// - Desktop/Web: `http://localhost:5150` or `http://127.0.0.1:5150`
/// - Android emulator: `http://10.0.2.2:5150`
/// - Physical device: `http://<PC-LAN-IP>:5150`
///
/// Override with `--dart-define=API_BASE_URL=http://<host>:<port>` when needed,
/// especially for a real Android tablet/phone on the same network as the PC.
String resolveApiBaseUrl() {
  const envBaseUrl = String.fromEnvironment('API_BASE_URL');
  if (envBaseUrl.isNotEmpty) {
    return envBaseUrl;
  }

  static String get _androidPhysicalDeviceFallback {
    final physicalDeviceBaseUrl = _physicalDeviceBaseUrl;
    if (physicalDeviceBaseUrl != null) {
      return physicalDeviceBaseUrl;
    }

    debugPrint(
      'API_BASE_URL is not set for a physical Android device. '
      'Falling back to $_androidEmulatorBaseUrl. Start Flutter with '
      '--dart-define=PC_LAN_IP=<PC_LAN_IP> or '
      '--dart-define=API_BASE_URL=http://<PC_LAN_IP>:$kBackendHttpPort.',
    );
    return _androidEmulatorBaseUrl;
  }

  static String get _iosPhysicalDeviceFallback {
    final physicalDeviceBaseUrl = _physicalDeviceBaseUrl;
    if (physicalDeviceBaseUrl != null) {
      return physicalDeviceBaseUrl;
    }

    debugPrint(
      'API_BASE_URL is not set for a physical iOS device. '
      'Falling back to $_loopbackBaseUrl. Start Flutter with '
      '--dart-define=PC_LAN_IP=<PC_LAN_IP> or '
      '--dart-define=API_BASE_URL=http://<PC_LAN_IP>:$kBackendHttpPort.',
    );
    return _loopbackBaseUrl;
  }

  static String? get _physicalDeviceBaseUrl {
    final pcLanIp = _envPcLanIp.trim();
    if (pcLanIp.isEmpty) {
      return null;
    }

    return 'http://$pcLanIp:$kBackendHttpPort';
  }

  static Future<bool> _isAndroidPhysicalDevice(
    DeviceInfoPlugin? deviceInfo,
  ) async {
    final info = await (deviceInfo ?? DeviceInfoPlugin()).androidInfo;
    return info.isPhysicalDevice;
  }

  static Future<bool> _isIosPhysicalDevice(
    DeviceInfoPlugin? deviceInfo,
  ) async {
    final info = await (deviceInfo ?? DeviceInfoPlugin()).iosInfo;
    return info.isPhysicalDevice;
  }
}

Future<String> resolveApiBaseUrl() => ApiConfig.resolveBaseUrl();
  switch (defaultTargetPlatform) {
    case TargetPlatform.android:
      return 'http://10.0.2.2:$kBackendHttpPort';
    default:
      return 'http://localhost:$kBackendHttpPort';
  }
}


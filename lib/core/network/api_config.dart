import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';

/// HTTP port from `launchSettings.json` (`applicationUrl`).
const int kBackendHttpPort = 5150;

class ApiConfigurationException implements Exception {
  const ApiConfigurationException(this.message);

  final String message;

  @override
  String toString() => 'API configuration error: $message';
}

class ApiConfig {
  static const String _envBaseUrl = String.fromEnvironment('API_BASE_URL');
  static const String _envPcLanIp = String.fromEnvironment('PC_LAN_IP');
  static const String _desktopDevelopmentBaseUrl =
      'http://localhost:$kBackendHttpPort';
  static const String _androidEmulatorDevelopmentBaseUrl =
      'http://10.0.2.2:$kBackendHttpPort';

  /// Resolves the API URL with this precedence:
  ///
  /// 1. Explicit `API_BASE_URL`.
  /// 2. Explicit `PC_LAN_IP`, expanded with the backend HTTP port.
  /// 3. A platform-specific development fallback.
  ///
  /// Physical devices must be configured explicitly. Release builds never use
  /// a development fallback.
  static Future<String> resolveBaseUrl({
    String? apiBaseUrl,
    String? pcLanIp,
    TargetPlatform? targetPlatform,
    bool? isPhysicalDevice,
    bool? isReleaseMode,
    bool? isWeb,
    DeviceInfoPlugin? deviceInfo,
  }) async {
    final explicitBaseUrl = (apiBaseUrl ?? _envBaseUrl).trim();
    if (explicitBaseUrl.isNotEmpty) {
      return _normalizeAndValidateBaseUrl(
        explicitBaseUrl,
        sourceName: 'API_BASE_URL',
      );
    }

    final explicitPcLanIp = (pcLanIp ?? _envPcLanIp).trim();
    if (explicitPcLanIp.isNotEmpty) {
      final host = _validatePcLanHost(explicitPcLanIp);
      return _normalizeAndValidateBaseUrl(
        'http://$host:$kBackendHttpPort',
        sourceName: 'PC_LAN_IP',
      );
    }

    final releaseMode = isReleaseMode ?? kReleaseMode;
    if (releaseMode) {
      throw const ApiConfigurationException(
        'API_BASE_URL is required in release builds. Development fallback '
        'addresses are disabled.',
      );
    }

    final web = isWeb ?? kIsWeb;
    if (web) {
      return _desktopDevelopmentBaseUrl;
    }

    final platform = targetPlatform ?? defaultTargetPlatform;
    switch (platform) {
      case TargetPlatform.android:
        final physical =
            isPhysicalDevice ?? await _isAndroidPhysicalDevice(deviceInfo);
        if (physical) {
          throw const ApiConfigurationException(
            'A physical Android device cannot use the emulator address '
            '10.0.2.2. Start Flutter with '
            '--dart-define=PC_LAN_IP=<PC_LAN_IP> or '
            '--dart-define=API_BASE_URL=http://<PC_LAN_IP>:5150.',
          );
        }
        return _androidEmulatorDevelopmentBaseUrl;
      case TargetPlatform.iOS:
        final physical =
            isPhysicalDevice ?? await _isIosPhysicalDevice(deviceInfo);
        if (physical) {
          throw const ApiConfigurationException(
            'API_BASE_URL or PC_LAN_IP is required for a physical iOS device.',
          );
        }
        return _desktopDevelopmentBaseUrl;
      case TargetPlatform.windows:
      case TargetPlatform.macOS:
      case TargetPlatform.linux:
      case TargetPlatform.fuchsia:
        return _desktopDevelopmentBaseUrl;
    }
  }

  static String _normalizeAndValidateBaseUrl(
    String value, {
    required String sourceName,
  }) {
    final uri = Uri.tryParse(value);
    if (uri == null ||
        !uri.hasScheme ||
        (uri.scheme != 'http' && uri.scheme != 'https') ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty ||
        uri.hasQuery ||
        uri.hasFragment) {
      throw ApiConfigurationException(
        '$sourceName must be an absolute HTTP(S) URL without credentials, '
        'query parameters, or fragments.',
      );
    }

    final normalizedPath =
        uri.path == '/' ? '' : uri.path.replaceFirst(RegExp(r'/+$'), '');
    return uri.replace(path: normalizedPath).toString();
  }

  static String _validatePcLanHost(String value) {
    if (value.contains('://') ||
        value.contains('/') ||
        value.contains('?') ||
        value.contains('#') ||
        value.contains('@') ||
        value.contains(':')) {
      throw const ApiConfigurationException(
        'PC_LAN_IP must contain only the PC LAN IPv4 address. Use '
        'API_BASE_URL when a scheme, port, or path is required.',
      );
    }

    final parts = value.split('.');
    final isIpv4 = parts.length == 4 &&
        parts.every((part) {
          final octet = int.tryParse(part);
          return octet != null &&
              octet >= 0 &&
              octet <= 255 &&
              part == octet.toString();
        });
    if (!isIpv4) {
      throw const ApiConfigurationException(
        'PC_LAN_IP must be a valid IPv4 address, for example 192.168.1.20.',
      );
    }
    return value;
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

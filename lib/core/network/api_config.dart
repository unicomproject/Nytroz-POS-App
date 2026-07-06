import 'package:flutter/foundation.dart';

/// HTTP port from `SCS.Api/Properties/launchSettings.json` (`applicationUrl`).
const int kBackendHttpPort = 5052;

/// Resolves the API base URL for the current platform.
///
/// Development defaults:
/// - Desktop/Web: `http://localhost:5052` or `http://127.0.0.1:5052`
/// - Android emulator: `http://10.0.2.2:5052`
/// - Physical device: `http://<PC-LAN-IP>:5052`
///
/// Override with `--dart-define=API_BASE_URL=http://<host>:<port>` when needed,
/// especially for a real Android tablet/phone on the same network as the PC.
String resolveApiBaseUrl() {
  const envBaseUrl = String.fromEnvironment('API_BASE_URL');
  if (envBaseUrl.isNotEmpty) {
    return envBaseUrl;
  }

  if (kIsWeb) {
    return 'http://127.0.0.1:$kBackendHttpPort';
  }

  switch (defaultTargetPlatform) {
    case TargetPlatform.android:
      return 'http://127.0.0.1:$kBackendHttpPort';
    default:
      return 'http://localhost:$kBackendHttpPort';
  }
}

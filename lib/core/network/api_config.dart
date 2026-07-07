import 'package:flutter/foundation.dart';

/// HTTP port from `launchSettings.json` (`applicationUrl`).
const int kBackendHttpPort = 5150;

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

  if (kIsWeb) {
    return 'http://127.0.0.1:$kBackendHttpPort';
  }

  switch (defaultTargetPlatform) {
    case TargetPlatform.android:
      return 'http://10.0.2.2:$kBackendHttpPort';
    default:
      return 'http://localhost:$kBackendHttpPort';
  }
}


import 'package:flutter/foundation.dart';

/// HTTP port from `SCS.Api/Properties/launchSettings.json` (`applicationUrl`).
const int kBackendHttpPort = 5050;

/// Resolves the API base URL for the current platform.
///
/// Override with `--dart-define=API_BASE_URL=http://<host>:<port>` when needed
/// (e.g. real Android device: `http://<LAPTOP_LAN_IP>:5050`, or custom backend port).
/// Backend port override: `dotnet run --urls "http://0.0.0.0:5051"` — then match here.
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

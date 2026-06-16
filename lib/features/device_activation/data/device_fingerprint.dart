import 'dart:io' show Platform;

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

String legacyDeviceFingerprint() {
  if (!kIsWeb) {
    return '';
  }

  return 'pos-web-${Uri.base.host}-${Uri.base.port}';
}

String currentDevicePlatform() {
  if (kIsWeb) {
    return 'web';
  }

  if (Platform.isAndroid) {
    return 'android';
  }

  if (Platform.isIOS) {
    return 'ios';
  }

  return 'web';
}

Future<String> createStableDeviceFingerprint() async {
  if (kIsWeb) {
    final legacy = legacyDeviceFingerprint();
    if (legacy.isNotEmpty) {
      return legacy;
    }

    return 'pos-web-unknown';
  }

  final plugin = DeviceInfoPlugin();

  if (Platform.isAndroid) {
    final info = await plugin.androidInfo;
    return 'pos-android-${info.id}';
  }

  if (Platform.isIOS) {
    final info = await plugin.iosInfo;
    final vendorId = info.identifierForVendor;
    if (vendorId != null && vendorId.trim().isNotEmpty) {
      return 'pos-ios-$vendorId';
    }
  }

  return 'pos-device-unknown';
}

List<String> uniqueFingerprints(Iterable<String> values) {
  final seen = <String>{};
  final result = <String>[];

  for (final value in values) {
    final trimmed = value.trim();
    if (trimmed.isEmpty || seen.contains(trimmed)) {
      continue;
    }

    seen.add(trimmed);
    result.add(trimmed);
  }

  return result;
}

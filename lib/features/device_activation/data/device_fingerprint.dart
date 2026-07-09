import 'dart:io' show Platform;
import 'dart:math';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import '../../../core/storage/platform_local_storage.dart';

const webInstallationIdKey = 'pos.web.installationId';

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
    return createStableWebDeviceFingerprint();
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

Future<String> createStableWebDeviceFingerprint() async {
  final existing = await PlatformLocalStorage.read(webInstallationIdKey);
  if (existing != null && existing.trim().isNotEmpty) {
    return 'pos-web-${existing.trim()}';
  }

  final installationId = _createInstallationId();
  await PlatformLocalStorage.write(webInstallationIdKey, installationId);
  return 'pos-web-$installationId';
}

String _createInstallationId() {
  final random = Random.secure();
  final bytes = List<int>.generate(16, (_) => random.nextInt(256));
  bytes[6] = (bytes[6] & 0x0f) | 0x40;
  bytes[8] = (bytes[8] & 0x3f) | 0x80;

  String hex(int value) => value.toRadixString(16).padLeft(2, '0');

  return '${bytes.sublist(0, 4).map(hex).join()}-'
      '${bytes.sublist(4, 6).map(hex).join()}-'
      '${bytes.sublist(6, 8).map(hex).join()}-'
      '${bytes.sublist(8, 10).map(hex).join()}-'
      '${bytes.sublist(10, 16).map(hex).join()}';
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

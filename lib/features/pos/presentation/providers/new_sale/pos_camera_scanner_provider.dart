import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../sale/presentation/widgets/new_sale/pos_camera_barcode_scanner.dart';

final posCameraScannerRequestProvider =
    StateProvider.autoDispose<int>((ref) => 0);

typedef PosCameraScannerLauncher = Future<PosCameraScanResult> Function(
  BuildContext context,
);

final posCameraScannerLauncherProvider = Provider<PosCameraScannerLauncher>(
  (ref) => launchPosCameraScanner,
);

final posCameraScannerSupportedProvider = Provider<bool>(
  (ref) =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS),
);

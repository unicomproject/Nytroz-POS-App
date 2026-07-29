import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../device_activation/presentation/providers/device_activation_provider.dart';
import '../../../device_configuration/models/pos_hardware_models.dart';
import '../../../receipt_printer/presentation/providers/local_print_agent_controller.dart';

final barcodeScannerConfigurationProvider =
    FutureProvider.autoDispose<PosBarcodeScannerConfiguration?>((ref) async {
  final device = ref.watch(deviceActivationProvider).deviceContext;
  if (device == null || device.deviceId.trim().isEmpty) return null;
  final configurations = await ref
      .watch(posHardwareRepositoryProvider)
      .getConfigurations(device.deviceId);
  final scanner = configurations
      .where((item) => item.hardwareType == 'barcodeScanner')
      .firstOrNull;
  return scanner == null
      ? null
      : PosBarcodeScannerConfiguration.fromHardware(scanner);
});

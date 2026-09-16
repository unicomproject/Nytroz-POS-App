import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../tills/domain/entities/till.dart';
import '../../../tills/domain/entities/till_monitoring.dart';
import '../../../tills/domain/entities/till_hardware_readiness.dart';
import '../../../tills/presentation/providers/till_providers.dart';
import '../../domain/entities/hardware_device.dart';
import '../../domain/entities/hardware_device_list_item.dart';
import 'hardware_providers.dart';

final hardwareListProvider =
    FutureProvider.autoDispose<List<HardwareDeviceListItem>>((ref) async {
  final repository = ref.watch(hardwareRepositoryProvider);
  final items = <HardwareDeviceListItem>[];
  for (var page = 1;; page++) {
    final batch =
        await repository.getHardwareDevices(page: page, pageSize: 100);
    items.addAll(batch);
    if (batch.length < 100) return items;
  }
});

final hardwareDetailProvider = FutureProvider.autoDispose
    .family<HardwareDevice, String>((ref, id) =>
        ref.watch(hardwareRepositoryProvider).getHardwareDevice(id));

final hardwareTillsProvider =
    FutureProvider.autoDispose<List<TillMonitoringItem>>((ref) async {
  final repository = ref.watch(tillRepositoryProvider);
  final items = <TillMonitoringItem>[];
  for (var page = 1;; page++) {
    final result = await repository.getTills(
        query: TillListQuery(page: page, pageSize: 100));
    items.addAll(result.items);
    if (items.length >= result.totalCount || result.items.isEmpty) return items;
  }
});

final hardwareReadinessProvider =
    FutureProvider.autoDispose<Map<String, TillHardwareConnection>>(
        (ref) async {
  final tills = await ref.watch(hardwareTillsProvider.future);
  final profiles = await ref.watch(hardwareCompatibilityProvider.future);
  final repository = ref.watch(tillRepositoryProvider);
  final result = <String, TillHardwareConnection>{};
  for (final till in tills) {
    final readiness = await repository.getTillHardwareReadiness(till.id);
    for (final connection in readiness.hardwareConnections) {
      if (profiles.any((p) =>
          p.canConfigure &&
          p.deviceType == connection.type &&
          p.connectionType == connection.connectionType)) {
        result[connection.id] = connection;
      }
    }
  }
  return result;
});

// Lifecycle ACTIVE is not evidence that a physical device is ready.
String hardwareReadinessLabel(bool assigned, TillHardwareConnection? evidence) {
  if (!assigned) return 'Not Configured';
  if (evidence == null) return 'Unknown';
  if (evidence.deviceStatus != 'ACTIVE') return 'Issues';
  if (evidence.connectionStatus == TillHardwareConnectionStatus.unknown) {
    return 'Unknown';
  }
  if (evidence.connectionStatus == TillHardwareConnectionStatus.disconnected) {
    return 'Disconnected';
  }
  if (evidence.connectionStatus ==
          TillHardwareConnectionStatus.needsAttention ||
      evidence.connectionStatus == TillHardwareConnectionStatus.maintenance) {
    return 'Issues';
  }
  final test = evidence.latestTest?.testStatus.toUpperCase();
  if (['FAILED', 'ERROR', 'TIMEOUT', 'WARNING'].contains(test)) return 'Issues';
  if (evidence.connectionStatus == TillHardwareConnectionStatus.connected &&
      ['PASSED', 'SUCCESS'].contains(test)) {
    return 'Ready';
  }
  return 'Not Configured';
}

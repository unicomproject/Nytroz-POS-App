import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/hardware_device.dart';
import '../../data/models/hardware_compatibility_profile.dart';
import '../../services/hardware_setup_discovery_service.dart';
import '../../../presentation/providers/tenant_admin_access_provider.dart';
import 'hardware_providers.dart';
import 'hardware_scope_provider.dart';
import 'hardware_list_provider.dart';
import 'hardware_dashboard_provider.dart';

final hardwareSetupDiscoveryProvider =
    Provider((ref) => HardwareSetupDiscoveryService());
final hardwareSetupControllerProvider = StateNotifierProvider.autoDispose<
    HardwareSetupController,
    HardwareSetupState>((ref) => HardwareSetupController(ref));

class HardwareSetupState {
  const HardwareSetupState(
      {this.step = 0,
      this.type = 'RECEIPT_PRINTER',
      this.connection = 'USB',
      this.outlet,
      this.till,
      this.fields = const {},
      this.identity = const {},
      this.devices = const [],
      this.device,
      this.busy = false,
      this.scanning = false,
      this.message,
      this.lastScannedAt,
      this.generation = 0});
  final DateTime? lastScannedAt;
  final int step, generation;
  final String type, connection;
  final String? outlet, till, message;
  final Map<String, String> fields;
  final Map<String, dynamic> identity;
  final List<DiscoveredHardware> devices;
  final HardwareDevice? device;
  final bool busy, scanning;
  HardwareSetupState copy(
          {int? step,
          String? type,
          String? connection,
          String? outlet,
          String? till,
          Map<String, String>? fields,
          Map<String, dynamic>? identity,
          List<DiscoveredHardware>? devices,
          HardwareDevice? device,
          bool? busy,
          bool? scanning,
          String? message,
          DateTime? lastScannedAt,
          bool clearScanTime = false,
          int? generation}) =>
      HardwareSetupState(
          step: step ?? this.step,
          type: type ?? this.type,
          connection: connection ?? this.connection,
          outlet: outlet ?? this.outlet,
          till: till ?? this.till,
          fields: fields ?? this.fields,
          identity: identity ?? this.identity,
          devices: devices ?? this.devices,
          device: device ?? this.device,
          busy: busy ?? this.busy,
          scanning: scanning ?? this.scanning,
          message: message,
          lastScannedAt:
              clearScanTime ? null : lastScannedAt ?? this.lastScannedAt,
          generation: generation ?? this.generation);
}

class HardwareSetupController extends StateNotifier<HardwareSetupState> {
  HardwareSetupController(this.ref) : super(const HardwareSetupState());
  final Ref ref;
  int _scan = 0;
  bool get locked => state.busy || state.device != null;
  void field(String key, String value) {
    if (!locked) state = state.copy(fields: {...state.fields, key: value});
  }

  void outlet(String value) {
    if (locked || value == state.outlet) return;
    state = HardwareSetupState(
        outlet: value,
        type: state.type,
        connection: state.connection,
        generation: state.generation + 1);
    _scan++;
  }

  void choose(HardwareCompatibilityProfile profile) {
    if (locked || !profile.canConfigure) return;
    state = HardwareSetupState(
        outlet: state.outlet,
        till: state.till,
        type: profile.deviceType,
        connection: profile.connectionType,
        step: 1,
        generation: state.generation + 1);
    _scan++;
  }

  void till(String value) {
    if (!locked) state = state.copy(till: value);
  }

  void connection(String value) {
    if (locked || state.scanning || value == state.connection) return;
    state = state.copy(
        connection: value,
        clearScanTime: true,
        identity: {},
        devices: [],
        fields: {},
        generation: state.generation + 1);
  }

  void back() {
    if (state.busy || state.scanning || state.step == 0) return;
    // Persisted registration is edited through the canonical device detail flow.
    if (state.device != null && state.step <= 3) return;
    state = state.copy(step: state.step - 1);
  }

  void configure() {
    if (!locked && !state.scanning) state = state.copy(step: 2);
  }

  void stop() {
    _scan++;
    state = state.copy(
        scanning: false, message: 'Scan stopped. Late results are ignored.');
  }

  Future<void> discover() async {
    if (locked || state.scanning) return;
    final ticket = ++_scan;
    state = state.copy(scanning: true, devices: []);
    try {
      final result = await ref
          .read(hardwareSetupDiscoveryProvider)
          .discover(state.type, state.connection);
      if (mounted && ticket == _scan) {
        state = state.copy(
            devices: result.devices,
            message: result.message,
            lastScannedAt: DateTime.now());
      }
    } catch (_) {
      if (mounted && ticket == _scan) {
        state = state.copy(
            message:
                'Discovery failed. Check Android permissions, Bluetooth pairing and power, then retry.');
      }
    } finally {
      if (mounted && ticket == _scan) {
        state = state.copy(scanning: false, message: state.message);
      }
    }
  }

  Future<void> select(DiscoveredHardware candidate) async {
    if (locked || state.scanning) return;
    state = state.copy(busy: true);
    try {
      final granted =
          await ref.read(hardwareSetupDiscoveryProvider).select(candidate);
      if (!mounted) return;
      state = granted
          ? state.copy(
              step: 2,
              identity: candidate.identity,
              fields: {
                ...state.fields,
                'name': candidate.name,
                'manufacturer': candidate.manufacturer,
                'model': candidate.model,
              },
              generation: state.generation + 1)
          : state.copy(message: 'USB permission was not granted.');
    } catch (_) {
      if (mounted) {
        state = state.copy(
            message: 'Device permission failed. Retry on the hardware host.');
      }
    } finally {
      if (mounted) state = state.copy(busy: false, message: state.message);
    }
  }

  Future<void> save() async {
    if (locked || state.outlet == null) return;
    state = state.copy(busy: true);
    try {
      final access = await ref.read(tenantAdminAccessCheckerProvider.future);
      if (!access.canManageTillHardware()) throw const HardwareSetupDenied();
      final outlets = await ref.read(hardwareOutletOptionsProvider.future);
      if (!outlets.any((o) => o.id == state.outlet)) {
        throw const HardwareSetupDenied();
      }
      if (state.till != null) {
        final tills = await ref.read(hardwareAssignableTillsProvider.future);
        if (!tills
            .any((t) => t.id == state.till && t.outletId == state.outlet)) {
          throw const HardwareSetupDenied();
        }
      }
      final profiles = await ref.read(hardwareCompatibilityProvider.future);
      final profile = profiles
          .where((p) =>
              p.deviceType == state.type &&
              p.connectionType == state.connection &&
              p.canConfigure)
          .firstOrNull;
      if (profile == null) throw const HardwareSetupDenied();
      final f = state.fields;
      final config = <String, dynamic>{
        ...state.identity,
        'compatibilityProfileId': profile.id,
        'protocol': profile.protocol,
        'adapterKey': profile.adapterKey,
        'capabilitySource': 'DECLARED',
        if (state.connection == 'NETWORK') ...{
          'host': f['host']?.trim(),
          'port': int.parse(f['port'] ?? '9100')
        },
        if (state.type == 'RECEIPT_PRINTER') ...{
          'paperWidth': int.parse(f['paperWidth'] ?? '80'),
          'cashDrawer': f['cashDrawer'] == 'true',
        },
        if (state.type == 'CASH_DRAWER') ...{
          'parentPrinterId': f['parentPrinterId'],
          'connectionStyle': 'PRINTER_ATTACHED'
        },
      };
      final device =
          await ref.read(hardwareRepositoryProvider).createHardwareDevice({
        'outletId': state.outlet,
        'hardwareDeviceCode': f['code']?.trim(),
        'hardwareDeviceName': f['name']?.trim(),
        'hardwareDeviceType': state.type,
        'connectionType': state.connection,
        'status': 'ACTIVE',
        'manufacturer': f['manufacturer']?.trim(),
        'model': f['model']?.trim(),
        'configJson': jsonEncode(config),
      });
      if (!mounted) return;
      state = state.copy(device: device, step: 3);
      ref.invalidate(hardwareListProvider);
      ref.invalidate(hardwareDashboardProvider);
    } catch (error) {
      if (mounted) state = state.copy(message: hardwareSetupError(error));
    } finally {
      if (mounted) state = state.copy(busy: false, message: state.message);
    }
  }

  Future<void> assignmentSaved() async {
    final device = state.device;
    if (device == null || state.busy) return;
    state = state.copy(busy: true);
    try {
      final fresh = await ref
          .read(hardwareRepositoryProvider)
          .getHardwareDevice(device.hardwareDeviceId);
      if (mounted) {
        state = state.copy(device: fresh, step: fresh.isAssigned ? 4 : 3);
      }
    } catch (e) {
      if (mounted) state = state.copy(message: hardwareSetupError(e));
    } finally {
      if (mounted) state = state.copy(busy: false, message: state.message);
    }
  }

  void complete(bool authoritativeReady) {
    if (!state.busy && state.device?.isAssigned == true && authoritativeReady) {
      state = state.copy(step: 5);
    }
  }
}

class HardwareSetupDenied implements Exception {
  const HardwareSetupDenied();
}

String hardwareSetupError(Object error) {
  if (error is HardwareSetupDenied) {
    return 'Hardware management access or a supported device profile is required.';
  }
  if (error is DioException) {
    return switch (error.response?.statusCode) {
      401 => 'Your session expired. Sign in again.',
      403 => 'You do not have access to this hardware action or outlet.',
      404 => 'The device or assignment target is no longer available.',
      409 =>
        'The device changed or is already assigned. Refresh before retrying.',
      400 ||
      422 =>
        'Check the device code, connection settings and parent printer.',
      _ =>
        'The server could not be reached. Your local hardware status has not been changed.',
    };
  }
  return 'The operation could not complete. Refresh and retry.';
}

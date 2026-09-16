import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../device_activation/presentation/providers/device_activation_provider.dart';
import '../../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';
import '../../adapters/bluetooth_receipt_printer_adapter.dart';
import '../../adapters/usb_receipt_printer_adapter.dart';
import '../../config/pos_device_printer_config_store.dart';
import '../../models/pos_device_printer_config.dart';
import '../../models/printer_exception.dart';
import '../../platform/android_receipt_printer_platform.dart';
import '../../testing/local_print_agent_test_receipt.dart';
import '../providers/local_print_agent_controller.dart';

class AndroidDirectPrinterState {
  const AndroidDirectPrinterState({
    this.config,
    this.capabilities,
    this.usbDevices = const [],
    this.bluetoothDevices = const [],
    this.message,
    this.isBusy = false,
    this.lastErrorCode,
  });

  final PosDevicePrinterConfig? config;
  final AndroidReceiptPrinterCapabilities? capabilities;
  final List<AndroidUsbPrinterDevice> usbDevices;
  final List<AndroidBluetoothPrinterDevice> bluetoothDevices;
  final String? message;
  final bool isBusy;
  final String? lastErrorCode;

  AndroidDirectPrinterState copyWith({
    PosDevicePrinterConfig? config,
    AndroidReceiptPrinterCapabilities? capabilities,
    List<AndroidUsbPrinterDevice>? usbDevices,
    List<AndroidBluetoothPrinterDevice>? bluetoothDevices,
    String? message,
    bool? isBusy,
    String? lastErrorCode,
    bool clearMessage = false,
  }) {
    return AndroidDirectPrinterState(
      config: config ?? this.config,
      capabilities: capabilities ?? this.capabilities,
      usbDevices: usbDevices ?? this.usbDevices,
      bluetoothDevices: bluetoothDevices ?? this.bluetoothDevices,
      message: clearMessage ? null : (message ?? this.message),
      isBusy: isBusy ?? this.isBusy,
      lastErrorCode: lastErrorCode,
    );
  }
}

class AndroidDirectPrinterController
    extends StateNotifier<AndroidDirectPrinterState> {
  AndroidDirectPrinterController(this._ref)
      : super(const AndroidDirectPrinterState());

  final Ref _ref;
  final _platform = MethodChannelAndroidReceiptPrinter();
  String? pendingTestId;

  Future<void> confirmPaper(bool printed) async {
    final id = pendingTestId;
    if (id == null || state.isBusy) return;
    state = state.copyWith(isBusy: true);
    try {
      await _ref.read(posHardwareRepositoryProvider).submitResult(id, {
        'status': printed ? 'Passed' : 'Failed',
        'resultCategory':
            printed ? 'test_print_submitted' : 'test_print_failed',
        'physicalConfirmation': printed,
      });
      pendingTestId = null;
      state = state.copyWith(
          message: printed
              ? 'Physical print confirmed and recorded.'
              : 'Print failure recorded.');
    } catch (_) {
      state = state.copyWith(
          message:
              'Result was not saved. Retry confirmation; do not print again.');
    } finally {
      state = state.copyWith(isBusy: false);
    }
  }

  Future<void> load() async {
    if (!MethodChannelAndroidReceiptPrinter.isAndroidNative) {
      state = state.copyWith(
        capabilities: const AndroidReceiptPrinterCapabilities(
          platform: 'unsupported',
          usbHost: false,
          bluetoothClassic: false,
        ),
        message:
            'Android USB/Bluetooth printers are only available on Android tablets.',
      );
      return;
    }
    final deviceId =
        _ref.read(deviceActivationProvider).deviceContext?.deviceId.trim() ??
            '';
    final stored = deviceId.isEmpty
        ? null
        : await _ref.read(posDevicePrinterConfigStoreProvider).load(deviceId);
    final caps = await _platform.getCapabilities();
    state = state.copyWith(
      config: stored,
      capabilities: caps,
      clearMessage: true,
    );
  }

  Future<void> refreshDevices() async {
    state = state.copyWith(isBusy: true, clearMessage: true);
    try {
      final usb = await _platform.usbListDevices();
      var btMessage = '';
      List<AndroidBluetoothPrinterDevice> bt = const [];
      try {
        if (await _platform.bluetoothIsEnabled()) {
          bt = await _platform.bluetoothListBonded();
        } else {
          btMessage = ' Bluetooth is off.';
        }
      } on PrinterException catch (error) {
        btMessage = ' Bluetooth: ${error.message}';
      }
      state = state.copyWith(
        usbDevices: usb,
        bluetoothDevices: bt,
        isBusy: false,
        message:
            'Found ${usb.length} USB candidate(s), ${bt.length} paired BT.$btMessage',
      );
    } on PrinterException catch (error) {
      state = state.copyWith(
        isBusy: false,
        message: error.message,
        lastErrorCode: error.code,
      );
    } catch (error) {
      state = state.copyWith(
        isBusy: false,
        message: error.toString(),
        lastErrorCode: 'WRITE_FAILED',
      );
    }
  }

  Future<void> saveUsbSelection(AndroidUsbPrinterDevice device) async {
    final deviceId =
        _ref.read(deviceActivationProvider).deviceContext?.deviceId.trim() ??
            '';
    if (deviceId.isEmpty) {
      state = state.copyWith(message: 'POS device is not activated.');
      return;
    }
    if (!device.hasPermission) {
      final granted = await _platform.usbRequestPermission(device.deviceName);
      if (!granted) {
        state = state.copyWith(
          message: 'USB permission denied.',
          lastErrorCode: 'PERMISSION_DENIED',
        );
        return;
      }
    }
    final config = PosDevicePrinterConfig(
      deviceId: deviceId,
      enabled: true,
      connectionType: PrinterConnectionType.usb,
      displayName: device.label,
      paperWidth: state.config?.paperWidth ?? PrinterPaperWidth.mm80,
      usbVendorId: device.vendorId,
      usbProductId: device.productId,
      usbDeviceIdentifier: device.serialNumber ?? device.deviceName,
      connectionTimeoutMs: state.config?.connectionTimeoutMs ?? 8000,
      autoCutEnabled: state.config?.autoCutEnabled ?? true,
      feedLinesBeforeCut: state.config?.feedLinesBeforeCut ?? 5,
    );
    await _saveAuthoritative(config);
  }

  Future<void> saveBluetoothSelection(
    AndroidBluetoothPrinterDevice device,
  ) async {
    final deviceId =
        _ref.read(deviceActivationProvider).deviceContext?.deviceId.trim() ??
            '';
    if (deviceId.isEmpty) {
      state = state.copyWith(message: 'POS device is not activated.');
      return;
    }
    final config = PosDevicePrinterConfig(
      deviceId: deviceId,
      enabled: true,
      connectionType: PrinterConnectionType.bluetooth,
      displayName: device.label,
      paperWidth: state.config?.paperWidth ?? PrinterPaperWidth.mm80,
      bluetoothAddress: device.address,
      bluetoothDeviceName: device.name,
      connectionTimeoutMs: state.config?.connectionTimeoutMs ?? 8000,
      autoCutEnabled: state.config?.autoCutEnabled ?? true,
      feedLinesBeforeCut: state.config?.feedLinesBeforeCut ?? 5,
    );
    await _saveAuthoritative(config);
  }

  Future<void> _saveAuthoritative(PosDevicePrinterConfig config) async {
    state = state.copyWith(isBusy: true, clearMessage: true);
    try {
      final context = _ref.read(deviceActivationProvider).deviceContext!;
      final repository = _ref.read(posHardwareRepositoryProvider);
      final printers = (await repository.getConfigurations(context.deviceId))
          .where((device) => device.hardwareType == 'receiptPrinter')
          .toList();
      if (printers.length > 1) {
        state = state.copyWith(
            message:
                'Multiple printers are assigned. Resolve assignments before saving.');
        return;
      }
      final saved = await repository.saveConfiguration({
        'posDeviceId': context.deviceId,
        'outletId': context.outletId,
        'tillId': context.tillId.isEmpty ? null : context.tillId,
        'hardwareType': 'receiptPrinter',
        'transportType': config.connectionType.name,
        'displayName': config.displayName,
        'enabled': config.enabled,
        'expectedVersion':
            printers.isEmpty ? 0 : printers.single.configurationVersion,
        'receiptPrinter': {
          'agentBaseUrl': '',
          'printerName': config.displayName,
          'paperWidth':
              config.paperWidth == PrinterPaperWidth.mm58 ? '58mm' : '80mm',
          'autoCut': config.autoCutEnabled,
          'requestTimeout': config.connectionTimeoutMs,
          'feedBeforeCut': config.feedLinesBeforeCut,
          'localApiKeyPresent': false,
          'usbVendorId': config.usbVendorId,
          'usbProductId': config.usbProductId,
          'usbDeviceIdentifier': config.usbDeviceIdentifier,
          'bluetoothAddress': config.bluetoothAddress,
        },
      });
      final bound = config.copyWith(
          configurationId: saved.configurationId,
          configurationVersion: saved.configurationVersion);
      await _ref.read(posDevicePrinterConfigStoreProvider).save(bound);
      state = state.copyWith(
          config: bound,
          message: 'Printer configuration saved. Run a physical print test.');
    } catch (_) {
      state = state.copyWith(
          message:
              'Unable to save. Check access and assignments. Finish the active shift before changing hardware.');
    } finally {
      state = state.copyWith(isBusy: false);
    }
  }

  Future<void> savePrintSettings(
      {PrinterPaperWidth? paperWidth, bool? autoCut, int? feedLines}) async {
    final config = state.config;
    if (config == null ||
        state.isBusy ||
        pendingTestId != null ||
        !{PrinterConnectionType.usb, PrinterConnectionType.bluetooth}
            .contains(config.connectionType)) {
      return;
    }
    if (feedLines != null && (feedLines < 0 || feedLines > 10)) return;
    await _saveAuthoritative(config.copyWith(
        paperWidth: paperWidth,
        autoCutEnabled: autoCut,
        feedLinesBeforeCut: feedLines));
  }

  Future<void> testPrint() async {
    if (pendingTestId != null) {
      state = state.copyWith(
          message: 'Confirm the previous paper result before printing again.');
      return;
    }
    final config = state.config;
    if (config == null || !config.enabled || config.configurationId == null) {
      state = state.copyWith(message: 'Save a USB or Bluetooth printer first.');
      return;
    }
    if (config.connectionType != PrinterConnectionType.usb &&
        config.connectionType != PrinterConnectionType.bluetooth) {
      state = state.copyWith(
        message: 'Current saved transport is not Android USB/Bluetooth.',
      );
      return;
    }
    state = state.copyWith(isBusy: true, clearMessage: true);
    final adapter = config.connectionType == PrinterConnectionType.usb
        ? UsbReceiptPrinterAdapter(platform: _platform)
        : BluetoothReceiptPrinterAdapter(platform: _platform);
    try {
      final test = const LocalPrintAgentTestReceiptBuilder().build(
        merchantName: 'Android Direct Printer Test',
        outletName: 'Hardware Testing',
        tillName: 'Till',
        cashierName: 'Cashier',
      );
      final context = _ref.read(deviceActivationProvider).deviceContext!;
      final operation =
          await _ref.read(posHardwareRepositoryProvider).createTest({
        'requestId': test.requestId,
        'posDeviceId': context.deviceId,
        'tillId': context.tillId.isEmpty ? null : context.tillId,
        'hardwareConfigurationId': config.configurationId,
        'hardwareType': 'receiptPrinter',
        'testType': 'testPrint',
        'configurationVersion': config.configurationVersion,
      });
      pendingTestId = operation.testId;
      final bytes = <int>[
        0x1B,
        0x40,
        ...('ANDROID DIRECT TEST\n').codeUnits,
        ...('Transport: ${config.connectionType.name}\n').codeUnits,
        ...('Printer: ${config.displayName}\n').codeUnits,
        ...('Request: ${test.requestId}\n').codeUnits,
        ...('NOT A SALE\n').codeUnits,
        ...List<int>.filled(config.feedLinesBeforeCut.clamp(0, 10), 0x0A),
        if (config.autoCutEnabled) ...[0x1D, 0x56, 0x00],
      ];
      await adapter.connect(config);
      await adapter.printBytes(config, bytes);
      await adapter.disconnect();
      state = state.copyWith(
        isBusy: false,
        message: 'Test bytes accepted by transport (${bytes.length} bytes). '
            'Paper completion is not proven by raw write alone.',
      );
    } on PrinterException catch (error) {
      try {
        await adapter.disconnect();
      } catch (_) {}
      state = state.copyWith(
        isBusy: false,
        message: error.message,
        lastErrorCode: error.code,
      );
    } catch (error) {
      try {
        await adapter.disconnect();
      } catch (_) {}
      state = state.copyWith(
        isBusy: false,
        message: error.toString(),
        lastErrorCode: 'WRITE_FAILED',
      );
    }
  }
}

final androidDirectPrinterControllerProvider = StateNotifierProvider
    .autoDispose<AndroidDirectPrinterController, AndroidDirectPrinterState>(
  (ref) => AndroidDirectPrinterController(ref),
);

class AndroidDirectPrinterTestCard extends ConsumerStatefulWidget {
  const AndroidDirectPrinterTestCard({super.key});

  @override
  ConsumerState<AndroidDirectPrinterTestCard> createState() =>
      _AndroidDirectPrinterTestCardState();
}

class _AndroidDirectPrinterTestCardState
    extends ConsumerState<AndroidDirectPrinterTestCard> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(androidDirectPrinterControllerProvider.notifier).load();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!MethodChannelAndroidReceiptPrinter.isAndroidNative) {
      return const SizedBox.shrink();
    }
    final state = ref.watch(androidDirectPrinterControllerProvider);
    final notifier = ref.read(androidDirectPrinterControllerProvider.notifier);

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(TenantAdminSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Android Direct Printer (USB / Bluetooth)',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: TenantAdminSpacing.xs),
            Text(
              'Primary Android tablet path. USB-C hubs enumerate as standard USB Host devices. '
              'Windows Local Print Agent remains optional for Windows-connected printers.',
              style: TenantAdminTextStyles.muted(context),
            ),
            if (state.config != null) ...[
              if ({PrinterConnectionType.usb, PrinterConnectionType.bluetooth}
                  .contains(state.config!.connectionType)) ...[
                DropdownButtonFormField<PrinterPaperWidth>(
                    key:
                        ValueKey('paper-${state.config!.configurationVersion}'),
                    initialValue: state.config!.paperWidth,
                    decoration: const InputDecoration(labelText: 'Paper width'),
                    items: const [
                      DropdownMenuItem(
                          value: PrinterPaperWidth.mm58, child: Text('58 mm')),
                      DropdownMenuItem(
                          value: PrinterPaperWidth.mm80, child: Text('80 mm'))
                    ],
                    onChanged: state.isBusy || notifier.pendingTestId != null
                        ? null
                        : (value) =>
                            notifier.savePrintSettings(paperWidth: value)),
                SwitchListTile(
                    title: const Text('Automatic cut'),
                    subtitle: const Text(
                        'Enable only if this printer supports a cutter. Changes are saved to this POS configuration.'),
                    value: state.config!.autoCutEnabled,
                    onChanged: state.isBusy || notifier.pendingTestId != null
                        ? null
                        : (value) =>
                            notifier.savePrintSettings(autoCut: value)),
                DropdownButtonFormField<int>(
                    key: ValueKey('feed-${state.config!.configurationVersion}'),
                    initialValue: state.config!.feedLinesBeforeCut.clamp(0, 10),
                    decoration: const InputDecoration(
                        labelText: 'Feed lines before cut'),
                    items: [
                      for (var i = 0; i <= 10; i++)
                        DropdownMenuItem(value: i, child: Text('$i'))
                    ],
                    onChanged: state.isBusy || notifier.pendingTestId != null
                        ? null
                        : (value) =>
                            notifier.savePrintSettings(feedLines: value)),
              ],
              const SizedBox(height: TenantAdminSpacing.sm),
              Text(
                'Saved: ${state.config!.connectionType.name} · ${state.config!.displayName}',
                style: TenantAdminTextStyles.muted(context),
              ),
            ],
            if (state.message != null) ...[
              const SizedBox(height: TenantAdminSpacing.sm),
              Text(
                state.message!,
                style: TextStyle(
                  color: state.lastErrorCode == null
                      ? TenantAdminColors.success
                      : TenantAdminColors.danger,
                ),
              ),
            ],
            const SizedBox(height: TenantAdminSpacing.md),
            Wrap(
              spacing: TenantAdminSpacing.sm,
              runSpacing: TenantAdminSpacing.sm,
              children: [
                FilledButton(
                  onPressed: state.isBusy ? null : notifier.refreshDevices,
                  child: const Text('Discover'),
                ),
                OutlinedButton(
                  onPressed: state.isBusy ? null : notifier.testPrint,
                  child: const Text('Test Print'),
                ),
              ],
            ),
            if (notifier.pendingTestId != null) ...[
              const Text(
                  'Did the test receipt print completely and correctly?'),
              Wrap(spacing: 12, children: [
                FilledButton(
                    onPressed:
                        state.isBusy ? null : () => notifier.confirmPaper(true),
                    child: const Text('Yes, printed correctly')),
                OutlinedButton(
                    onPressed: state.isBusy
                        ? null
                        : () => notifier.confirmPaper(false),
                    child: const Text('No / incomplete')),
              ]),
            ],
            if (state.usbDevices.isNotEmpty) ...[
              const SizedBox(height: TenantAdminSpacing.md),
              Text(
                'USB candidates',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              ...state.usbDevices.map(
                (device) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(device.label),
                  subtitle: Text(
                    'VID ${device.vendorId} · PID ${device.productId} · '
                    '${device.hasPermission ? 'permission OK' : 'needs permission'}',
                  ),
                  trailing: TextButton(
                    onPressed: state.isBusy
                        ? null
                        : () => notifier.saveUsbSelection(device),
                    child: const Text('Use'),
                  ),
                ),
              ),
            ],
            if (state.bluetoothDevices.isNotEmpty) ...[
              const SizedBox(height: TenantAdminSpacing.md),
              Text(
                'Paired Bluetooth',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              ...state.bluetoothDevices.map(
                (device) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(device.label),
                  subtitle: Text(device.address),
                  trailing: TextButton(
                    onPressed: state.isBusy
                        ? null
                        : () => notifier.saveBluetoothSelection(device),
                    child: const Text('Use'),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

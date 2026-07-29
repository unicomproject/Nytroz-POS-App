import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../sale/presentation/widgets/new_sale/pos_camera_barcode_scanner.dart';
import '../../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';
import '../providers/barcode_scanner_test_controller.dart';

class BarcodeScannerTestCard extends ConsumerStatefulWidget {
  const BarcodeScannerTestCard({super.key});

  @override
  ConsumerState<BarcodeScannerTestCard> createState() =>
      _BarcodeScannerTestCardState();
}

class _BarcodeScannerTestCardState
    extends ConsumerState<BarcodeScannerTestCard> {
  final _name = TextEditingController(text: 'Barcode Scanner');
  final _timeout = TextEditingController(text: '120');
  final _minimum = TextEditingController(text: '4');
  final _maximum = TextEditingController(text: '128');
  final _reason = TextEditingController();
  bool _hydrated = false;
  bool _enabled = true;
  bool _allowRapidScan = true;
  bool _cameraEnabled = true;
  String _mode = 'usbHid';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(barcodeScannerTestControllerProvider.notifier).load();
    });
  }

  @override
  void dispose() {
    _name.dispose();
    _timeout.dispose();
    _minimum.dispose();
    _maximum.dispose();
    _reason.dispose();
    super.dispose();
  }

  void _hydrate(BarcodeScannerTestState state) {
    if (_hydrated || state.configuration == null) return;
    _name.text = state.configuration!.displayName;
    _timeout.text = '${state.settings.scanTimeout}';
    _minimum.text = '${state.settings.minimumBarcodeLength}';
    _maximum.text = '${state.settings.maximumBarcodeLength}';
    _enabled = state.settings.enabled;
    _allowRapidScan = state.settings.allowRapidScan;
    _cameraEnabled = state.settings.cameraEnabled;
    _mode = state.settings.mode;
    _hydrated = true;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(barcodeScannerTestControllerProvider);
    _hydrate(state);
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(TenantAdminSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.qr_code_scanner_rounded),
                const SizedBox(width: TenantAdminSpacing.sm),
                Expanded(
                  child: Text(
                    'Barcode scanner',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                ),
                if (state.configuration != null)
                  Text('v${state.configuration!.configurationVersion}'),
              ],
            ),
            const SizedBox(height: TenantAdminSpacing.xs),
            Text(state.message),
            const SizedBox(height: TenantAdminSpacing.md),
            Wrap(
              spacing: TenantAdminSpacing.md,
              runSpacing: TenantAdminSpacing.md,
              children: [
                SizedBox(
                  width: 260,
                  child: TextField(
                    controller: _name,
                    enabled: !state.isBusy,
                    decoration:
                        const InputDecoration(labelText: 'Scanner name'),
                  ),
                ),
                SizedBox(
                  width: 220,
                  child: DropdownButtonFormField<String>(
                    initialValue: _mode,
                    decoration: const InputDecoration(labelText: 'Mode'),
                    items: const [
                      DropdownMenuItem(
                        value: 'usbHid',
                        child: Text('USB HID'),
                      ),
                      DropdownMenuItem(
                        value: 'camera',
                        child: Text('Android camera'),
                      ),
                    ],
                    onChanged: state.isBusy
                        ? null
                        : (value) => setState(() => _mode = value ?? 'usbHid'),
                  ),
                ),
                _numberField(_timeout, 'Inter-key timeout (ms)', 200),
                _numberField(_minimum, 'Minimum length', 180),
                _numberField(_maximum, 'Maximum length', 180),
              ],
            ),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              value: _enabled,
              onChanged: state.isBusy
                  ? null
                  : (value) => setState(() => _enabled = value),
              title: const Text('Scanner enabled'),
            ),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              value: _allowRapidScan,
              onChanged: state.isBusy
                  ? null
                  : (value) => setState(() => _allowRapidScan = value),
              title: const Text('Allow rapid scans'),
            ),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              value: _cameraEnabled,
              onChanged: state.isBusy
                  ? null
                  : (value) => setState(() => _cameraEnabled = value),
              title: const Text('Camera scanning enabled'),
            ),
            if (state.configuration?.activeShift == true)
              TextField(
                controller: _reason,
                enabled: !state.isBusy,
                decoration: const InputDecoration(
                  labelText: 'Active-shift change reason',
                  helperText:
                      'Required when a scanner setting changes during an open till session.',
                ),
              ),
            const SizedBox(height: TenantAdminSpacing.md),
            Wrap(
              spacing: TenantAdminSpacing.sm,
              runSpacing: TenantAdminSpacing.sm,
              children: [
                FilledButton.icon(
                  onPressed: state.isBusy ? null : _save,
                  icon: const Icon(Icons.save_outlined),
                  label: const Text('Save scanner configuration'),
                ),
                OutlinedButton.icon(
                  onPressed: state.isBusy || state.isListening
                      ? null
                      : () => ref
                          .read(barcodeScannerTestControllerProvider.notifier)
                          .startTest(
                            _mode == 'camera' ? 'cameraScan' : 'hidInput',
                          ),
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: Text(
                    _mode == 'camera' ? 'Start camera test' : 'Start HID test',
                  ),
                ),
                if (state.isListening && _mode == 'camera')
                  FilledButton.tonalIcon(
                    onPressed: _launchCamera,
                    icon: const Icon(Icons.camera_alt_outlined),
                    label: const Text('Open camera'),
                  ),
                if (state.isListening)
                  TextButton(
                    onPressed: () => ref
                        .read(barcodeScannerTestControllerProvider.notifier)
                        .cancelListening(),
                    child: const Text('Cancel test'),
                  ),
              ],
            ),
            if (state.status ==
                BarcodeScannerTestStatus.awaitingConfirmation) ...[
              const SizedBox(height: TenantAdminSpacing.md),
              Text(
                'Detected ${state.detectedBarcode?.length ?? 0} characters. '
                'The raw barcode will not be stored.',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: TenantAdminSpacing.sm),
              Wrap(
                spacing: TenantAdminSpacing.sm,
                children: [
                  OutlinedButton(
                    onPressed: () => ref
                        .read(barcodeScannerTestControllerProvider.notifier)
                        .finalize(physicalConfirmation: false),
                    child: const Text('Physical result failed'),
                  ),
                  FilledButton(
                    onPressed: () => ref
                        .read(barcodeScannerTestControllerProvider.notifier)
                        .finalize(physicalConfirmation: true),
                    child: const Text('Confirm physical result'),
                  ),
                ],
              ),
            ],
            if (state.history.isNotEmpty) ...[
              const SizedBox(height: TenantAdminSpacing.lg),
              const Text(
                'Scanner test history',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
              ...state.history.take(5).map(
                    (test) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        test.status.toLowerCase() == 'passed'
                            ? Icons.check_circle_outline
                            : Icons.info_outline,
                      ),
                      title: Text('${test.testType} · ${test.status}'),
                      subtitle: Text(
                        test.safeMessage ??
                            test.resultCategory ??
                            'No result message.',
                      ),
                      trailing: Text(
                        'v${test.configurationVersion}',
                      ),
                    ),
                  ),
            ],
            const SizedBox(height: TenantAdminSpacing.sm),
            const Text(
              'Scanner testing detects hardware input only. It never adds a '
              'product, changes cart quantity, or creates a transaction.',
            ),
          ],
        ),
      ),
    );
  }

  SizedBox _numberField(
    TextEditingController controller,
    String label,
    double width,
  ) =>
      SizedBox(
        width: width,
        child: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(labelText: label),
        ),
      );

  Future<void> _save() async {
    final errors =
        await ref.read(barcodeScannerTestControllerProvider.notifier).save(
              displayName: _name.text,
              enabled: _enabled,
              mode: _mode,
              inputSuffix: 'enter',
              scanTimeout: int.tryParse(_timeout.text) ?? 0,
              minimumBarcodeLength: int.tryParse(_minimum.text) ?? 0,
              maximumBarcodeLength: int.tryParse(_maximum.text) ?? 0,
              allowRapidScan: _allowRapidScan,
              cameraEnabled: _cameraEnabled,
              changeReason: _reason.text,
            );
    if (!mounted || errors.isEmpty) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(errors.join('\n'))),
    );
  }

  Future<void> _launchCamera() async {
    final result = await launchPosCameraScanner(context);
    if (!mounted) return;
    switch (result.type) {
      case PosCameraScanResultType.barcode:
        ref
            .read(barcodeScannerTestControllerProvider.notifier)
            .acceptDetectedBarcode(result.barcode ?? '');
      case PosCameraScanResultType.permissionDenied:
        ref.read(barcodeScannerTestControllerProvider.notifier).finalizeFailure(
              category: 'camera_permission_denied',
              message:
                  'Camera permission was denied. Enable it in system settings.',
            );
      case PosCameraScanResultType.unavailable:
        ref.read(barcodeScannerTestControllerProvider.notifier).finalizeFailure(
              category: 'camera_unavailable',
              message: 'Camera is unavailable on this device.',
            );
      case PosCameraScanResultType.failed:
      case PosCameraScanResultType.unsupported:
        ref.read(barcodeScannerTestControllerProvider.notifier).finalizeFailure(
              category: 'camera_initialization_failed',
              message: 'Camera scanner could not initialize safely.',
            );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Camera could not detect a barcode safely.'),
          ),
        );
      case PosCameraScanResultType.cancelled:
        break;
    }
  }
}

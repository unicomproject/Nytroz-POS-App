import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../presentation/theme/tenant_admin_theme.dart';

import '../providers/hardware_list_provider.dart';
import '../providers/hardware_setup_controller.dart';
import 'hardware_setup_widgets.dart';

class HardwareConfigurationForm extends ConsumerStatefulWidget {
  const HardwareConfigurationForm({super.key});
  @override
  ConsumerState<HardwareConfigurationForm> createState() =>
      _HardwareConfigurationFormState();
}

class _HardwareConfigurationFormState
    extends ConsumerState<HardwareConfigurationForm> {
  final _form = GlobalKey<FormState>();
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(hardwareSetupControllerProvider);
    final controller = ref.read(hardwareSetupControllerProvider.notifier);
    Widget field(String key, String label,
            {bool required = false, int max = 120}) =>
        Padding(
            padding: const EdgeInsets.only(bottom: TenantAdminSpacing.lg),
            child: TextFormField(
                key: ValueKey('${state.generation}:$key'),
                initialValue:
                    state.fields[key] ?? (key == 'port' ? '9100' : ''),
                enabled: !state.busy,
                maxLength: max,
                decoration: InputDecoration(labelText: label, counterText: ''),
                onChanged: (value) => controller.field(key, value),
                validator: (value) {
                  if (required && (value?.trim().isEmpty ?? true)) {
                    return '$label is required';
                  }
                  if (key == 'port') {
                    final number = int.tryParse(value ?? '');
                    if (number == null || number < 1 || number > 65535) {
                      return 'Use a port between 1 and 65535';
                    }
                  }
                  return null;
                }));
    return Form(
        key: _form,
        child: HardwareSetupColumns(
            summary:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(hardwareTypeIcon(state.type),
                  size: 64, color: TenantAdminColors.primary),
              const SizedBox(height: TenantAdminSpacing.lg),
              Text(hardwareTypeLabel(state.type),
                  style: Theme.of(context).textTheme.titleLarge),
              Text(state.connection == 'USB' && state.type == 'CASH_DRAWER'
                  ? 'Printer attached'
                  : state.connection),
              const SizedBox(height: TenantAdminSpacing.lg),
              Text(state.identity.isEmpty
                  ? 'Manual configuration. No discovery evidence.'
                  : 'Device enumerated locally. Physical verification is still required.'),
              const SizedBox(height: TenantAdminSpacing.lg),
              const Text(
                  'Model certification, cutter, density and default-printer settings are not inferred. Configure supported runtime options on the assigned POS.'),
            ]),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Device Settings',
                      style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: TenantAdminSpacing.lg),
                  field('code', 'Device Code', required: true, max: 50),
                  field('name', 'Display Name', required: true),
                  field('manufacturer', 'Manufacturer'),
                  field('model', 'Model'),
                  if (state.connection == 'NETWORK') ...[
                    field('host', 'Host', required: true),
                    field('port', 'Port', required: true)
                  ],
                  if (state.type == 'RECEIPT_PRINTER')
                    DropdownButtonFormField<String>(
                        initialValue: state.fields['paperWidth'] ?? '80',
                        decoration:
                            const InputDecoration(labelText: 'Paper Width'),
                        items: [
                          for (final width in ['58', '80'])
                            DropdownMenuItem(
                                value: width, child: Text('$width mm'))
                        ],
                        onChanged: state.busy
                            ? null
                            : (v) => controller.field('paperWidth', v!)),
                  if (state.type == 'RECEIPT_PRINTER')
                    SwitchListTile(
                        title: const Text(
                            'Printer has a compatible cash drawer port'),
                        subtitle: const Text(
                            'Enable only after checking the drawer connector, voltage and pin compatibility. This permits linking a drawer; it does not send an opening command.'),
                        value: state.fields['cashDrawer'] == 'true',
                        onChanged: state.busy
                            ? null
                            : (value) =>
                                controller.field('cashDrawer', '$value')),
                  if (state.type == 'BARCODE_SCANNER')
                    const Text(
                        'USB/Bluetooth HID input. Enable the scanner and set its suffix in POS Hardware Testing after assignment. Registering hardware alone does not enable scan-to-cart.'),
                  if (state.type == 'CASH_DRAWER')
                    ref.watch(hardwareListProvider).when(
                        loading: () => const LinearProgressIndicator(),
                        error: (_, __) => TextButton(
                            onPressed: () =>
                                ref.invalidate(hardwareListProvider),
                            child: const Text('Retry parent printers')),
                        data: (devices) => DropdownButtonFormField<String>(
                            initialValue: state.fields['parentPrinterId'],
                            isExpanded: true,
                            decoration: const InputDecoration(
                                labelText: 'Parent Printer'),
                            items: [
                              for (final d in devices.where((d) =>
                                  d.outletId == state.outlet &&
                                  d.hardwareDeviceType == 'RECEIPT_PRINTER' &&
                                  d.status == 'ACTIVE'))
                                DropdownMenuItem(
                                    value: d.hardwareDeviceId,
                                    child: Text(d.hardwareDeviceName,
                                        overflow: TextOverflow.ellipsis))
                            ],
                            validator: (v) => v == null
                                ? 'Select a compatible parent printer'
                                : null,
                            onChanged: state.busy
                                ? null
                                : (v) =>
                                    controller.field('parentPrinterId', v!))),
                  const SizedBox(height: TenantAdminSpacing.xl),
                  const Text(
                      'Save registers configuration. Connection and physical test results must come from the assigned POS.'),
                  const SizedBox(height: TenantAdminSpacing.lg),
                  FilledButton(
                      onPressed: state.busy
                          ? null
                          : () {
                              if (_form.currentState!.validate()) {
                                controller.save();
                              }
                            },
                      child: Text(state.busy ? 'Saving…' : 'Save & Continue')),
                ])));
  }
}

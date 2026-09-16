import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/hardware_device.dart';
import '../providers/hardware_providers.dart';
import '../providers/hardware_list_provider.dart';
import '../providers/hardware_dashboard_provider.dart';

class EditHardwareDialog extends ConsumerStatefulWidget {
  const EditHardwareDialog({super.key, required this.device});
  final HardwareDevice device;
  @override
  ConsumerState<EditHardwareDialog> createState() => _EditHardwareDialogState();
}

class _EditHardwareDialogState extends ConsumerState<EditHardwareDialog> {
  late final name =
      TextEditingController(text: widget.device.hardwareDeviceName);
  late String status =
      ['ACTIVE', 'INACTIVE', 'MAINTENANCE'].contains(widget.device.status)
          ? widget.device.status
          : 'INACTIVE';
  bool busy = false;
  String? error;
  @override
  void dispose() {
    name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: const Text('Edit hardware'),
        content: SizedBox(
            width: 420,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(
                  controller: name,
                  maxLength: 150,
                  enabled: !busy,
                  decoration: const InputDecoration(labelText: 'Device name')),
              DropdownButtonFormField<String>(
                  initialValue: status,
                  items: ['ACTIVE', 'INACTIVE', 'MAINTENANCE']
                      .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                      .toList(),
                  onChanged: busy ? null : (v) => setState(() => status = v!),
                  decoration: const InputDecoration(labelText: 'Lifecycle')),
              const SizedBox(height: 12),
              const Text(
                  'Release assignments before deactivating hardware. Transport settings are configured on the assigned POS.'),
              if (error != null)
                Text(error!, style: const TextStyle(color: Colors.red)),
            ])),
        actions: [
          TextButton(
              onPressed: busy ? null : () => Navigator.pop(context),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: busy ? null : save,
              child: Text(busy ? 'Saving…' : 'Save')),
        ],
      );
  Future<void> save() async {
    if (name.text.trim().isEmpty) {
      setState(() => error = 'Enter a device name.');
      return;
    }
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await ref
          .read(hardwareRemoteDataSourceProvider)
          .updateHardwareDevice(widget.device.hardwareDeviceId, {
        'hardwareDeviceName': name.text.trim(),
        'status': status,
        'expectedVersion': widget.device.configurationVersion,
      });
      ref.invalidate(hardwareDetailProvider(widget.device.hardwareDeviceId));
      ref.invalidate(hardwareListProvider);
      ref.invalidate(hardwareReadinessProvider);
      ref.invalidate(hardwareDashboardProvider);
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      if (mounted) {
        setState(() => error =
            'Save failed. Check assignments and access; refresh the device if it changed elsewhere.');
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }
}

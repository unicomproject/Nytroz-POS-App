import 'package:flutter/material.dart';
import '../providers/hardware_scope_provider.dart';
import '../../../presentation/providers/tenant_admin_access_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../tills/domain/entities/till_monitoring.dart';
import '../providers/hardware_providers.dart';
import '../providers/hardware_list_provider.dart';

class AssignHardwareDialog extends ConsumerStatefulWidget {
  const AssignHardwareDialog(
      {super.key,
      required this.hardwareId,
      required this.hardwareName,
      this.initialTillId});
  final String? initialTillId;
  final String hardwareId, hardwareName;
  @override
  ConsumerState<AssignHardwareDialog> createState() =>
      _AssignHardwareDialogState();
}

class _AssignHardwareDialogState extends ConsumerState<AssignHardwareDialog> {
  String? tillId;
  bool toPos = false, busy = false;
  String? error;
  @override
  void initState() {
    super.initState();
    tillId = widget.initialTillId;
  }

  @override
  Widget build(BuildContext context) {
    final canManage = ref
            .watch(tenantAdminAccessCheckerProvider)
            .asData
            ?.value
            .canManageTillHardware() ==
        true;
    final hardware = ref.watch(hardwareDetailProvider(widget.hardwareId));
    final tills = ref.watch(hardwareAssignableTillsProvider);
    final valid = (tills.isLoading ||
                tills.hasError ||
                hardware.isLoading ||
                hardware.hasError
            ? <TillMonitoringItem>[]
            : tills.valueOrNull ?? <TillMonitoringItem>[])
        .where((t) =>
            t.outletId == hardware.valueOrNull?.outletId &&
            t.lifecycleStatus == TillLifecycleStatus.active)
        .toList();
    final selected = valid.where((t) => t.id == tillId).firstOrNull;
    return AlertDialog(
      title: const Text('Assign Device'),
      content: SizedBox(
          width: 560,
          child: SingleChildScrollView(
              child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                Text(widget.hardwareName),
                const SizedBox(height: 12),
                Text(
                    'Outlet: ${hardware.valueOrNull?.outletName ?? 'Loading…'}'),
                const SizedBox(height: 12),
                if (hardware.isLoading || tills.isLoading)
                  const LinearProgressIndicator(),
                if (hardware.hasError || tills.hasError)
                  const Text(
                      'Explicit till access could not be verified. Assignment is unavailable until your access projection can be loaded.'),
                DropdownButtonFormField<String>(
                    key: ValueKey(selected?.id),
                    initialValue: selected?.id,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Till'),
                    items: [
                      for (final t in valid)
                        DropdownMenuItem(
                            value: t.id, child: Text('${t.name} (${t.code})'))
                    ],
                    onChanged: busy || !canManage
                        ? null
                        : (v) => setState(() {
                              tillId = v;
                              toPos = false;
                            })),
                const SizedBox(height: 12),
                if (!tills.isLoading && valid.isEmpty)
                  const Text(
                      'No active tills in this outlet. Create or activate a till first.'),
                SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Assign through this till’s POS device'),
                    subtitle: Text(selected?.assignedPosDeviceName ??
                        'Select a till with an assigned, trusted POS device.'),
                    value: toPos,
                    onChanged: busy ||
                            !canManage ||
                            selected?.assignedPosDeviceId == null ||
                            selected?.isPosDeviceTrusted != true
                        ? null
                        : (v) => setState(() => toPos = v)),
                const SizedBox(height: 12),
                const Text('Permissions & Availability',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const Text(
                    'Only active tills in this outlet are shown. Hardware can have one active assignment. A printer-attached drawer must use the same target as its parent printer.'),
                if (error != null)
                  Text(error!, style: const TextStyle(color: Colors.red)),
              ]))),
      actions: [
        TextButton(
            onPressed: busy ? null : () => Navigator.pop(context),
            child: const Text('Back')),
        FilledButton(
            onPressed: busy ||
                    !canManage ||
                    selected == null ||
                    hardware.valueOrNull == null
                ? null
                : () async {
                    setState(() {
                      busy = true;
                      error = null;
                    });
                    try {
                      final access = await ref
                          .read(tenantAdminAccessCheckerProvider.future);
                      if (!access.canManageTillHardware()) {
                        throw StateError('Access denied');
                      }
                      final repository = ref.read(hardwareRepositoryProvider);
                      final request = {
                        'hardwareDeviceId': widget.hardwareId,
                        'isPrimary': false
                      };
                      if (toPos) {
                        await repository.assignHardwareToPosDevice(
                            posDeviceId: selected.assignedPosDeviceId!,
                            request: request);
                      } else {
                        await repository.assignHardwareToTill(
                            tillId: selected.id, request: request);
                      }
                      ref.invalidate(hardwareDetailProvider(widget.hardwareId));
                      ref.invalidate(hardwareListProvider);
                      ref.invalidate(hardwareReadinessProvider);
                      if (context.mounted) Navigator.pop(context, true);
                    } catch (_) {
                      if (mounted) {
                        setState(() => error =
                            'Assignment rejected. Check the device, parent printer and target, then retry.');
                      }
                    } finally {
                      if (mounted) setState(() => busy = false);
                    }
                  },
            child: Text(busy ? 'Assigning…' : 'Assign Device')),
      ],
    );
  }
}

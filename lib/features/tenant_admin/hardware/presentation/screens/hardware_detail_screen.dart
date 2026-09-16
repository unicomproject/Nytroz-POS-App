import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../presentation/providers/tenant_admin_access_provider.dart';

import '../providers/hardware_list_provider.dart';
import '../providers/hardware_providers.dart';
import '../widgets/assign_hardware_dialog.dart';
import '../widgets/edit_hardware_dialog.dart';
import '../widgets/hardware_setup_widgets.dart';
import '../widgets/hardware_test_history.dart';

class HardwareDetailScreen extends ConsumerStatefulWidget {
  const HardwareDetailScreen({super.key, required this.hardwareId});
  final String hardwareId;
  @override
  ConsumerState<HardwareDetailScreen> createState() =>
      _HardwareDetailScreenState();
}

class _HardwareDetailScreenState extends ConsumerState<HardwareDetailScreen> {
  bool busy = false;
  String? message;
  int step = 0;
  @override
  Widget build(BuildContext context) {
    final device = ref.watch(hardwareDetailProvider(widget.hardwareId));
    final readiness = ref.watch(hardwareReadinessProvider);
    final checker = ref.watch(tenantAdminAccessCheckerProvider).valueOrNull;
    final canManage = checker?.canManageTillHardware() == true;
    return HardwareSetupPage(
      title: step == 0 ? 'Assign Device' : 'Test & Go Live',
      actions: [
        OutlinedButton.icon(
            onPressed: device.valueOrNull == null
                ? null
                : () => showDialog<void>(
                    context: context,
                    builder: (_) => HardwareTestHistory(
                        hardwareId: widget.hardwareId,
                        name: device.valueOrNull!.hardwareDeviceName)),
            icon: const Icon(Icons.history),
            label: const Text('View Test Logs')),
        OutlinedButton.icon(
            onPressed: () {
              ref.invalidate(hardwareDetailProvider(widget.hardwareId));
              ref.invalidate(hardwareReadinessProvider);
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Refresh status'))
      ],
      child: device.when(
        loading: () => const CircularProgressIndicator(),
        error: (_, __) =>
            const Text('Unable to load this device. Check access and retry.'),
        data: (d) {
          final evidence = readiness.valueOrNull?[d.hardwareDeviceId];
          final status = hardwareReadinessLabel(d.isAssigned, evidence);
          String? parentId;
          try {
            final config = jsonDecode(d.configJson ?? '{}');
            if (config is Map && config['parentPrinterId'] is String) {
              parentId = config['parentPrinterId'] as String;
            }
          } on FormatException {/* Legacy configuration is not shown raw. */}
          final registry = ref.watch(hardwareListProvider).valueOrNull ?? [];
          final parent =
              registry.where((p) => p.hardwareDeviceId == parentId).firstOrNull;
          final tills = ref.watch(hardwareTillsProvider).valueOrNull ?? [];
          final till = tills
              .where((t) =>
                  t.id == d.assignedTillId ||
                  (d.assignedPosDeviceId != null &&
                      t.assignedPosDeviceId == d.assignedPosDeviceId))
              .firstOrNull;
          final assignedHere = registry
              .where((p) =>
                  p.isAssigned &&
                  p.outletId == d.outletId &&
                  p.assignedTillId == d.assignedTillId &&
                  p.assignedPosDeviceId == d.assignedPosDeviceId)
              .toList();
          final allReady = assignedHere.isNotEmpty &&
              assignedHere.every((p) =>
                  hardwareReadinessLabel(p.isAssigned,
                      readiness.valueOrNull?[p.hardwareDeviceId]) ==
                  'Ready');
          return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Wrap(spacing: 12, children: [
                  const Chip(label: Text('1  Hardware Setup')),
                  Chip(
                      label: const Text('2  Configure & Assign'),
                      backgroundColor:
                          step == 0 ? const Color(0xffffe9d9) : null),
                  Chip(
                      label: const Text('3  Test & Go Live'),
                      backgroundColor:
                          step == 1 ? const Color(0xffffe9d9) : null),
                ]),
                const SizedBox(height: 16),
                if (message != null) Text(message!),
                HardwareSetupCard(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Icon(hardwareTypeIcon(d.hardwareDeviceType),
                          size: 40, color: const Color(0xffff6a00)),
                      Text(d.hardwareDeviceName,
                          style: Theme.of(context).textTheme.headlineSmall),
                      Text(
                          '${hardwareTypeLabel(d.hardwareDeviceType)} • ${d.connectionType}'),
                      Text(
                          'Manufacturer: ${d.manufacturer ?? 'Not specified'} • Model: ${d.model ?? 'Not specified'}'),
                      Text('Outlet: ${d.outletName}'),
                      if (parentId != null)
                        Text(
                            'Parent Printer: ${parent?.hardwareDeviceName ?? 'Unavailable'}'),
                      Text(
                          'Till: ${till?.name ?? (d.isAssigned ? 'Assignment details unavailable' : 'Not assigned')}'),
                      Text(
                          'POS Device: ${d.assignedPosDeviceId != null ? till?.assignedPosDeviceName ?? 'Assigned POS' : 'Till-level assignment'}'),
                      Text('Status: $status • Lifecycle: ${d.status}'),
                      Text(
                          'Last seen: ${d.lastSeenAt?.toLocal().toString().split('.').first ?? 'Never'}'),
                      if (readiness.hasError)
                        const Text(
                            'Live readiness unavailable. Registry data does not confirm connection.'),
                      if (step == 0) ...[
                        const SizedBox(height: 16),
                        if (canManage)
                          OutlinedButton(
                              onPressed: busy
                                  ? null
                                  : () => showDialog<bool>(
                                      context: context,
                                      builder: (_) =>
                                          EditHardwareDialog(device: d)),
                              child: const Text('Edit name / lifecycle')),
                        if (!d.isAssigned && canManage)
                          FilledButton(
                              onPressed: () => showDialog<bool>(
                                  context: context,
                                  builder: (_) => AssignHardwareDialog(
                                      hardwareId: d.hardwareDeviceId,
                                      hardwareName: d.hardwareDeviceName)),
                              child: const Text('Assign Device')),
                        if (d.activeAssignmentId != null && canManage)
                          OutlinedButton(
                              onPressed: busy
                                  ? null
                                  : () async {
                                      final confirmed = await showDialog<bool>(
                                          context: context,
                                          builder: (context) => AlertDialog(
                                                  title: const Text(
                                                      'Release device?'),
                                                  content: const Text(
                                                      'This removes the active assignment. The device will need reassignment before POS use. Release any attached drawers first.'),
                                                  actions: [
                                                    TextButton(
                                                        onPressed: () =>
                                                            Navigator.pop(
                                                                context, false),
                                                        child: const Text(
                                                            'Cancel')),
                                                    FilledButton(
                                                        onPressed: () =>
                                                            Navigator.pop(
                                                                context, true),
                                                        child: const Text(
                                                            'Release')),
                                                  ]));
                                      if (confirmed != true || !mounted) return;
                                      setState(() => busy = true);
                                      try {
                                        await ref
                                            .read(hardwareRepositoryProvider)
                                            .releaseHardwareAssignment(
                                                assignmentId:
                                                    d.activeAssignmentId!,
                                                request: {
                                              'reason':
                                                  'Released from hardware setup'
                                            });
                                        ref.invalidate(hardwareDetailProvider(
                                            widget.hardwareId));
                                        ref.invalidate(hardwareListProvider);
                                        ref.invalidate(
                                            hardwareReadinessProvider);
                                      } catch (_) {
                                        if (mounted) {
                                          setState(() => message =
                                              'Release failed. Check permissions and dependent devices.');
                                        }
                                      } finally {
                                        if (mounted) {
                                          setState(() => busy = false);
                                        }
                                      }
                                    },
                              child: const Text('Release Device / Replace')),
                        const SizedBox(height: 12),
                        const Text(
                            'To replace: release the existing assignment, register the replacement and assign it to the same target.'),
                        FilledButton(
                            onPressed: d.isAssigned
                                ? () => setState(() => step = 1)
                                : null,
                            child: const Text('Save & Continue')),
                      ],
                    ])),
                if (step == 1) ...[
                  const SizedBox(height: 16),
                  HardwareSetupCard(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        Text(
                            switch (d.hardwareDeviceType) {
                              'RECEIPT_PRINTER' => 'Print Test Receipt',
                              'BARCODE_SCANNER' => 'Scan Test Barcode',
                              'CASH_DRAWER' => 'Open Drawer Test',
                              'CARD_READER' => 'Test Connection',
                              _ => 'Hardware test',
                            },
                            style: Theme.of(context).textTheme.titleLarge),
                        Text(
                            'Latest result: ${evidence?.latestTest?.testStatus ?? 'NOT CONFIGURED'}'),
                        Text(
                            'Last tested: ${evidence?.latestTest?.testedAt.toLocal().toString().split('.').first ?? 'Never'}'),
                        if (evidence?.warningMessage != null)
                          Text(evidence!.warningMessage!),
                        const SizedBox(height: 12),
                        Text(d.hardwareDeviceType == 'CARD_READER'
                            ? 'Payment provider integration is not configured. A provider-certified SDK/API and terminal are required. Test connection is unavailable.'
                            : 'Perform the physical test on the POS assigned above, then return and refresh. A browser cannot execute remote hardware tests.'),
                        if (!kIsWeb &&
                            d.hardwareDeviceType != 'CARD_READER' &&
                            [
                              'RECEIPT_PRINTER',
                              'BARCODE_SCANNER',
                              'CASH_DRAWER'
                            ].contains(d.hardwareDeviceType))
                          OutlinedButton(
                              onPressed: () => context.go('/pos/settings'),
                              child:
                                  const Text('Open this POS hardware testing')),
                        const Text(
                            'POS testing requires the existing POS hardware settings permission and a trusted device context. Tests operate on that POS configuration.'),
                        const SizedBox(height: 16),
                        FilledButton(
                            onPressed: status == 'Ready'
                                ? () => context.go('/tenant-admin/hardware')
                                : null,
                            child: const Text('Complete Setup')),
                        Text(allReady
                            ? 'All assigned devices ready'
                            : 'Some assigned devices still need verification'),
                        OutlinedButton(
                            onPressed: allReady && !kIsWeb
                                ? () => context.go('/pos/home')
                                : null,
                            child: const Text('Start Selling')),
                        TextButton(
                            onPressed: () => setState(() => step = 0),
                            child: const Text('Back to assignment')),
                      ])),
                ],
                TextButton(
                    onPressed: () => context.go('/tenant-admin/hardware'),
                    child: const Text('Back to Hardware Integration')),
              ]);
        },
      ),
    );
  }
}

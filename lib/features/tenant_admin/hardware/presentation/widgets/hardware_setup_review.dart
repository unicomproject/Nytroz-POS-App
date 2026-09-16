import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../presentation/theme/tenant_admin_theme.dart';
import '../providers/hardware_setup_controller.dart';
import '../providers/hardware_dashboard_provider.dart';
import '../widgets/assign_hardware_dialog.dart';
import 'hardware_setup_widgets.dart';

/// Review backend evidence; never dispatch a physical command from Tenant Admin.
class HardwareSetupReview extends ConsumerWidget {
  const HardwareSetupReview({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(hardwareSetupControllerProvider);
    final controller = ref.read(hardwareSetupControllerProvider.notifier);
    final d = state.device;
    if (d == null) {
      return const Text('Return to Choose Device Type to start setup.');
    }
    final query = (
      page: 1,
      outletId: d.outletId,
      search: d.hardwareDeviceCode,
      type: '',
      status: '',
      sort: 'name'
    );
    final result = ref.watch(hardwareDashboardProvider(query));
    final readiness = result.asData?.value.statuses[d.hardwareDeviceId];
    final ready = d.isAssigned &&
        readiness == 'Ready' &&
        !result.isLoading &&
        !result.hasError;
    final complete = state.step == 5 && ready;
    return HardwareSetupColumns(
        summary:
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Setup Summary', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: TenantAdminSpacing.lg),
          Text('Outlet: ${d.outletName}'),
          Text('Device: ${d.hardwareDeviceName}'),
          Text('Assignment: ${d.isAssigned ? 'Assigned' : 'Not Assigned'}'),
          Text('Readiness: ${readiness ?? 'Not verified'}'),
          const SizedBox(height: TenantAdminSpacing.lg),
          const Text(
              'Test on the POS hosting this device. Check power, cable and permissions. Physical test success is not implied by saving configuration.'),
        ]),
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Icon(hardwareTypeIcon(d.hardwareDeviceType),
              size: 56, color: TenantAdminColors.primary),
          Text(d.hardwareDeviceName,
              style: Theme.of(context).textTheme.titleLarge),
          Text(hardwareTypeLabel(d.hardwareDeviceType)),
          const SizedBox(height: TenantAdminSpacing.lg),
          if (state.step == 3) ...[
            const Text(
                'Assign this device to an eligible till or its trusted POS in the same outlet. The backend validates conflicts and parent-printer constraints.'),
            const SizedBox(height: TenantAdminSpacing.lg),
            FilledButton(
                onPressed: state.busy
                    ? null
                    : () async {
                        final saved = await showDialog<bool>(
                            context: context,
                            builder: (_) => AssignHardwareDialog(
                                initialTillId: state.till,
                                hardwareId: d.hardwareDeviceId,
                                hardwareName: d.hardwareDeviceName));
                        if (saved == true && context.mounted) {
                          await controller.assignmentSaved();
                        }
                      },
                child: const Text('Select Till / POS and Assign')),
            TextButton(
                onPressed: state.busy ? null : controller.assignmentSaved,
                child: const Text('Refresh assignment')),
          ] else ...[
            if (result.isLoading) const LinearProgressIndicator(),
            Text(
                complete
                    ? 'This device is configured, assigned and Ready according to the backend.'
                    : 'Test on POS required',
                style: Theme.of(context).textTheme.titleMedium),
            if (!complete)
              const Text(
                  'Open Hardware Testing on the assigned POS. Run the physical test and report its result there, then refresh here. No remote command channel is available.'),
            if (result.hasError)
              const Text(
                  'Readiness could not be loaded. Retry; local hardware connection has not been inferred.'),
            const SizedBox(height: TenantAdminSpacing.lg),
            OutlinedButton.icon(
                onPressed: () =>
                    ref.invalidate(hardwareDashboardProvider(query)),
                icon: const Icon(Icons.refresh),
                label: const Text('Refresh test status')),
            if (state.step == 4)
              FilledButton(
                  onPressed: ready ? () => controller.complete(ready) : null,
                  child: const Text('Complete Setup')),
            if (complete) ...[
              const Text(
                  'Completion covers this device only. Other devices and payment-provider readiness follow their own backend policy.'),
              FilledButton(
                  onPressed: () => context.go('/pos/home'),
                  child: const Text('Go to POS')),
            ],
            if (state.step == 5 && !ready)
              const Text(
                  'Readiness is no longer confirmed. Return to testing and refresh.'),
          ],
          TextButton(
              onPressed: () =>
                  context.go('/tenant-admin/hardware/${d.hardwareDeviceId}'),
              child: const Text('View Device / Edit Configuration')),
        ]));
  }
}

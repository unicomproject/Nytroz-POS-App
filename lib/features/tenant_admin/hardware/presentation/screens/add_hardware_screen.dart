import 'package:flutter/material.dart';
import '../../data/models/hardware_compatibility_profile.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../presentation/providers/tenant_admin_access_provider.dart';
import '../../../presentation/theme/tenant_admin_theme.dart';
import '../providers/hardware_providers.dart';
import '../providers/hardware_setup_controller.dart';
import '../providers/hardware_scope_provider.dart';
import '../widgets/hardware_setup_widgets.dart';
import '../widgets/hardware_configuration_form.dart';
import '../widgets/hardware_setup_review.dart';
import 'hardware_detail_screen.dart';

class AddHardwareScreen extends ConsumerWidget {
  const AddHardwareScreen({super.key, this.hardwareId});
  final String? hardwareId;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (hardwareId != null) {
      return HardwareDetailScreen(hardwareId: hardwareId!);
    }
    final access = ref.watch(tenantAdminAccessCheckerProvider);
    if (access.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (access.asData?.value.canManageTillHardware() != true) {
      return HardwareSetupPage(
          title: 'Hardware setup',
          child: Column(children: [
            const Text('Hardware management access is required.'),
            TextButton(
                onPressed: () =>
                    ref.invalidate(tenantAdminAccessCheckerProvider),
                child: const Text('Retry access')),
          ]));
    }
    final state = ref.watch(hardwareSetupControllerProvider);
    final controller = ref.read(hardwareSetupControllerProvider.notifier);
    final profiles = ref.watch(hardwareCompatibilityProvider);
    final outlets = ref.watch(hardwareOutletOptionsProvider);
    final tills = ref.watch(hardwareAssignableTillsProvider);
    final validOutlet = !outlets.isLoading &&
        !outlets.hasError &&
        outlets.valueOrNull?.any((o) => o.id == state.outlet) == true;
    final validTills = !tills.isLoading && !tills.hasError && validOutlet
        ? tills.requireValue.where((t) => t.outletId == state.outlet).toList()
        : null;
    final validTill = validTills?.any((t) => t.id == state.till) == true;
    final catalogReady = !profiles.isLoading && !profiles.hasError;
    final selectedProfileAvailable = catalogReady &&
        profiles.requireValue.any((p) =>
            p.deviceType == state.type &&
            p.connectionType == state.connection &&
            p.canConfigure);
    final connections = <String, HardwareCompatibilityProfile>{
      if (catalogReady)
        for (final p in profiles.requireValue)
          if (p.deviceType == state.type && p.canConfigure) p.connectionType: p,
    };
    const titles = [
      'Choose Device Type',
      'Discover & Connect',
      'Configure Device',
      'Assign Device',
      'Test Devices',
      'Setup Complete'
    ];
    return HardwareSetupPage(
        title: titles[state.step],
        subtitle: 'Tenant Admin / Hardware Integration',
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          HardwareSetupStepper(step: state.step),
          const SizedBox(height: TenantAdminSpacing.xl),
          if (state.message != null)
            Padding(
                padding: const EdgeInsets.only(bottom: TenantAdminSpacing.lg),
                child: Text(state.message!)),
          if (state.step == 0) ...[
            outlets.when(
                loading: () => const LinearProgressIndicator(),
                error: (_, __) => TextButton(
                    onPressed: () =>
                        ref.invalidate(hardwareOutletOptionsProvider),
                    child: const Text('Cannot load authorized outlets. Retry')),
                data: (items) => DropdownButtonFormField<String>(
                    key: ValueKey(
                        'outlet-${state.outlet}-${items.map((o) => o.id).join(',')}'),
                    initialValue: items.any((o) => o.id == state.outlet)
                        ? state.outlet
                        : null,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Outlet'),
                    items: [
                      for (final o in items)
                        DropdownMenuItem(
                            value: o.id,
                            child:
                                Text(o.name, overflow: TextOverflow.ellipsis))
                    ],
                    onChanged: (v) {
                      if (v != null) controller.outlet(v);
                    })),
            const SizedBox(height: TenantAdminSpacing.lg),
            DropdownButtonFormField<String>(
              key: ValueKey(
                  'till-${state.outlet}-${validTill ? state.till : ''}'),
              initialValue: validTill ? state.till : null,
              isExpanded: true,
              decoration: const InputDecoration(
                  labelText: 'Till', prefixIcon: Icon(Icons.point_of_sale)),
              items: [
                for (final t in validTills ?? [])
                  DropdownMenuItem<String>(
                      value: t.id,
                      child: Text('${t.name} (${t.code})',
                          overflow: TextOverflow.ellipsis))
              ],
              onChanged: validTills?.isNotEmpty == true
                  ? (v) {
                      if (v != null) controller.till(v);
                    }
                  : null,
            ),
            if (tills.isLoading) const LinearProgressIndicator(),
            if (tills.hasError)
              TextButton(
                  onPressed: () =>
                      ref.invalidate(hardwareAssignableTillsProvider),
                  child: const Text('Cannot load authorized tills. Retry')),
            if (validOutlet && validTills?.isEmpty == true)
              const Text(
                  'No authorized active tills are available in this outlet.'),
            const SizedBox(height: TenantAdminSpacing.lg),
            profiles.when(
                loading: () => const LinearProgressIndicator(),
                error: (_, __) => TextButton(
                    onPressed: () =>
                        ref.invalidate(hardwareCompatibilityProvider),
                    child: const Text('Cannot load device options. Retry')),
                data: (items) => LayoutBuilder(builder: (context, constraints) {
                      final columns = constraints.maxWidth >= 900
                          ? 3
                          : constraints.maxWidth >= 550
                              ? 2
                              : 1;
                      final width = (constraints.maxWidth -
                              (columns - 1) * TenantAdminSpacing.lg) /
                          columns;
                      return Wrap(
                          spacing: TenantAdminSpacing.lg,
                          runSpacing: TenantAdminSpacing.lg,
                          children: [
                            for (final entry in hardwareTypes.entries)
                              SizedBox(
                                  width: width,
                                  child: HardwareSetupCard(
                                      child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                        Icon(hardwareTypeIcon(entry.key),
                                            size: 48,
                                            color: TenantAdminColors.primary),
                                        const SizedBox(
                                            height: TenantAdminSpacing.md),
                                        Text(entry.value,
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleMedium),
                                        const SizedBox(
                                            height: TenantAdminSpacing.sm),
                                        Text(items
                                                .where((p) =>
                                                    p.deviceType == entry.key)
                                                .firstOrNull
                                                ?.notes ??
                                            'No runtime adapter is available.'),
                                        const SizedBox(
                                            height: TenantAdminSpacing.lg),
                                        FilledButton(
                                            onPressed: !validOutlet ||
                                                    !validTill ||
                                                    !catalogReady ||
                                                    !items.any((p) =>
                                                        p.deviceType == entry.key &&
                                                        p.canConfigure)
                                                ? null
                                                : () => controller.choose(
                                                    items.firstWhere((p) =>
                                                        p.deviceType ==
                                                            entry.key &&
                                                        p.canConfigure)),
                                            child: Text(items.any((p) =>
                                                    p.deviceType == entry.key && p.canConfigure)
                                                ? 'Select Device'
                                                : 'Unavailable')),
                                      ]))),
                          ]);
                    })),
          ],
          if (state.step == 1) ...[
            if (!validOutlet || !validTill || !selectedProfileAvailable)
              const Text(
                  'Outlet, till or connection access is unavailable. Go back and review your selections.'),
            Text(hardwareTypeLabel(state.type),
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: TenantAdminSpacing.lg),
            Wrap(
                spacing: TenantAdminSpacing.sm,
                runSpacing: TenantAdminSpacing.sm,
                children: [
                  for (final p in connections.values)
                    ChoiceChip(
                        label: Text(state.type == 'CASH_DRAWER'
                            ? 'Printer Attached'
                            : p.connectionType),
                        selected: p.connectionType == state.connection,
                        onSelected: state.busy ||
                                state.scanning ||
                                !validOutlet ||
                                !validTill
                            ? null
                            : (_) => controller.connection(p.connectionType)),
                ]),
            const SizedBox(height: TenantAdminSpacing.lg),
            const Text(
                'Only actual local enumeration is shown. USB permission may be requested when selecting a device. Bluetooth printers must already be paired. LAN uses a manual host and port.'),
            if (state.scanning) const LinearProgressIndicator(),
            Wrap(spacing: TenantAdminSpacing.md, children: [
              if (state.type == 'RECEIPT_PRINTER' &&
                  state.connection != 'NETWORK')
                FilledButton(
                    onPressed: state.scanning ||
                            state.busy ||
                            !validOutlet ||
                            !validTill ||
                            !selectedProfileAvailable
                        ? null
                        : controller.discover,
                    child: const Text('Discover Devices')),
              if (state.scanning)
                OutlinedButton(
                    onPressed: controller.stop,
                    child: const Text('Stop Scanning')),
              OutlinedButton(
                  onPressed: state.scanning ||
                          state.busy ||
                          !validOutlet ||
                          !validTill ||
                          !selectedProfileAvailable
                      ? null
                      : controller.configure,
                  child: const Text('Configure manually')),
            ]),
            const SizedBox(height: TenantAdminSpacing.lg),
            Text('Detected Devices (${state.devices.length})',
                style: Theme.of(context).textTheme.titleMedium),
            if (state.lastScannedAt != null)
              Text(
                  'Last scan completed: ${state.lastScannedAt!.toLocal().toString().split('.').first}'),
            if (!state.scanning &&
                state.lastScannedAt != null &&
                state.devices.isEmpty)
              const Text(
                  'No devices detected. Check power, connection and permissions, then retry.'),
            for (final candidate in state.devices)
              Card(
                  child: ListTile(
                      leading: Icon(hardwareTypeIcon(state.type)),
                      title: Text(candidate.name,
                          maxLines: 2, overflow: TextOverflow.ellipsis),
                      subtitle:
                          const Text('Detected · Compatibility unverified'),
                      trailing: TextButton(
                          onPressed: state.busy ||
                                  !validOutlet ||
                                  !validTill ||
                                  !selectedProfileAvailable
                              ? null
                              : () => controller.select(candidate),
                          child: const Text('Use Device')))),
          ],
          if (state.step == 2) const HardwareConfigurationForm(),
          if (state.step >= 3) const HardwareSetupReview(),
          const SizedBox(height: TenantAdminSpacing.xl),
          Wrap(spacing: TenantAdminSpacing.md, children: [
            if (state.step > 0 && (state.device == null || state.step > 3))
              OutlinedButton(
                  onPressed:
                      state.busy || state.scanning ? null : controller.back,
                  child: const Text('Back')),
            TextButton(
                onPressed: state.busy
                    ? null
                    : () => context.go('/tenant-admin/hardware'),
                child: const Text('Back to Hardware Overview')),
            TextButton(
                onPressed: () => showSupportedHardware(context),
                child: const Text('View Supported Devices')),
          ]),
        ]));
  }
}

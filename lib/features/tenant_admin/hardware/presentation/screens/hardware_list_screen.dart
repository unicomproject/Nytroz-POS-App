import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../presentation/theme/tenant_admin_theme.dart';
import '../../../presentation/widgets/tenant_admin_buttons.dart';
import '../providers/hardware_list_provider.dart';
import '../widgets/assign_hardware_dialog.dart';

class HardwareListScreen extends ConsumerWidget {
  const HardwareListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hardwareState = ref.watch(hardwareListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hardware Management'),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TenantAdminPrimaryButton(
              label: 'Add Hardware',
              onPressed: () => context.go('/tenant-admin/hardware/new'),
            ),
          ),
        ],
      ),
      body: hardwareState.when(
        data: (hardwareList) {
          if (hardwareList.isEmpty) {
            return const Center(child: Text('No hardware registered yet.'));
          }
          return ListView.builder(
            itemCount: hardwareList.length,
            itemBuilder: (context, index) {
              final hardware = hardwareList[index];
              return ListTile(
                title: Text(hardware.hardwareDeviceName),
                subtitle:
                    Text('${hardware.hardwareDeviceType} • ${hardware.status}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!hardware.isAssigned)
                      TextButton(
                        onPressed: () => showDialog(
                          context: context,
                          builder: (_) => AssignHardwareDialog(
                            hardwareId: hardware.hardwareDeviceId,
                            hardwareName: hardware.hardwareDeviceName,
                          ),
                        ),
                        child: const Text('Assign to Till'),
                      ),
                    const SizedBox(width: 8),
                    Text(hardware.isAssigned ? 'Assigned' : 'Unassigned'),
                  ],
                ),
                onTap: () => context
                    .go('/tenant-admin/hardware/${hardware.hardwareDeviceId}'),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Error loading hardware: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.refresh(hardwareListProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

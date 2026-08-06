import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../presentation/widgets/tenant_admin_buttons.dart';
import '../../../tills/presentation/providers/till_providers.dart';
import '../providers/hardware_providers.dart';
import '../providers/hardware_list_provider.dart';

class AssignHardwareDialog extends ConsumerStatefulWidget {
  const AssignHardwareDialog({
    super.key,
    required this.hardwareId,
    required this.hardwareName,
  });

  final String hardwareId;
  final String hardwareName;

  @override
  ConsumerState<AssignHardwareDialog> createState() =>
      _AssignHardwareDialogState();
}

class _AssignHardwareDialogState extends ConsumerState<AssignHardwareDialog> {
  String? _selectedTillId;
  bool _submitting = false;

  @override
  Widget build(BuildContext context) {
    final tillsState = ref.watch(tillListResultFutureProvider);

    return AlertDialog(
      title: const Text('Assign Hardware'),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Assign ${widget.hardwareName} to a Till:'),
            const SizedBox(height: 16),
            tillsState.when(
              data: (result) {
                if (result == null || result.items.isEmpty) {
                  return const Text('No tills available.');
                }
                final tills = result.items;
                return DropdownButtonFormField<String>(
                  initialValue: _selectedTillId,
                  decoration: const InputDecoration(labelText: 'Select Till'),
                  items: tills.map((till) {
                    return DropdownMenuItem(
                      value: till.id,
                      child: Text('${till.name} (${till.code})'),
                    );
                  }).toList(),
                  onChanged: (val) => setState(() => _selectedTillId = val),
                );
              },
              loading: () => const CircularProgressIndicator(),
              error: (error, stack) => Text('Error loading tills: $error'),
            ),
          ],
        ),
      ),
      actions: [
        TenantAdminSecondaryButton(
          onPressed: _submitting ? null : () => Navigator.of(context).pop(),
          label: 'Cancel',
        ),
        const SizedBox(width: 8),
        TenantAdminPrimaryButton(
          label: _submitting ? 'Assigning...' : 'Assign',
          onPressed: _submitting || _selectedTillId == null ? null : _submit,
        ),
      ],
    );
  }

  Future<void> _submit() async {
    setState(() => _submitting = true);
    try {
      final request = {
        'hardwareDeviceId': widget.hardwareId,
        'isPrimary': false,
      };

      await ref.read(hardwareRepositoryProvider).assignHardwareToTill(
            tillId: _selectedTillId!,
            request: request,
          );

      ref.invalidate(hardwareListProvider);

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to assign hardware: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }
}

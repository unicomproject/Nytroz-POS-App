import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../presentation/theme/tenant_admin_theme.dart';
import '../../../presentation/widgets/tenant_admin_buttons.dart';
import '../../../presentation/widgets/tenant_admin_page_scaffold.dart';
import '../../../presentation/widgets/tenant_admin_states.dart';
import '../../../tills/presentation/providers/till_providers.dart';
import '../providers/hardware_providers.dart';

class AddHardwareScreen extends ConsumerStatefulWidget {
  const AddHardwareScreen({super.key, this.hardwareId});

  final String? hardwareId;

  @override
  ConsumerState<AddHardwareScreen> createState() => _AddHardwareScreenState();
}

class _AddHardwareScreenState extends ConsumerState<AddHardwareScreen> {
  final _formKey = GlobalKey<FormState>();

  String? _selectedOutletId;
  final _codeController = TextEditingController();
  final _nameController = TextEditingController();
  String _selectedType = 'RECEIPT_PRINTER';
  String _selectedConnectionType = 'NETWORK';
  final _configController = TextEditingController();

  bool _submitting = false;

  final _deviceTypes = [
    'RECEIPT_PRINTER',
    'BARCODE_SCANNER',
    'CASH_DRAWER',
    'PAYMENT_TERMINAL',
    'CUSTOMER_DISPLAY',
    'KITCHEN_PRINTER',
  ];

  final _connectionTypes = [
    'NETWORK',
    'USB',
    'BLUETOOTH',
    'SERIAL',
  ];

  @override
  void dispose() {
    _codeController.dispose();
    _nameController.dispose();
    _configController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final outletsState = ref.watch(tillOutletOptionsProvider);

    return TenantAdminPageScaffold(
      title: widget.hardwareId == null ? 'Add Hardware' : 'Edit Hardware',
      subtitle: 'Register a new hardware device.',
      child: outletsState.when(
        loading: () => const TenantAdminLoadingSkeleton(rowCount: 4),
        error: (error, stack) =>
            const Center(child: Text('Error loading outlets.')),
        data: (outlets) {
          if (outlets.isEmpty) {
            return const TenantAdminEmptyState(
              title: 'No outlets available',
              message: 'Create an outlet before adding hardware.',
            );
          }

          if (_selectedOutletId == null && outlets.isNotEmpty) {
            _selectedOutletId = outlets.first.id;
          }

          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(TenantAdminSpacing.lg),
              children: [
                DropdownButtonFormField<String>(
                  initialValue: _selectedOutletId,
                  decoration: const InputDecoration(labelText: 'Outlet'),
                  items: outlets.map((outlet) {
                    return DropdownMenuItem(
                      value: outlet.id,
                      child: Text(outlet.name),
                    );
                  }).toList(),
                  onChanged: (val) => setState(() => _selectedOutletId = val),
                ),
                const SizedBox(height: TenantAdminSpacing.md),
                TextFormField(
                  controller: _codeController,
                  decoration: const InputDecoration(
                      labelText: 'Device Code (e.g. PRINTER-01)'),
                  validator: (val) =>
                      val == null || val.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: TenantAdminSpacing.md),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                      labelText: 'Device Name (e.g. Receipt Printer 1)'),
                  validator: (val) =>
                      val == null || val.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: TenantAdminSpacing.md),
                DropdownButtonFormField<String>(
                  initialValue: _selectedType,
                  decoration: const InputDecoration(labelText: 'Device Type'),
                  items: _deviceTypes.map((type) {
                    return DropdownMenuItem(value: type, child: Text(type));
                  }).toList(),
                  onChanged: (val) => setState(() => _selectedType = val!),
                ),
                const SizedBox(height: TenantAdminSpacing.md),
                DropdownButtonFormField<String>(
                  initialValue: _selectedConnectionType,
                  decoration:
                      const InputDecoration(labelText: 'Connection Type'),
                  items: _connectionTypes.map((type) {
                    return DropdownMenuItem(value: type, child: Text(type));
                  }).toList(),
                  onChanged: (val) =>
                      setState(() => _selectedConnectionType = val!),
                ),
                const SizedBox(height: TenantAdminSpacing.md),
                TextFormField(
                  controller: _configController,
                  decoration: const InputDecoration(
                      labelText: 'Config JSON (Optional)'),
                  maxLines: 3,
                ),
                const SizedBox(height: TenantAdminSpacing.xl),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _submitting ? null : () => context.pop(),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: TenantAdminSpacing.md),
                    TenantAdminPrimaryButton(
                      label: _submitting ? 'Saving...' : 'Save Hardware',
                      onPressed: _submitting ? null : _submit,
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedOutletId == null) return;

    setState(() => _submitting = true);
    try {
      final request = {
        'outletId': _selectedOutletId,
        'hardwareDeviceCode': _codeController.text,
        'hardwareDeviceName': _nameController.text,
        'hardwareDeviceType': _selectedType,
        'connectionType': _selectedConnectionType,
        'status': 'ACTIVE',
        if (_configController.text.isNotEmpty)
          'configJson': _configController.text,
      };

      await ref.read(hardwareRepositoryProvider).createHardwareDevice(request);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Hardware created successfully.')),
        );
        context.go('/tenant-admin/hardware');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create hardware: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }
}

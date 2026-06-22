import 'package:flutter/material.dart';

import '../../../outlets/domain/entities/outlet.dart';
import '../../../presentation/theme/tenant_admin_theme.dart';
import '../../../presentation/widgets/tenant_admin_buttons.dart';
import '../../domain/entities/till.dart';

class TillForm extends StatefulWidget {
  const TillForm({
    super.key,
    required this.outlets,
    required this.backendErrors,
    required this.submitting,
    required this.onSubmit,
  });

  final List<Outlet> outlets;
  final Map<String, String> backendErrors;
  final bool submitting;
  final Future<void> Function(TillFormData form) onSubmit;

  @override
  State<TillForm> createState() => _TillFormState();
}

class _TillFormState extends State<TillForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _codeController = TextEditingController();
  String? _selectedOutletId;
  String _status = 'active';

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: 'Till name',
              errorText: widget.backendErrors['name'],
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Till name is required.';
              }
              return null;
            },
          ),
          const SizedBox(height: TenantAdminSpacing.lg),
          TextFormField(
            controller: _codeController,
            decoration: InputDecoration(
              labelText: 'Till code',
              errorText: widget.backendErrors['code'],
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Till code is required.';
              }
              return null;
            },
          ),
          const SizedBox(height: TenantAdminSpacing.lg),
          DropdownButtonFormField<String>(
            value: _selectedOutletId,
            decoration: InputDecoration(
              labelText: 'Outlet',
              errorText: widget.backendErrors['outletId'],
            ),
            items: [
              for (final outlet in widget.outlets)
                DropdownMenuItem<String>(
                  value: outlet.id,
                  child: Text(outlet.name),
                ),
            ],
            onChanged: widget.submitting
                ? null
                : (value) => setState(() => _selectedOutletId = value),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Outlet is required.';
              }
              return null;
            },
          ),
          const SizedBox(height: TenantAdminSpacing.lg),
          DropdownButtonFormField<String>(
            value: _status,
            decoration: InputDecoration(
              labelText: 'Status',
              errorText: widget.backendErrors['status'],
            ),
            items: const [
              DropdownMenuItem(value: 'active', child: Text('Active')),
              DropdownMenuItem(value: 'inactive', child: Text('Inactive')),
              DropdownMenuItem(value: 'maintenance', child: Text('Maintenance')),
            ],
            onChanged: widget.submitting
                ? null
                : (value) => setState(() => _status = value ?? 'active'),
          ),
          const SizedBox(height: TenantAdminSpacing.xl),
          Align(
            alignment: Alignment.centerRight,
            child: TenantAdminPrimaryButton(
              label: 'Save till',
              icon: Icons.save_outlined,
              loading: widget.submitting,
              onPressed: widget.submitting ? null : _submit,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    try {
      await widget.onSubmit(
        TillFormData(
          name: _nameController.text.trim(),
          code: _codeController.text.trim(),
          outletId: _selectedOutletId ?? '',
          status: _status,
        ),
      );
    } catch (_) {
      // Errors are handled by the screen callback.
    }
  }
}

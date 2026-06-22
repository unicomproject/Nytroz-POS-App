import 'package:flutter/material.dart';

class TillFormData {
  const TillFormData({
    required this.name,
    required this.code,
    required this.outletId,
    required this.status,
  });

  final String name;
  final String code;
  final String outletId;
  final String status;
}

class TillForm extends StatefulWidget {
  const TillForm({
    super.key,
    required this.outletOptions,
    required this.onSubmit,
    this.backendErrors = const {},
    this.submitting = false,
  });

  final List<TillFormOutletOption> outletOptions;
  final Future<void> Function(TillFormData data) onSubmit;
  final Map<String, String> backendErrors;
  final bool submitting;

  @override
  State<TillForm> createState() => _TillFormState();
}

class TillFormOutletOption {
  const TillFormOutletOption({
    required this.id,
    required this.label,
  });

  final String id;
  final String label;
}

class _TillFormState extends State<TillForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _codeController = TextEditingController();
  String? _outletId;
  String _status = 'active';

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _outletId ??=
        widget.outletOptions.isNotEmpty ? widget.outletOptions.first.id : null;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: 'Till name',
              errorText: widget.backendErrors['name'],
            ),
            validator: (value) =>
                value == null || value.trim().isEmpty ? 'Name is required.' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _codeController,
            decoration: InputDecoration(
              labelText: 'Till code',
              errorText: widget.backendErrors['code'],
            ),
            validator: (value) =>
                value == null || value.trim().isEmpty ? 'Code is required.' : null,
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _outletId,
            decoration: InputDecoration(
              labelText: 'Outlet',
              errorText: widget.backendErrors['outletId'],
            ),
            items: widget.outletOptions
                .map(
                  (option) => DropdownMenuItem(
                    value: option.id,
                    child: Text(option.label),
                  ),
                )
                .toList(growable: false),
            onChanged: widget.outletOptions.isEmpty
                ? null
                : (value) => setState(() => _outletId = value),
            validator: (value) =>
                value == null || value.isEmpty ? 'Outlet is required.' : null,
          ),
          const SizedBox(height: 16),
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
            onChanged: (value) {
              if (value != null) {
                setState(() => _status = value);
              }
            },
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: widget.submitting ? null : _submit,
            child: widget.submitting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Create till'),
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    await widget.onSubmit(
      TillFormData(
        name: _nameController.text.trim(),
        code: _codeController.text.trim(),
        outletId: _outletId ?? '',
        status: _status,
      ),
    );
  }
}

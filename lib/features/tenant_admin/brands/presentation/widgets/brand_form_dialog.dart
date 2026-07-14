import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../domain/entities/brand.dart';
import '../../../presentation/theme/tenant_admin_theme.dart';
import '../../../presentation/widgets/tenant_admin_buttons.dart';

String brandApiErrorMessage(Object error) {
  if (error is DioException) {
    final data = error.response?.data;
    if (data is Map) {
      final message = data['message']?.toString();
      if (message != null && message.trim().isNotEmpty) {
        return message;
      }
    }

    return error.message ?? 'Unable to save brand.';
  }

  return error.toString();
}

String deriveBrandCode(String name) {
  final normalized = name
      .trim()
      .toUpperCase()
      .replaceAll(RegExp(r'[^A-Z0-9]+'), '_')
      .replaceAll(RegExp(r'_+'), '_')
      .replaceAll(RegExp(r'^_|_$'), '');

  return normalized.isEmpty ? 'BRAND' : normalized;
}

Future<BrandUpsertInput?> showBrandFormDialog({
  required BuildContext context,
  Brand? existing,
}) {
  return showDialog<BrandUpsertInput>(
    context: context,
    barrierDismissible: false,
    builder: (context) => BrandFormDialog(existing: existing),
  );
}

class BrandFormDialog extends StatefulWidget {
  const BrandFormDialog({super.key, this.existing});

  final Brand? existing;

  @override
  State<BrandFormDialog> createState() => _BrandFormDialogState();
}

class _BrandFormDialogState extends State<BrandFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _codeController;
  late final TextEditingController _descriptionController;
  late String _status;
  bool _codeEditedManually = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.existing?.name ?? '');
    _codeController = TextEditingController(text: widget.existing?.code ?? '');
    _descriptionController =
        TextEditingController(text: widget.existing?.description ?? '');
    _status = widget.existing?.status.toUpperCase() ?? 'ACTIVE';
    _codeEditedManually = widget.existing != null;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;

    return AlertDialog(
      title: Text(isEdit ? 'Edit Brand' : 'Add Brand'),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Brand name',
                  hintText: 'Enter brand name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Brand name is required.';
                  }
                  return null;
                },
                onChanged: (value) {
                  if (!_codeEditedManually) {
                    _codeController.text = deriveBrandCode(value);
                  }
                },
              ),
              const SizedBox(height: TenantAdminSpacing.md),
              TextFormField(
                controller: _codeController,
                decoration: const InputDecoration(
                  labelText: 'Brand code',
                  hintText: 'Enter brand code',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Brand code is required.';
                  }
                  return null;
                },
                onChanged: (_) => _codeEditedManually = true,
              ),
              const SizedBox(height: TenantAdminSpacing.md),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description (optional)',
                  hintText: 'Add a short description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: TenantAdminSpacing.md),
              DropdownButtonFormField<String>(
                value: _status,
                decoration: const InputDecoration(
                  labelText: 'Status',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'ACTIVE', child: Text('Active')),
                  DropdownMenuItem(value: 'INACTIVE', child: Text('Inactive')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _status = value);
                  }
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TenantAdminPrimaryButton(
          label: isEdit ? 'Save changes' : 'Add brand',
          onPressed: _submit,
        ),
      ],
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    Navigator.of(context).pop(
      BrandUpsertInput(
        code: _codeController.text,
        name: _nameController.text,
        status: _status,
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
      ),
    );
  }
}

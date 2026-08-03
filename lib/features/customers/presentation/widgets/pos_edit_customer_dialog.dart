import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../sale/domain/entities/pos_customer.dart';
import '../../../sale/presentation/widgets/payment/pos_bottom_action_buttons.dart';
import '../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';
import '../../../../shared/presentation/app_modal.dart';
import '../providers/customers_provider.dart';

Future<PosCustomer?> showPosEditCustomerDialog({
  required BuildContext context,
  required WidgetRef ref,
  required PosCustomer customer,
}) {
  final container = ProviderScope.containerOf(context, listen: false);

  return showAppDialog<PosCustomer>(
    context: context,
    builder: (_) => UncontrolledProviderScope(
      container: container,
      child: _PosEditCustomerDialog(customer: customer),
    ),
  );
}

class _PosEditCustomerDialog extends ConsumerStatefulWidget {
  const _PosEditCustomerDialog({required this.customer});

  final PosCustomer customer;

  @override
  ConsumerState<_PosEditCustomerDialog> createState() =>
      _PosEditCustomerDialogState();
}

class _PosEditCustomerDialogState
    extends ConsumerState<_PosEditCustomerDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _fullNameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;
  late String _status;

  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fullNameController = TextEditingController(text: widget.customer.fullName);
    _phoneController = TextEditingController(text: widget.customer.phone ?? '');
    _emailController = TextEditingController(text: widget.customer.email ?? '');
    _status = widget.customer.isActive ? 'ACTIVE' : 'INACTIVE';
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Dialog(
        backgroundColor: TenantAdminColors.surface,
        surfaceTintColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(TenantAdminSpacing.lg),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(TenantAdminRadius.lg),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Padding(
            padding: const EdgeInsets.all(TenantAdminSpacing.xl),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Edit Customer',
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    color: TenantAdminColors.bodyText,
                                    fontWeight: FontWeight.w900,
                                  ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Close',
                        onPressed: _isSaving
                            ? null
                            : () => Navigator.of(context).pop(null),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: TenantAdminSpacing.lg),
                  TextFormField(
                    readOnly: true,
                    initialValue: widget.customer.shortCustomerId,
                    decoration: const InputDecoration(
                      labelText: 'Customer Code',
                    ),
                  ),
                  const SizedBox(height: TenantAdminSpacing.md),
                  TextFormField(
                    controller: _fullNameController,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(labelText: 'Name'),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Name is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: TenantAdminSpacing.md),
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.next,
                    decoration:
                        const InputDecoration(labelText: 'Phone number'),
                  ),
                  const SizedBox(height: TenantAdminSpacing.md),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(labelText: 'Email'),
                    validator: (value) {
                      final email = value?.trim() ?? '';
                      if (email.isEmpty) {
                        return null;
                      }
                      final isValid =
                          RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email);
                      return isValid ? null : 'Enter a valid email';
                    },
                  ),
                  const SizedBox(height: TenantAdminSpacing.md),
                  DropdownButtonFormField<String>(
                    initialValue: _status,
                    decoration: const InputDecoration(labelText: 'Status'),
                    items: const [
                      DropdownMenuItem(
                        value: 'ACTIVE',
                        child: Text('Active'),
                      ),
                      DropdownMenuItem(
                        value: 'INACTIVE',
                        child: Text('Inactive'),
                      ),
                    ],
                    onChanged: _isSaving
                        ? null
                        : (value) {
                            if (value != null) {
                              setState(() => _status = value);
                            }
                          },
                  ),
                  if (_errorMessage != null) ...[
                    const SizedBox(height: TenantAdminSpacing.md),
                    Text(
                      _errorMessage!,
                      style: const TextStyle(
                        color: TenantAdminColors.danger,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                  const SizedBox(height: TenantAdminSpacing.xl),
                  PosPrimaryActionButton(
                    onPressed: _isSaving ? null : _save,
                    icon: Icons.save_outlined,
                    isLoading: _isSaving,
                    label: 'Save Changes',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final updated = await ref.read(customersProvider.notifier).updateCustomer(
            customerId: widget.customer.customerId,
            fullName: _fullNameController.text.trim(),
            phone: _emptyToNull(_phoneController.text),
            email: _emptyToNull(_emailController.text),
            status: _status,
          );

      if (!mounted) {
        return;
      }

      if (updated == null) {
        setState(() {
          _errorMessage = 'Unable to update customer. Try again.';
        });
        return;
      }

      Navigator.of(context).pop(updated);
    } on DioException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage = error.response?.statusCode == 403
            ? 'Permission Denied'
            : _mapError(error);
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage = 'Unable to update customer. Try again.';
      });
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  String? _emptyToNull(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  String _mapError(DioException error) {
    final data = error.response?.data;
    if (data is Map) {
      final message = data['message']?.toString() ??
          data['Message']?.toString() ??
          data['title']?.toString();
      if (message != null && message.trim().isNotEmpty) {
        return message.trim();
      }
    }
    return 'Unable to update customer. Try again.';
  }
}

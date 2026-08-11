import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nytroz_pos/features/sale/domain/entities/pos_customer.dart';
import 'package:nytroz_pos/features/sale/presentation/widgets/payment_method/payment_method_style.dart';
import 'package:nytroz_pos/features/tenant_admin/presentation/theme/tenant_admin_theme.dart';
import 'package:nytroz_pos/shared/presentation/app_modal.dart';
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
          constraints: const BoxConstraints(maxWidth: 540),
          child: Padding(
            padding: const EdgeInsets.all(TenantAdminSpacing.xl),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _DialogHeader(
                    onClose: _isSaving
                        ? null
                        : () => Navigator.of(context).pop(null),
                  ),
                  const SizedBox(height: TenantAdminSpacing.xl),
                  TextFormField(
                    readOnly: true,
                    initialValue: widget.customer.shortCustomerId,
                    decoration: InputDecoration(
                      labelText: 'Customer Code',
                      prefixIcon: const Icon(Icons.badge_outlined),
                      floatingLabelStyle: const TextStyle(
                        color: PaymentMethodStyle.orange,
                        fontWeight: FontWeight.w700,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(TenantAdminRadius.md),
                        borderSide: const BorderSide(
                          color: PaymentMethodStyle.orange,
                          width: 1.5,
                        ),
                      ),
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(TenantAdminRadius.md),
                      ),
                    ),
                  ),
                  const SizedBox(height: TenantAdminSpacing.md),
                  _CustomerField(
                    controller: _fullNameController,
                    label: 'Name',
                    hint: 'Enter customer full name',
                    icon: Icons.person_outline_rounded,
                    textInputAction: TextInputAction.next,
                    maxLength: 150,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Name is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: TenantAdminSpacing.md),
                  _CustomerField(
                    controller: _phoneController,
                    label: 'Phone number',
                    hint: 'Enter customer phone number',
                    icon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.next,
                    maxLength: 50,
                    validator: (value) {
                      final phone = value?.trim() ?? '';
                      if (phone.isEmpty) return null;
                      if (RegExp(r'\d').allMatches(phone).length < 7) {
                        return 'Enter a valid phone number';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: TenantAdminSpacing.md),
                  _CustomerField(
                    controller: _emailController,
                    label: 'Email',
                    hint: 'Enter customer email address',
                    icon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.done,
                    maxLength: 150,
                    onFieldSubmitted: (_) => _submitIfAllowed(),
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
                    decoration: InputDecoration(
                      labelText: 'Status',
                      prefixIcon: const Icon(Icons.verified_user_outlined),
                      floatingLabelStyle: const TextStyle(
                        color: PaymentMethodStyle.orange,
                        fontWeight: FontWeight.w700,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(TenantAdminRadius.md),
                        borderSide: const BorderSide(
                          color: PaymentMethodStyle.orange,
                          width: 1.5,
                        ),
                      ),
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(TenantAdminRadius.md),
                      ),
                    ),
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
                    _InlineMessage(message: _errorMessage!, isError: true),
                  ],
                  const SizedBox(height: TenantAdminSpacing.xl),
                  SizedBox(
                    height: 52,
                    child: FilledButton.icon(
                      onPressed: _isSaving ? null : _save,
                      icon: _isSaving
                          ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.save_outlined),
                      label: Text(
                        _isSaving ? 'Saving Changes...' : 'Save Changes',
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: PaymentMethodStyle.orange,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor:
                            PaymentMethodStyle.orange.withValues(alpha: 0.45),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(TenantAdminRadius.md),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: TenantAdminSpacing.sm),
                  TextButton(
                    onPressed: _isSaving
                        ? null
                        : () => Navigator.of(context).pop(null),
                    style: TextButton.styleFrom(
                      foregroundColor: PaymentMethodStyle.orange,
                    ),
                    child: const Text('Cancel'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _submitIfAllowed() {
    if (!_isSaving) {
      _save();
    }
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

class _DialogHeader extends StatelessWidget {
  const _DialogHeader({required this.onClose});

  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: PaymentMethodStyle.orange.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(TenantAdminRadius.md),
          ),
          child: const Icon(
            Icons.person_rounded,
            color: PaymentMethodStyle.orange,
          ),
        ),
        const SizedBox(width: TenantAdminSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Edit Customer',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: TenantAdminColors.bodyText,
                      fontWeight: FontWeight.w900,
                    ),
              ),
              const SizedBox(height: TenantAdminSpacing.xs),
              const Text(
                'Update customer details below.',
                style: TextStyle(
                  color: TenantAdminColors.mutedText,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: 'Close',
          onPressed: onClose,
          icon: const Icon(Icons.close_rounded),
        ),
      ],
    );
  }
}

class _CustomerField extends StatelessWidget {
  const _CustomerField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    required this.textInputAction,
    required this.maxLength,
    required this.validator,
    this.keyboardType,
    this.onFieldSubmitted,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final TextInputType? keyboardType;
  final TextInputAction textInputAction;
  final int maxLength;
  final FormFieldValidator<String> validator;
  final ValueChanged<String>? onFieldSubmitted;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      maxLength: maxLength,
      validator: validator,
      onFieldSubmitted: onFieldSubmitted,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        counterText: '',
        prefixIcon: Icon(icon),
        floatingLabelStyle: const TextStyle(
          color: PaymentMethodStyle.orange,
          fontWeight: FontWeight.w700,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(TenantAdminRadius.md),
          borderSide: const BorderSide(
            color: PaymentMethodStyle.orange,
            width: 1.5,
          ),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(TenantAdminRadius.md),
        ),
      ),
    );
  }
}

class _InlineMessage extends StatelessWidget {
  const _InlineMessage({required this.message, this.isError = false});

  final String message;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final color =
        isError ? TenantAdminColors.danger : TenantAdminColors.warning;
    return Container(
      padding: const EdgeInsets.all(TenantAdminSpacing.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(TenantAdminRadius.md),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Icon(
            isError ? Icons.error_outline_rounded : Icons.lock_outline_rounded,
            color: color,
            size: 20,
          ),
          const SizedBox(width: TenantAdminSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: color, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

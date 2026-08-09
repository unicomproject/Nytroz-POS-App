import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nytroz_pos/core/network/dio_provider.dart';
import 'package:nytroz_pos/features/device_activation/presentation/providers/device_activation_provider.dart';
import 'package:nytroz_pos/features/sale/data/datasources/pos_customer_remote_datasource.dart';
import 'package:nytroz_pos/features/sale/domain/entities/pos_customer.dart';
import 'package:nytroz_pos/features/sale/presentation/widgets/payment_method/payment_method_style.dart';
import 'package:nytroz_pos/shared/presentation/app_modal.dart';

import '../../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';

Future<PosCustomer?> showPosNewSaleCustomerDialog({
  required BuildContext context,
  required WidgetRef ref,
  required bool canCreateCustomer,
}) {
  final container = ProviderScope.containerOf(context, listen: false);

  return showAppDialog<PosCustomer>(
    context: context,
    builder: (_) => UncontrolledProviderScope(
      container: container,
      child: _PosAddCustomerDialog(
        canCreateCustomer: canCreateCustomer,
      ),
    ),
  );
}

class _PosAddCustomerDialog extends ConsumerStatefulWidget {
  const _PosAddCustomerDialog({required this.canCreateCustomer});

  final bool canCreateCustomer;

  @override
  ConsumerState<_PosAddCustomerDialog> createState() =>
      _PosAddCustomerDialogState();
}

class _PosAddCustomerDialogState extends ConsumerState<_PosAddCustomerDialog> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();

  bool _isCreating = false;
  String? _errorMessage;

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
                    onClose: _isCreating
                        ? null
                        : () => Navigator.of(context).pop(null),
                  ),
                  const SizedBox(height: TenantAdminSpacing.xl),
                  _CustomerField(
                    key: const ValueKey('add-customer-name'),
                    controller: _fullNameController,
                    label: 'Full Name',
                    hint: 'Enter customer full name',
                    icon: Icons.person_outline_rounded,
                    textInputAction: TextInputAction.next,
                    maxLength: 150,
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Full name is required'
                        : null,
                  ),
                  const SizedBox(height: TenantAdminSpacing.md),
                  _CustomerField(
                    key: const ValueKey('add-customer-phone'),
                    controller: _phoneController,
                    label: 'Phone Number',
                    hint: 'Enter customer phone number',
                    icon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.next,
                    maxLength: 50,
                    validator: (value) {
                      final phone = value?.trim() ?? '';
                      if (phone.isEmpty) return 'Phone number is required';
                      if (RegExp(r'\d').allMatches(phone).length < 7) {
                        return 'Enter a valid phone number';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: TenantAdminSpacing.md),
                  _CustomerField(
                    key: const ValueKey('add-customer-email'),
                    controller: _emailController,
                    label: 'Email (Optional)',
                    hint: 'Enter customer email address',
                    icon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.done,
                    maxLength: 150,
                    onFieldSubmitted: (_) => _submitIfAllowed(),
                    validator: (value) {
                      final email = value?.trim() ?? '';
                      if (email.isEmpty) return null;
                      return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                              .hasMatch(email)
                          ? null
                          : 'Enter a valid email address';
                    },
                  ),
                  if (!widget.canCreateCustomer) ...[
                    const SizedBox(height: TenantAdminSpacing.md),
                    const _InlineMessage(
                      message:
                          'You do not have permission to create customers.',
                    ),
                  ],
                  if (_errorMessage != null) ...[
                    const SizedBox(height: TenantAdminSpacing.md),
                    _InlineMessage(message: _errorMessage!, isError: true),
                  ],
                  const SizedBox(height: TenantAdminSpacing.xl),
                  SizedBox(
                    height: 52,
                    child: FilledButton.icon(
                      key: const ValueKey('create-customer-button'),
                      onPressed: widget.canCreateCustomer && !_isCreating
                          ? _createCustomer
                          : null,
                      icon: _isCreating
                          ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.person_add_alt_1_rounded),
                      label: Text(
                        _isCreating ? 'Creating Customer...' : 'Add Customer',
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
                    onPressed: _isCreating
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
    if (widget.canCreateCustomer && !_isCreating) {
      _createCustomer();
    }
  }

  Future<void> _createCustomer() async {
    if (!_formKey.currentState!.validate()) return;

    final deviceContext = ref.read(deviceActivationProvider).deviceContext;
    if (deviceContext == null) {
      setState(() => _errorMessage = 'Device context is not available.');
      return;
    }

    setState(() {
      _isCreating = true;
      _errorMessage = null;
    });

    try {
      final customer =
          await PosCustomerRemoteDatasource(ref.read(appDioProvider))
              .createCustomer(
        deviceId: deviceContext.deviceId,
        fullName: _fullNameController.text.trim(),
        phone: _phoneController.text.trim(),
        email: _emptyToNull(_emailController.text),
      );
      if (mounted) Navigator.of(context).pop(customer);
    } on DioException catch (error) {
      if (!mounted) return;
      setState(() => _errorMessage = _apiMessage(error));
    } catch (_) {
      if (!mounted) return;
      setState(() => _errorMessage = 'Unable to add customer. Try again.');
    } finally {
      if (mounted) setState(() => _isCreating = false);
    }
  }

  String _apiMessage(DioException error) {
    final data = error.response?.data;
    if (data is Map) {
      final message = data['message'] ?? data['error']?['message'];
      if (message is String && message.trim().isNotEmpty) {
        return message.trim();
      }
    }
    return 'Unable to add customer. Try again.';
  }

  String? _emptyToNull(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
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
            Icons.person_add_alt_1_rounded,
            color: PaymentMethodStyle.orange,
          ),
        ),
        const SizedBox(width: TenantAdminSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Add Customer',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: TenantAdminColors.bodyText,
                      fontWeight: FontWeight.w900,
                    ),
              ),
              const SizedBox(height: TenantAdminSpacing.xs),
              const Text(
                'Enter the customer details below.',
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
    super.key,
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

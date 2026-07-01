import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nytroz_pos/features/tenant_admin/presentation/theme/tenant_admin_theme.dart';

import '../../domain/entities/pos_customer.dart';
import '../providers/customer_registration_provider.dart';
import 'customer_date_field.dart';
import 'customer_phone_field.dart';

/// Quick Add New Customer form shown inside the Add Customer modal.
///
/// FRONTEND-ONLY: on submit it builds a [PosCustomer] locally and attaches it to
/// the current sale's UI selection (no backend create call). [onAttached] is
/// invoked after a successful save so the modal can close and confirm.
class QuickAddCustomerForm extends ConsumerStatefulWidget {
  const QuickAddCustomerForm({super.key, required this.onAttached});

  final ValueChanged<PosCustomer> onAttached;

  @override
  ConsumerState<QuickAddCustomerForm> createState() =>
      _QuickAddCustomerFormState();
}

class _QuickAddCustomerFormState extends ConsumerState<QuickAddCustomerForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();

  String _dialCode = kCustomerDialCodes.first;
  DateTime? _dateOfBirth;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _nameController.addListener(_onRequiredChanged);
    _phoneController.addListener(_onRequiredChanged);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _onRequiredChanged() => setState(() {});

  bool get _canSubmit =>
      !_submitting &&
      _nameController.text.trim().isNotEmpty &&
      _phoneController.text.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: ListView(
        shrinkWrap: true,
        padding: EdgeInsets.fromLTRB(
          TenantAdminSpacing.lg,
          TenantAdminSpacing.lg,
          TenantAdminSpacing.lg,
          TenantAdminSpacing.lg + MediaQuery.viewInsetsOf(context).bottom,
        ),
        children: [
          Text(
            'Quick Add New Customer',
            style: TenantAdminTextStyles.sectionTitle(context),
          ),
          const SizedBox(height: TenantAdminSpacing.xs),
          Text(
            'Add a customer and attach them to this sale.',
            style: TenantAdminTextStyles.muted(context),
          ),
          const SizedBox(height: TenantAdminSpacing.lg),
          const CustomerFieldLabel(label: 'Full Name', isRequired: true),
          const SizedBox(height: TenantAdminSpacing.sm),
          TextFormField(
            controller: _nameController,
            textInputAction: TextInputAction.next,
            textCapitalization: TextCapitalization.words,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Full name is required';
              }
              return null;
            },
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: TenantAdminColors.bodyText,
                  fontWeight: FontWeight.w600,
                ),
            decoration: customerInputDecoration(
              context,
              hint: 'e.g., Aisha Khan',
            ),
          ),
          const SizedBox(height: TenantAdminSpacing.lg),
          CustomerPhoneField(
            controller: _phoneController,
            dialCode: _dialCode,
            onDialCodeChanged: (value) => setState(() => _dialCode = value),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Phone number is required';
              }
              final digits = value.replaceAll(RegExp(r'\D'), '');
              if (digits.length < 6) {
                return 'Enter a valid phone number';
              }
              return null;
            },
          ),
          const SizedBox(height: TenantAdminSpacing.lg),
          const CustomerFieldLabel(label: 'Email (Optional)'),
          const SizedBox(height: TenantAdminSpacing.sm),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            validator: (value) {
              final email = value?.trim() ?? '';
              if (email.isEmpty) {
                return null;
              }
              final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
              if (!emailRegex.hasMatch(email)) {
                return 'Enter a valid email address';
              }
              return null;
            },
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: TenantAdminColors.bodyText,
                  fontWeight: FontWeight.w600,
                ),
            decoration: customerInputDecoration(
              context,
              hint: 'e.g., customer@example.com',
            ),
          ),
          const SizedBox(height: TenantAdminSpacing.lg),
          CustomerDateField(
            label: 'Date of Birth (Optional)',
            value: _dateOfBirth,
            onChanged: (value) => setState(() => _dateOfBirth = value),
          ),
          const SizedBox(height: TenantAdminSpacing.xl),
          SizedBox(
            height: 56,
            child: FilledButton.icon(
              onPressed: _canSubmit ? _submit : null,
              icon: _submitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.person_add_alt_1_rounded, size: 20),
              label: Text(_submitting ? 'Saving…' : 'Save & Attach Customer'),
              style: FilledButton.styleFrom(
                backgroundColor: TenantAdminColors.info,
                foregroundColor: Colors.white,
                textStyle: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(TenantAdminRadius.md),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    if (_submitting || !(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() => _submitting = true);

    try {
      final customer =
          await ref.read(customerRegistrationControllerProvider).createAndAttach(
                fullName: _nameController.text,
                dialCode: _dialCode,
                phoneNumber: _phoneController.text,
                email: _emailController.text,
                dateOfBirth: _dateOfBirth,
              );

      if (!mounted) {
        return;
      }
      widget.onAttached(customer);
    } on CustomerRegistrationException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(error.message)));
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Could not save the customer. Please try again.'),
          ),
        );
    }
  }
}

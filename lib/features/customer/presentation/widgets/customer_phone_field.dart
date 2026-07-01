import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nytroz_pos/features/tenant_admin/presentation/theme/tenant_admin_theme.dart';

/// Dial codes offered by the Quick Add phone field. UI-local only.
const List<String> kCustomerDialCodes = ['+44', '+94', '+1', '+91', '+61'];

/// Labelled phone input with a country dial-code selector, matching the POS
/// form style. The dial code is held by the parent; the number uses [controller]
/// so the parent's [Form] can validate it.
class CustomerPhoneField extends StatelessWidget {
  const CustomerPhoneField({
    super.key,
    required this.controller,
    required this.dialCode,
    required this.onDialCodeChanged,
    this.validator,
  });

  final TextEditingController controller;
  final String dialCode;
  final ValueChanged<String> onDialCodeChanged;
  final FormFieldValidator<String>? validator;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(TenantAdminRadius.md);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const CustomerFieldLabel(
          label: 'Phone Number',
          isRequired: true,
        ),
        const SizedBox(height: TenantAdminSpacing.sm),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 52,
              padding: const EdgeInsets.symmetric(
                horizontal: TenantAdminSpacing.md,
              ),
              decoration: BoxDecoration(
                color: TenantAdminColors.background,
                borderRadius: radius,
                border: Border.all(color: TenantAdminColors.border),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: dialCode,
                  isDense: true,
                  borderRadius: radius,
                  icon: const Icon(Icons.expand_more_rounded, size: 18),
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: TenantAdminColors.bodyText,
                        fontWeight: FontWeight.w700,
                      ),
                  items: [
                    for (final code in kCustomerDialCodes)
                      DropdownMenuItem<String>(
                        value: code,
                        child: Text(code),
                      ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      onDialCodeChanged(value);
                    }
                  },
                ),
              ),
            ),
            const SizedBox(width: TenantAdminSpacing.sm),
            Expanded(
              child: TextFormField(
                controller: controller,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
                validator: validator,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9 +\-]')),
                ],
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: TenantAdminColors.bodyText,
                      fontWeight: FontWeight.w600,
                    ),
                decoration: customerInputDecoration(
                  context,
                  hint: '7700 900000',
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Shared POS form-field decoration used by the Quick Add customer fields.
InputDecoration customerInputDecoration(
  BuildContext context, {
  required String hint,
}) {
  final radius = BorderRadius.circular(TenantAdminRadius.md);
  return InputDecoration(
    isDense: true,
    hintText: hint,
    hintStyle: TenantAdminTextStyles.muted(context),
    filled: true,
    fillColor: TenantAdminColors.background,
    contentPadding: const EdgeInsets.symmetric(
      horizontal: TenantAdminSpacing.md,
      vertical: TenantAdminSpacing.md,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: radius,
      borderSide: const BorderSide(color: TenantAdminColors.border),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: radius,
      borderSide: const BorderSide(color: TenantAdminColors.info, width: 1.5),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: radius,
      borderSide: const BorderSide(color: TenantAdminColors.danger),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: radius,
      borderSide: const BorderSide(color: TenantAdminColors.danger, width: 1.5),
    ),
  );
}

/// Bold form-field label with an optional required asterisk.
class CustomerFieldLabel extends StatelessWidget {
  const CustomerFieldLabel({super.key, required this.label, this.isRequired = false});

  final String label;
  final bool isRequired;

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        text: label,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: TenantAdminColors.bodyText,
              fontWeight: FontWeight.w800,
            ),
        children: [
          if (isRequired)
            const TextSpan(
              text: ' *',
              style: TextStyle(color: TenantAdminColors.danger),
            ),
        ],
      ),
    );
  }
}

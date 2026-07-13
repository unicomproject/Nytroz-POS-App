import 'package:flutter/material.dart';

import '../../../presentation/theme/tenant_admin_theme.dart';

class ProductOptionDropdown extends StatelessWidget {
  const ProductOptionDropdown({
    super.key,
    required this.label,
    required this.hint,
    required this.icon,
    required this.value,
    required this.items,
    required this.enabled,
    this.onChanged,
    this.errorText,
  });

  final String label;
  final String hint;
  final IconData icon;
  final String? value;
  final List<DropdownMenuItem<String>> items;
  final bool enabled;
  final ValueChanged<String?>? onChanged;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: TenantAdminColors.bodyText,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: TenantAdminSpacing.sm),
        DropdownButtonFormField<String>(
          initialValue: value,
          items: items,
          onChanged: enabled ? onChanged : null,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, size: 19),
            filled: true,
            fillColor: TenantAdminColors.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(TenantAdminRadius.md),
              borderSide: const BorderSide(color: TenantAdminColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(TenantAdminRadius.md),
              borderSide: const BorderSide(color: TenantAdminColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(TenantAdminRadius.md),
              borderSide: const BorderSide(color: TenantAdminColors.primary),
            ),
            errorText: errorText,
          ),
        ),
      ],
    );
  }
}

class ProductFormTextField extends StatelessWidget {
  const ProductFormTextField({
    super.key,
    required this.label,
    required this.hint,
    required this.icon,
    required this.controller,
    required this.enabled,
    this.keyboardType,
    this.errorText,
  });

  final String label;
  final String hint;
  final IconData icon;
  final TextEditingController controller;
  final bool enabled;
  final TextInputType? keyboardType;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: TenantAdminColors.bodyText,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: TenantAdminSpacing.sm),
        TextField(
          controller: controller,
          enabled: enabled,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, size: 19),
            filled: true,
            fillColor: TenantAdminColors.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(TenantAdminRadius.md),
              borderSide: const BorderSide(color: TenantAdminColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(TenantAdminRadius.md),
              borderSide: const BorderSide(color: TenantAdminColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(TenantAdminRadius.md),
              borderSide: const BorderSide(color: TenantAdminColors.primary),
            ),
            errorText: errorText,
          ),
        ),
      ],
    );
  }
}

List<DropdownMenuItem<String>> buildOptionItems({
  required List<({String id, String label})> options,
  required String emptyLabel,
}) {
  if (options.isEmpty) {
    return [
      DropdownMenuItem<String>(
        value: null,
        enabled: false,
        child: Text(emptyLabel),
      ),
    ];
  }

  return options
      .map(
        (option) => DropdownMenuItem<String>(
          value: option.id,
          child: Text(option.label),
        ),
      )
      .toList();
}

String? labelForId(
  String? id,
  List<({String id, String label})> options,
) {
  if (id == null) {
    return null;
  }

  for (final option in options) {
    if (option.id == id) {
      return option.label;
    }
  }

  return null;
}

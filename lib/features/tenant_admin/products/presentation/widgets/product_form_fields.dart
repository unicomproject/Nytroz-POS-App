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
    this.enabled = true,
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
    final effectiveValue =
        items.any((item) => item.value == value) ? value : null;

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
          initialValue: effectiveValue,
          items: items,
          onChanged: enabled ? onChanged : null,
          decoration: InputDecoration(
            hintText: hint,
            // Single-line dropdown icon is vertically centered
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
    this.enabled = true,
    this.keyboardType,
    this.maxLines = 1,
    this.maxLength,
    this.helperText,
    this.errorText,
  });

  final String label;
  final String hint;
  final IconData icon;
  final TextEditingController controller;
  final bool enabled;
  final TextInputType? keyboardType;
  final int maxLines;
  final int? maxLength;
  final String? helperText;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final isMultiLine = maxLines > 1;

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
        Stack(
          children: [
            TextField(
              controller: controller,
              enabled: enabled,
              keyboardType: keyboardType,
              maxLines: maxLines,
              maxLength: maxLength,
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: const TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 13,
                ),
                helperText: helperText,
                helperStyle: const TextStyle(
                  fontSize: 11,
                  color: TenantAdminColors.mutedText,
                ),
                contentPadding: isMultiLine
                    ? const EdgeInsets.only(
                        left: 42, top: 14, right: 14, bottom: 14)
                    : null,
                prefixIcon: isMultiLine ? null : Icon(icon, size: 19),
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
                  borderSide:
                      const BorderSide(color: TenantAdminColors.primary),
                ),
                errorText: errorText,
              ),
            ),
            if (isMultiLine)
              Positioned(
                top: 14,
                left: 14,
                child: IgnorePointer(
                  child: Icon(
                    icon,
                    size: 19,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ),
          ],
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
  String id,
  List<({String id, String label})> options,
) {
  for (final option in options) {
    if (option.id == id) {
      return option.label;
    }
  }

  return null;
}

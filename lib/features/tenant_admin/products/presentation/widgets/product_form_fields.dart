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
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: TenantAdminColors.bodyText,
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          initialValue: effectiveValue,
          items: items,
          isExpanded: true,
          onChanged: enabled ? onChanged : null,
          decoration: InputDecoration(
            isDense: true,
            hintText: hint,
            hintStyle: const TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 13,
            ),
            prefixIcon: Icon(icon, size: 18),
            prefixIconConstraints: const BoxConstraints(
              minWidth: 40,
              minHeight: 40,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
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
            errorStyle: const TextStyle(fontSize: 11, height: 1),
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
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: TenantAdminColors.bodyText,
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 6),
        Stack(
          children: [
            TextField(
              controller: controller,
              enabled: enabled,
              keyboardType: keyboardType,
              maxLines: maxLines,
              maxLength: maxLength,
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: TenantAdminColors.bodyText,
              ),
              decoration: InputDecoration(
                isDense: true,
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
                        left: 40,
                        top: 12,
                        right: 12,
                        bottom: 12,
                      )
                    : const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                prefixIcon: isMultiLine
                    ? null
                    : Icon(icon, size: 18, color: const Color(0xFF64748B)),
                prefixIconConstraints: isMultiLine
                    ? null
                    : const BoxConstraints(
                        minWidth: 40,
                        minHeight: 40,
                      ),
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
                errorStyle: const TextStyle(fontSize: 11, height: 1),
              ),
            ),
            if (isMultiLine)
              Positioned(
                top: 12,
                left: 12,
                child: IgnorePointer(
                  child: Icon(
                    icon,
                    size: 18,
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
        child: Text(
          emptyLabel,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    ];
  }

  return options
      .map(
        (option) => DropdownMenuItem<String>(
          value: option.id,
          child: Text(
            option.label,
            overflow: TextOverflow.ellipsis,
          ),
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

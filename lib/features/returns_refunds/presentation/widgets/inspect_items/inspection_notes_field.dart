import 'package:flutter/material.dart';

import '../../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';

class InspectionNotesField extends StatelessWidget {
  const InspectionNotesField({
    super.key,
    required this.controller,
    required this.notesLength,
    required this.maxLength,
    required this.onChanged,
    this.required = false,
  });

  final TextEditingController controller;
  final int notesLength;
  final int maxLength;
  final ValueChanged<String> onChanged;
  final bool required;

  @override
  Widget build(BuildContext context) {
    final label = required ? 'Notes' : 'Notes (Optional)';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: TenantAdminSpacing.sm),
        TextFormField(
          controller: controller,
          maxLines: 3,
          maxLength: maxLength,
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: 'Add notes about the item condition...',
            counterText: '$notesLength/$maxLength',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(TenantAdminRadius.md),
            ),
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';

import '../../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';
import '../../providers/return_reason_provider.dart';

class ReturnReasonNotesField extends StatelessWidget {
  const ReturnReasonNotesField({
    super.key,
    required this.controller,
    required this.notesLength,
    required this.onChanged,
    this.required = false,
  });

  final TextEditingController controller;
  final int notesLength;
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
                color: TenantAdminColors.bodyText,
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: TenantAdminSpacing.sm),
        TextFormField(
          controller: controller,
          maxLines: 4,
          maxLength: returnReasonNotesMaxLength,
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: 'Add notes for this return or exchange...',
            alignLabelWithHint: true,
            counterText: '$notesLength/$returnReasonNotesMaxLength',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(TenantAdminRadius.md),
            ),
          ),
        ),
      ],
    );
  }
}

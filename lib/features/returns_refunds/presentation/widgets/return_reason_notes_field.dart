import 'package:flutter/material.dart';

import '../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';
import '../providers/return_reason_provider.dart';

class ReturnReasonNotesField extends StatelessWidget {
  const ReturnReasonNotesField({
    super.key,
    required this.controller,
    required this.notesLength,
    required this.onChanged,
  });

  final TextEditingController controller;
  final int notesLength;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Add a note (optional)',
          style: TenantAdminTextStyles.sectionTitle(context),
        ),
        const SizedBox(height: TenantAdminSpacing.lg),
        TextFormField(
          controller: controller,
          maxLines: 4,
          maxLength: returnReasonNotesMaxLength,
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: 'Enter reason for return...',
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

import 'package:flutter/material.dart';

import '../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';

class ReturnCreditConfirmationCheckbox extends StatelessWidget {
  const ReturnCreditConfirmationCheckbox({
    super.key,
    required this.value,
    required this.onChanged,
    this.showValidationMessage = false,
  });

  final bool value;
  final ValueChanged<bool?> onChanged;
  final bool showValidationMessage;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CheckboxListTile(
          value: value,
          onChanged: onChanged,
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          title: Text(
            'I confirm the return details are correct',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
        if (showValidationMessage && !value) ...[
          const SizedBox(height: TenantAdminSpacing.xs),
          Text(
            'Confirmation is required before creating credit.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: TenantAdminColors.danger,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ],
    );
  }
}

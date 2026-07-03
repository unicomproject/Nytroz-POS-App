import 'package:flutter/material.dart';

import '../../../presentation/theme/tenant_admin_theme.dart';
import '../../../presentation/widgets/tenant_admin_buttons.dart';

class InventoryFormField extends StatelessWidget {
  const InventoryFormField({
    super.key,
    required this.label,
    required this.child,
    this.errorText,
    this.requiredField = false,
  });

  final String label;
  final Widget child;
  final String? errorText;
  final bool requiredField;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: TenantAdminSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
            text: TextSpan(
              text: label,
              style: const TextStyle(
                color: TenantAdminColors.bodyText,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
              children: [
                if (requiredField)
                  const TextSpan(
                    text: ' *',
                    style: TextStyle(color: TenantAdminColors.danger),
                  ),
              ],
            ),
          ),
          const SizedBox(height: TenantAdminSpacing.sm),
          child,
          if (errorText != null) ...[
            const SizedBox(height: 4),
            Text(
              errorText!,
              style: const TextStyle(
                color: TenantAdminColors.danger,
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class InventoryApiBanner extends StatelessWidget {
  const InventoryApiBanner({
    super.key,
    required this.message,
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: TenantAdminSpacing.lg),
      padding: const EdgeInsets.all(TenantAdminSpacing.md),
      decoration: BoxDecoration(
        color: TenantAdminColors.warning.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(TenantAdminRadius.md),
        border: Border.all(
          color: TenantAdminColors.warning.withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline,
            color: TenantAdminColors.warning,
            size: 18,
          ),
          const SizedBox(width: TenantAdminSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: TenantAdminColors.bodyText,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class InventoryFormActions extends StatelessWidget {
  const InventoryFormActions({
    super.key,
    required this.onCancel,
    required this.onSave,
    required this.submitting,
    required this.saveEnabled,
  });

  final VoidCallback onCancel;
  final VoidCallback onSave;
  final bool submitting;
  final bool saveEnabled;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TenantAdminSecondaryButton(
          label: 'Cancel',
          onPressed: submitting ? null : onCancel,
        ),
        const SizedBox(width: TenantAdminSpacing.sm),
        TenantAdminPrimaryButton(
          label: submitting ? 'Saving...' : 'Save',
          icon: Icons.save_outlined,
          onPressed: saveEnabled && !submitting ? onSave : null,
        ),
      ],
    );
  }
}

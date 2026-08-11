import 'package:flutter/material.dart';

import '../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';
import '../../../auth/presentation/widgets/pos_onboarding_form_components.dart';

class DeviceActivationForm extends StatelessWidget {
  const DeviceActivationForm({
    super.key,
    required this.formKey,
    required this.codeController,
    required this.isSubmitting,
    required this.onSubmit,
    required this.isWide,
    this.errorMessage,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController codeController;
  final bool isSubmitting;
  final bool isWide;
  final VoidCallback onSubmit;
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PosOnboardingHeading(
            leadingText: 'Activate',
            accentText: 'Device',
            isWide: isWide,
          ),
          const SizedBox(height: TenantAdminSpacing.sm),
          Text(
            'Enter your device activation code to continue.',
            style: TextStyle(
              color: TenantAdminColors.mutedText,
              fontSize: isWide ? 18 : 16,
            ),
          ),
          SizedBox(height: isWide ? 36 : TenantAdminSpacing.xl),
          if (errorMessage != null) ...[
            Container(
              padding: const EdgeInsets.all(TenantAdminSpacing.md),
              decoration: BoxDecoration(
                color: TenantAdminColors.danger.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(TenantAdminRadius.md),
                border: Border.all(
                  color: TenantAdminColors.danger.withValues(alpha: 0.25),
                ),
              ),
              child: Text(
                errorMessage!,
                style: const TextStyle(
                  color: TenantAdminColors.danger,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: TenantAdminSpacing.lg),
          ],
          PosOnboardingField(
            label: 'Device Activation Code',
            hint: 'Enter device activation code',
            controller: codeController,
            icon: Icons.key,
            isWide: isWide,
            semanticLabel: 'Device Activation Code',
            keyboardType: TextInputType.text,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) {
              if (!isSubmitting) onSubmit();
            },
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Device activation code is required.';
              }
              return null;
            },
          ),
          SizedBox(height: isWide ? 28 : TenantAdminSpacing.lg),
          PosOnboardingPrimaryAction(
            label: 'Activate Device',
            semanticLabel:
                isSubmitting ? 'Activating device' : 'Activate Device',
            onPressed: isSubmitting ? null : onSubmit,
            isLoading: isSubmitting,
            isWide: isWide,
          ),
        ],
      ),
    );
  }
}

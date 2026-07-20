import 'package:flutter/material.dart';

import '../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';
import '../../../../shared/widgets/pos_action_buttons.dart';

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
    final labelSize = isWide ? 15.0 : 14.0;
    final textSize = isWide ? 18.0 : 16.0;
    final hintSize = isWide ? 17.0 : 15.0;
    final iconSize = isWide ? 26.0 : 24.0;
    final verticalPadding = isWide ? 20.0 : 17.0;
    final borderRadius = isWide ? 14.0 : 12.0;

    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Activate Device',
            style: TextStyle(
              color: TenantAdminColors.navy,
              fontWeight: FontWeight.w900,
              fontSize: isWide ? 32 : 28,
            ),
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
          Text(
            'Device Activation Code',
            style: TextStyle(
              color: TenantAdminColors.navy,
              fontSize: labelSize,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: codeController,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => onSubmit(),
            style: TextStyle(
              color: TenantAdminColors.bodyText,
              fontWeight: FontWeight.w500,
              fontSize: textSize,
            ),
            decoration: InputDecoration(
              prefixIcon: Icon(
                Icons.key_outlined,
                color: TenantAdminColors.mutedText,
                size: iconSize,
              ),
              hintText: 'Enter device activation code',
              hintStyle: TextStyle(
                color: TenantAdminColors.mutedText.withValues(alpha: 0.75),
                fontWeight: FontWeight.w400,
                fontSize: hintSize,
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 18,
                vertical: verticalPadding,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(borderRadius),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(borderRadius),
                borderSide: const BorderSide(
                  color: TenantAdminColors.navy,
                  width: 1.5,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(borderRadius),
                borderSide: const BorderSide(color: TenantAdminColors.danger),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(borderRadius),
                borderSide: const BorderSide(color: TenantAdminColors.danger),
              ),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Device activation code is required.';
              }
              return null;
            },
          ),
          SizedBox(height: isWide ? 28 : TenantAdminSpacing.lg),
          PosPrimaryActionButton(
            label: 'Activate Device',
            onPressed: isSubmitting ? null : onSubmit,
            isLoading: isSubmitting,
            fullWidth: true,
            minimumHeight: isWide ? 62 : 56,
          ),
        ],
      ),
    );
  }
}

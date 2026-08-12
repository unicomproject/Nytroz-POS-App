import 'package:flutter/material.dart';

import '../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';
import 'auth_error_banner.dart';
import 'pos_onboarding_form_components.dart';

class PosLoginForm extends StatelessWidget {
  const PosLoginForm({
    super.key,
    required this.formKey,
    required this.emailController,
    required this.passwordController,
    required this.subtitle,
    required this.isWide,
    required this.obscurePassword,
    required this.submitting,
    required this.onTogglePassword,
    required this.onSubmit,
    this.error,
  });
  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final String subtitle;
  final bool isWide;
  final bool obscurePassword;
  final bool submitting;
  final VoidCallback onTogglePassword;
  final VoidCallback onSubmit;
  final String? error;

  @override
  Widget build(BuildContext context) => Form(
        key: formKey,
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          PosOnboardingHeading(
            leadingText: 'Welcome',
            accentText: 'Back!',
            isWide: isWide,
          ),
          SizedBox(height: isWide ? 18 : TenantAdminSpacing.sm),
          Text(
            subtitle,
            style: TextStyle(
              color: TenantAdminColors.mutedText,
              fontSize: isWide ? 21 : 17,
              fontWeight: FontWeight.w400,
              height: 1.35,
            ),
          ),
          SizedBox(height: isWide ? 40 : TenantAdminSpacing.xl),
          if (error != null) ...[
            AuthErrorBanner(message: error!),
            const SizedBox(height: TenantAdminSpacing.lg)
          ],
          PosOnboardingField(
              label: 'Email',
              hint: 'Enter email',
              controller: emailController,
              icon: Icons.person_outline,
              keyboardType: TextInputType.emailAddress,
              isWide: isWide,
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Email is required' : null),
          const SizedBox(height: TenantAdminSpacing.lg),
          PosOnboardingField(
              label: 'Password',
              hint: 'Enter password',
              controller: passwordController,
              icon: Icons.lock_outline,
              obscureText: obscurePassword,
              isWide: isWide,
              suffix: IconButton(
                  onPressed: onTogglePassword,
                  icon: Icon(
                    obscurePassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: TenantAdminColors.mutedText,
                  )),
              validator: (v) =>
                  v == null || v.isEmpty ? 'Password is required' : null),
          SizedBox(height: isWide ? 32 : TenantAdminSpacing.xl),
          PosOnboardingPrimaryAction(
              label: 'Sign In',
              semanticLabel: 'Sign in to POS',
              onPressed: submitting ? null : onSubmit,
              isLoading: submitting,
              isWide: isWide),
        ]),
      );
}

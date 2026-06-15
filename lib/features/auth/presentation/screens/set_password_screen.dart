import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';
import '../../../tenant_admin/presentation/widgets/tenant_admin_buttons.dart';
import '../providers/set_password_provider.dart';
import '../providers/setup_token_provider.dart';
import '../widgets/auth_error_banner.dart';
import '../widgets/auth_page_shell.dart';
import '../widgets/password_rules_box.dart';

class SetPasswordScreen extends ConsumerStatefulWidget {
  const SetPasswordScreen({
    super.key,
    required this.setupToken,
  });

  final String setupToken;

  @override
  ConsumerState<SetPasswordScreen> createState() => _SetPasswordScreenState();
}

class _SetPasswordScreenState extends ConsumerState<SetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();
  var _submitting = false;
  String? _error;

  @override
  void dispose() {
    _password.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final setupValidationState =
        ref.watch(setupTokenValidationProvider(widget.setupToken));
    final email = setupValidationState.maybeWhen(
      data: (validation) => validation.email,
      orElse: () => null,
    );

    return AuthPageShell(
      title: 'Set your password',
      subtitle: 'Activate your Nytroz POS account to continue',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(TenantAdminSpacing.md),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F8FF),
                borderRadius: BorderRadius.circular(TenantAdminRadius.md),
                border: Border.all(color: TenantAdminColors.border),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, color: TenantAdminColors.info),
                  SizedBox(width: TenantAdminSpacing.sm),
                  Expanded(
                    child: Text(
                      'You were invited by your administrator. Create a secure password to access the POS app.',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: TenantAdminSpacing.md),
            if (_error != null) ...[
              AuthErrorBanner(message: _error!),
              const SizedBox(height: TenantAdminSpacing.lg),
            ],
            TextFormField(
              key: ValueKey(email ?? 'loading-username'),
              initialValue: email ?? '',
              enabled: false,
              decoration: const InputDecoration(
                labelText: 'Username',
                hintText: 'Loading account email',
                prefixIcon: Icon(Icons.email_outlined),
              ),
            ),
            const SizedBox(height: TenantAdminSpacing.sm),
            TextFormField(
              controller: _password,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'New Password',
                hintText: 'Enter secure password',
                prefixIcon: Icon(Icons.lock_outline),
                suffixIcon: Icon(Icons.visibility_outlined),
              ),
              validator: _validatePassword,
            ),
            const SizedBox(height: TenantAdminSpacing.sm),
            TextFormField(
              controller: _confirmPassword,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Confirm Password',
                hintText: 'Repeat password',
                prefixIcon: Icon(Icons.restart_alt),
                suffixIcon: Icon(Icons.visibility_outlined),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Confirm password is required';
                }
                if (value != _password.text) {
                  return 'Passwords must match';
                }
                return null;
              },
            ),
            const SizedBox(height: TenantAdminSpacing.md),
            const PasswordRulesBox(),
            const SizedBox(height: TenantAdminSpacing.lg),
            TenantAdminPrimaryButton(
              label: 'Set Password & Activate Account',
              loading: _submitting,
              onPressed: _submit,
            ),
            const SizedBox(height: TenantAdminSpacing.sm),
            TextButton(
              onPressed:
                  _submitting ? null : () => context.go('/tenant-login'),
              child: const Text('Cancel'),
            ),
            const Divider(height: 32),
            const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.shield_outlined,
                  size: 18,
                  color: TenantAdminColors.mutedText,
                ),
                SizedBox(width: TenantAdminSpacing.sm),
                Expanded(
                  child: Text(
                    'For security reasons, your password was not sent by email. This activation link will expire in 24 hours.',
                    style: TextStyle(
                      color: TenantAdminColors.mutedText,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String? _validatePassword(String? value) {
    final password = value ?? '';
    if (password.isEmpty) {
      return 'Password is required';
    }
    if (password.length < 8) {
      return 'Password must be at least 8 characters';
    }
    final hasUpper = RegExp('[A-Z]').hasMatch(password);
    final hasLower = RegExp('[a-z]').hasMatch(password);
    final hasNumber = RegExp('[0-9]').hasMatch(password);
    final hasSpecial = RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password);
    if (!hasUpper || !hasLower || !hasNumber || !hasSpecial) {
      return 'Use uppercase, lowercase, number, and special character';
    }
    return null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      await ref.read(setPasswordProvider).call(
            setupToken: widget.setupToken,
            password: _password.text,
            confirmPassword: _confirmPassword.text,
          );
      if (!mounted) {
        return;
      }
      context.go('/tenant-admin/setup/success');
    } catch (_) {
      setState(() => _error = 'Unable to set password. Please try again.');
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';
import '../../../tenant_admin/presentation/widgets/tenant_admin_buttons.dart';
import '../../domain/entities/auth_exception.dart';
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
  var _showPassword = false;
  var _showConfirmation = false;
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
    final validation = setupValidationState.asData?.value;
    if (setupValidationState.isLoading ||
        setupValidationState.hasError ||
        validation == null ||
        !validation.valid ||
        validation.expired) {
      return AuthPageShell(
        title: 'Verify your invitation',
        child: setupValidationState.when(
          skipLoadingOnRefresh: false,
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Column(children: [
            AuthErrorBanner(
                message: error is AuthException
                    ? error.message
                    : 'Unable to verify your invitation. Please try again.'),
            TextButton(
              onPressed: () => ref
                  .invalidate(setupTokenValidationProvider(widget.setupToken)),
              child: const Text('Retry verification'),
            ),
          ]),
          data: (value) => Column(children: [
            AuthErrorBanner(
                message: value.message ??
                    'This invitation is invalid or has expired. Ask your administrator for a new invitation.'),
            TextButton(
                onPressed: () => context.go('/tenant-login'),
                child: const Text('Back to login')),
          ]),
        ),
      );
    }
    final email = setupValidationState.maybeWhen(
      data: (validation) => validation.email,
      orElse: () => null,
    );

    return AuthPageShell(
      title: 'Set your password',
      subtitle: 'Activate your ONEVERZ Tenant Admin account to continue',
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
              obscureText: !_showPassword,
              enabled: !_submitting,
              decoration: InputDecoration(
                labelText: 'New Password',
                hintText: 'Enter secure password',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  tooltip: _showPassword ? 'Hide password' : 'Show password',
                  onPressed: () =>
                      setState(() => _showPassword = !_showPassword),
                  icon: Icon(_showPassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined),
                ),
              ),
              validator: _validatePassword,
            ),
            const SizedBox(height: TenantAdminSpacing.sm),
            TextFormField(
              controller: _confirmPassword,
              obscureText: !_showConfirmation,
              enabled: !_submitting,
              decoration: InputDecoration(
                labelText: 'Confirm Password',
                hintText: 'Repeat password',
                prefixIcon: const Icon(Icons.restart_alt),
                suffixIcon: IconButton(
                  tooltip: _showConfirmation
                      ? 'Hide confirmation'
                      : 'Show confirmation',
                  onPressed: () =>
                      setState(() => _showConfirmation = !_showConfirmation),
                  icon: Icon(_showConfirmation
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined),
                ),
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
              onPressed: _submitting ? null : () => context.go('/tenant-login'),
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
                    'Your password is never sent by email. This invitation can only be used once and is valid until its configured expiry time.',
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
    if (password.length > 128) {
      return 'Password must be at most 128 characters';
    }
    final hasUpper = RegExp('[A-Z]').hasMatch(password);
    final hasLower = RegExp('[a-z]').hasMatch(password);
    final hasNumber = RegExp('[0-9]').hasMatch(password);
    if (!hasUpper || !hasLower || !hasNumber) {
      return 'Use uppercase, lowercase, and numeric characters';
    }
    return null;
  }

  Future<void> _submit() async {
    final validation =
        ref.read(setupTokenValidationProvider(widget.setupToken)).asData?.value;
    if (_submitting ||
        validation == null ||
        !validation.valid ||
        validation.expired ||
        !(_formKey.currentState?.validate() ?? false)) {
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
    } on AuthException catch (error) {
      if (!mounted) return;
      if (const [
        'INVITE_EXPIRED',
        'INVITE_USED',
        'INVITE_CANCELLED',
        'INVITE_INVALID',
        'TENANT_NOT_OPERATIONAL'
      ].contains(error.errorCode)) {
        ref.invalidate(setupTokenValidationProvider(widget.setupToken));
      }
      setState(() => _error = _mapSetupPasswordError(error));
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Unable to set password. Please try again.');
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  String _mapSetupPasswordError(AuthException error) {
    switch (error.errorCode) {
      case 'INVITE_EXPIRED':
        return 'This invitation link has expired. Ask your administrator to resend it.';
      case 'INVITE_USED':
        return 'This invitation link has already been used. Try signing in.';
      case 'INVITE_CANCELLED':
        return 'This invitation link has been cancelled. Ask your administrator to resend it.';
      case 'INVITE_INVALID':
        return 'This invitation link is invalid or no longer available.';
      case 'TENANT_NOT_OPERATIONAL':
        return 'This tenant is not available for account setup.';
      case 'PASSWORD_INVALID':
      case 'PASSWORD_MISMATCH':
        return error.message;
      default:
        return error.message.isNotEmpty
            ? error.message
            : 'Unable to set password. Please try again.';
    }
  }
}

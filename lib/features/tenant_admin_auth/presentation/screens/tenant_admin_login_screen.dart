import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../tenant_admin/presentation/providers/tenant_admin_context_provider.dart';
import '../../../tenant_admin/presentation/providers/tenant_admin_menu_provider.dart';
import '../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';
import '../../../tenant_admin/presentation/widgets/tenant_admin_buttons.dart';
import '../providers/tenant_admin_login_provider.dart';
import '../providers/tenant_admin_session_provider.dart';
import '../widgets/auth_error_banner.dart';
import '../widgets/auth_page_shell.dart';

class TenantAdminLoginScreen extends ConsumerStatefulWidget {
  const TenantAdminLoginScreen({super.key});

  @override
  ConsumerState<TenantAdminLoginScreen> createState() =>
      _TenantAdminLoginScreenState();
}

class _TenantAdminLoginScreenState
    extends ConsumerState<TenantAdminLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  var _submitting = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AuthPageShell(
      title: 'Welcome back',
      subtitle: 'Login to access your Nytroz POS Tenant Admin dashboard.',
      heroTitle: 'Powering every sale.',
      heroSubtitle: 'Every store. Every till.',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_error != null) ...[
              AuthErrorBanner(message: _error!),
              const SizedBox(height: TenantAdminSpacing.lg),
            ],
            TextFormField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email',
                hintText: 'admin@example.com',
                prefixIcon: Icon(Icons.email_outlined),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Email is required';
                }
                return null;
              },
            ),
            const SizedBox(height: TenantAdminSpacing.md),
            TextFormField(
              controller: _password,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Password',
                hintText: 'Enter your password',
                prefixIcon: Icon(Icons.lock_outline),
                suffixIcon: Icon(Icons.visibility_outlined),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Password is required';
                }
                return null;
              },
            ),
            const SizedBox(height: TenantAdminSpacing.xl),
            TenantAdminPrimaryButton(
              label: 'Login',
              loading: _submitting,
              onPressed: _login,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      final session = await ref.read(loginTenantAdminProvider).call(
            email: _email.text.trim(),
            password: _password.text,
          );
      ref.read(tenantAdminSessionProvider.notifier).setSession(session);
      ref.read(tenantAdminDioProvider).options.headers['Authorization'] =
          'Bearer ${session.accessToken}';
      ref.refresh(tenantAdminContextProvider).maybeWhen(orElse: () {});
      ref.refresh(tenantAdminMenuProvider).maybeWhen(orElse: () {});

      if (!mounted) {
        return;
      }

      context.go('/tenant-admin/dashboard');
    } catch (_) {
      setState(() => _error = 'Login failed. Please check your credentials.');
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }
}

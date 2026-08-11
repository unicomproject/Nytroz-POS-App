import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:developer' as developer;

import '../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';
import '../../domain/entities/auth_exception.dart';
import '../../domain/entities/pos_login_branding.dart';
import '../providers/login_provider.dart';
import '../providers/pos_login_branding_provider.dart';
import '../providers/session_provider.dart';
import '../widgets/pos_login_branding_panel.dart';
import '../widgets/pos_login_form.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  var _submitting = false;
  var _obscurePassword = true;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    // Chrome/web and landscape tablet: left branding + right Sign In.
    // Narrow native phones keep the stacked compact layout.
    final isWide = kIsWeb || width >= TenantAdminBreakpoints.tablet;
    final loadedBranding = ref.watch(posLoginBrandingProvider);
    final branding = loadedBranding.tenantSlug.isEmpty &&
            loadedBranding.brandDisplayName.isEmpty
        ? PosLoginBranding.packagedDefault
        : loadedBranding;

    if (isWide) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 45,
              child: PosLoginBrandingPanel(
                branding: branding,
                compact: false,
              ),
            ),
            const VerticalDivider(
              width: 1,
              thickness: 1,
              color: Color(0xFFE5EAF2),
            ),
            Expanded(
              flex: 55,
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 48,
                    vertical: 32,
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 520),
                    child: _buildLoginForm(
                      isWide: true,
                      subtitle: branding.loginSubtitle,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: TenantAdminSpacing.lg,
            vertical: TenantAdminSpacing.xl,
          ),
          child: Column(
            children: [
              PosLoginBrandingPanel(
                branding: branding,
                compact: true,
              ),
              const SizedBox(height: TenantAdminSpacing.xl),
              _buildLoginForm(
                isWide: false,
                subtitle: branding.loginSubtitle,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoginForm({
    required bool isWide,
    required String subtitle,
  }) {
    return PosLoginForm(
      formKey: _formKey,
      emailController: _email,
      passwordController: _password,
      subtitle: subtitle,
      isWide: isWide,
      obscurePassword: _obscurePassword,
      submitting: _submitting,
      error: _error,
      onTogglePassword: () {
        setState(() => _obscurePassword = !_obscurePassword);
      },
      onSubmit: _login,
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
      final stopwatch = Stopwatch()..start();
      developer.log(
        'Login request started. endpoint=/api/v1/tenant-auth/login',
        name: 'auth.login',
      );
      final session = await ref.read(loginProvider).call(
            login: _email.text.trim(),
            password: _password.text,
          );
      stopwatch.stop();
      developer.log(
        'Login request succeeded. endpoint=/api/v1/tenant-auth/login durationMs=${stopwatch.elapsedMilliseconds}',
        name: 'auth.login',
      );
      if (!session.isAuthenticated) {
        throw StateError('Invalid credentials');
      }
      await ref.read(authSessionProvider.notifier).setSession(session);
    } on AuthException catch (error) {
      setState(() => _error = '${error.message} (${error.errorCode})');
    } catch (_) {
      setState(() => _error =
          'Login failed. Please check your credentials. (LOGIN_FAILED)');
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }
}

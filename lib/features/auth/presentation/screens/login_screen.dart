import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/dio_provider.dart';
import '../../../tenant_admin/presentation/providers/tenant_admin_context_provider.dart';
import '../../../tenant_admin/presentation/providers/tenant_admin_menu_provider.dart';
import '../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';
import '../../domain/entities/auth_branding.dart';
import '../providers/auth_branding_provider.dart';
import '../providers/login_provider.dart';
import '../providers/session_provider.dart';
import '../widgets/auth_error_banner.dart';

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
    final isWide = width >= TenantAdminBreakpoints.tablet;
    final branding = ref.watch(authBrandingProvider).maybeWhen(
          data: (value) => value,
          orElse: () => const AuthBranding(),
        );

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(
              width < TenantAdminBreakpoints.mobile
                  ? TenantAdminSpacing.lg
                  : TenantAdminSpacing.xxl,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1020),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: const Color(0xFFE5EAF2)),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x1A0F172A),
                      blurRadius: 32,
                      offset: Offset(0, 18),
                    ),
                  ],
                ),
                child: isWide
                    ? IntrinsicHeight(
                        child: Row(
                          children: [
                            Expanded(
                                child: _LoginBrandPanel(branding: branding)),
                            Container(width: 1, color: const Color(0xFFE5EAF2)),
                            Expanded(child: _buildLoginForm()),
                          ],
                        ),
                      )
                    : Column(
                        children: [
                          _LoginBrandPanel(
                            compact: true,
                            branding: branding,
                          ),
                          const Divider(height: 1),
                          _buildLoginForm(),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginForm() {
    return Padding(
      padding: const EdgeInsets.all(44),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Welcome Back!',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: TenantAdminColors.navy,
                    fontWeight: FontWeight.w900,
                  ),
            ),
            const SizedBox(height: TenantAdminSpacing.xs),
            const Text(
              'Sign in to continue to Nytroz POS',
              style: TextStyle(color: TenantAdminColors.bodyText),
            ),
            const SizedBox(height: TenantAdminSpacing.xl),
            if (_error != null) ...[
              AuthErrorBanner(message: _error!),
              const SizedBox(height: TenantAdminSpacing.lg),
            ],
            TextFormField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Username / Email',
                hintText: 'Enter username or email',
                prefixIcon: Icon(Icons.person_outline),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Email is required';
                }
                return null;
              },
            ),
            const SizedBox(height: TenantAdminSpacing.lg),
            TextFormField(
              controller: _password,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Password / PIN',
                hintText: 'Enter password or PIN',
                prefixIcon: Icon(Icons.lock_outline),
                suffixIcon: Icon(Icons.visibility_off_outlined),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Password is required';
                }
                return null;
              },
            ),
            const SizedBox(height: TenantAdminSpacing.sm),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: null,
                child: Text(
                  'Forgot Password?',
                  style: TextStyle(
                    color: TenantAdminColors.navy.withValues(alpha: 0.72),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(height: TenantAdminSpacing.md),
            SizedBox(
              height: 54,
              child: ElevatedButton(
                onPressed: _submitting ? null : _login,
                style: ElevatedButton.styleFrom(
                  backgroundColor: TenantAdminColors.navy,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(TenantAdminRadius.md),
                  ),
                ),
                child: _submitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Sign In',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
              ),
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
      final session = await ref.read(loginProvider).call(
            email: _email.text.trim(),
            password: _password.text,
          );
      if (!session.isAuthenticated) {
        throw StateError('Invalid credentials');
      }
      ref.read(authSessionProvider.notifier).setSession(session);
      ref.read(appDioProvider).options.headers['Authorization'] =
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

class _LoginBrandPanel extends StatelessWidget {
  const _LoginBrandPanel({
    required this.branding,
    this.compact = false,
  });

  final bool compact;
  final AuthBranding branding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(compact ? TenantAdminSpacing.xl : 44),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFFFFFF),
            Color(0xFFF3F7FF),
          ],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _UploadedImageOrFallback(
            imageUrl: branding.logoUrl,
            width: compact ? 58 : 74,
            height: compact ? 58 : 74,
            borderRadius: 18,
            fallback: Container(
              decoration: BoxDecoration(
                color: TenantAdminColors.navy,
                borderRadius: BorderRadius.circular(18),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x26071A33),
                    blurRadius: 18,
                    offset: Offset(0, 10),
                  ),
                ],
              ),
              child: const Icon(
                Icons.shopping_bag_outlined,
                color: Colors.white,
                size: 36,
              ),
            ),
          ),
          const SizedBox(height: TenantAdminSpacing.lg),
          Text(
            'Nytroz POS',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: TenantAdminColors.navy,
                      fontWeight: FontWeight.w900,
                    ) ??
                const TextStyle(
                  color: TenantAdminColors.navy,
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: TenantAdminSpacing.xs),
          const Text(
            'Smart Cashier System',
            style: TextStyle(
              color: TenantAdminColors.bodyText,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (!compact) ...[
            const SizedBox(height: 42),
            _UploadedImageOrFallback(
              imageUrl: branding.loginIllustrationUrl,
              width: 300,
              height: 220,
              borderRadius: 28,
              fit: BoxFit.contain,
              fallback: const _PosIllustration(),
            ),
          ],
        ],
      ),
    );
  }
}

class _UploadedImageOrFallback extends StatelessWidget {
  const _UploadedImageOrFallback({
    required this.imageUrl,
    required this.width,
    required this.height,
    required this.fallback,
    this.borderRadius = 0,
    this.fit = BoxFit.cover,
  });

  final String? imageUrl;
  final double width;
  final double height;
  final double borderRadius;
  final BoxFit fit;
  final Widget fallback;

  @override
  Widget build(BuildContext context) {
    final url = imageUrl?.trim();
    if (url == null || url.isEmpty) {
      return SizedBox(width: width, height: height, child: fallback);
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: Image.network(
        url,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) {
          return SizedBox(width: width, height: height, child: fallback);
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) {
            return child;
          }

          return SizedBox(
            width: width,
            height: height,
            child: const Center(child: CircularProgressIndicator()),
          );
        },
      ),
    );
  }
}

class _PosIllustration extends StatelessWidget {
  const _PosIllustration();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 220,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 260,
            height: 190,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF2FF),
              borderRadius: BorderRadius.circular(120),
            ),
          ),
          Positioned(
            bottom: 36,
            child: Container(
              width: 190,
              height: 74,
              decoration: BoxDecoration(
                color: const Color(0xFF111827),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Icon(Icons.point_of_sale,
                    color: Color(0xFF60A5FA), size: 36),
              ),
            ),
          ),
          Positioned(
            bottom: 16,
            left: 96,
            child: Container(
              width: 170,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFF1F2937),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          Positioned(
            bottom: 22,
            right: 54,
            child: Container(
              width: 42,
              height: 118,
              decoration: BoxDecoration(
                color: const Color(0xFF111827),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
          Positioned(
            bottom: 130,
            right: 48,
            child: Container(
              width: 66,
              height: 38,
              decoration: BoxDecoration(
                color: const Color(0xFF374151),
                borderRadius: BorderRadius.circular(22),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

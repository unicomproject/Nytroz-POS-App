import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_provider.dart';
import '../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';
import '../../domain/entities/auth_exception.dart';
import '../providers/login_provider.dart';
import '../providers/session_provider.dart';
import '../widgets/auth_error_banner.dart';

const _logoAsset = 'assets/images/logo.png';
const _terminalAsset = 'assets/images/log-screen-terminal.png';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _tenantCode = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  var _submitting = false;
  var _obscurePassword = true;
  String? _error;

  @override
  void dispose() {
    _tenantCode.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isWide = width >= TenantAdminBreakpoints.tablet;

    if (isWide) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Expanded(
              flex: 45,
              child: _LoginBrandPanel(compact: false),
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
                    child: _buildLoginForm(isWide: true),
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
              const _LoginBrandPanel(compact: true),
              const SizedBox(height: TenantAdminSpacing.xl),
              _buildLoginForm(isWide: false),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoginForm({required bool isWide}) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Welcome Back!',
            style: TextStyle(
              color: TenantAdminColors.navy,
              fontWeight: FontWeight.w900,
              fontSize: isWide ? 32 : 28,
            ),
          ),
          const SizedBox(height: TenantAdminSpacing.sm),
          Text(
            'Sign in to continue to Nytroz POS',
            style: TextStyle(
              color: TenantAdminColors.mutedText,
              fontSize: isWide ? 18 : 16,
            ),
          ),
          SizedBox(height: isWide ? 36 : TenantAdminSpacing.xl),
          if (_error != null) ...[
            AuthErrorBanner(message: _error!),
            const SizedBox(height: TenantAdminSpacing.lg),
          ],
          _LoginLabeledField(
            label: 'Tenant Code',
            hintText: 'Enter tenant code',
            controller: _tenantCode,
            prefixIcon: Icons.storefront_outlined,
            textCapitalization: TextCapitalization.characters,
            large: isWide,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Tenant code is required';
              }
              return null;
            },
          ),
          const SizedBox(height: TenantAdminSpacing.lg),
          _LoginLabeledField(
            label: 'Email',
            hintText: 'Enter email',
            controller: _email,
            prefixIcon: Icons.person_outline,
            keyboardType: TextInputType.emailAddress,
            large: isWide,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Email is required';
              }
              return null;
            },
          ),
          const SizedBox(height: TenantAdminSpacing.lg),
          _LoginLabeledField(
            label: 'Password',
            hintText: 'Enter password',
            controller: _password,
            prefixIcon: Icons.lock_outline,
            obscureText: _obscurePassword,
            large: isWide,
            suffixIcon: IconButton(
              onPressed: () {
                setState(() => _obscurePassword = !_obscurePassword);
              },
              icon: Icon(
                _obscurePassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: TenantAdminColors.mutedText,
                size: isWide ? 26 : 24,
              ),
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
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                'Forgot Password?',
                style: TextStyle(
                  color: TenantAdminColors.navy.withValues(alpha: 0.72),
                  fontWeight: FontWeight.w700,
                  fontSize: isWide ? 16 : 15,
                ),
              ),
            ),
          ),
          SizedBox(height: isWide ? 28 : TenantAdminSpacing.lg),
          SizedBox(
            height: isWide ? 62 : 56,
            child: ElevatedButton(
              onPressed: _submitting ? null : _login,
              style: ElevatedButton.styleFrom(
                backgroundColor: TenantAdminColors.navy,
                foregroundColor: Colors.white,
                elevation: 0,
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
                  : Text(
                      'Sign In',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: isWide ? 18 : 17,
                      ),
                    ),
            ),
          ),
        ],
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
            tenantCode: _tenantCode.text.trim(),
            login: _email.text.trim(),
            password: _password.text,
          );
      if (!session.isAuthenticated) {
        throw StateError('Invalid credentials');
      }
      await ref.read(authSessionProvider.notifier).setSession(session);
      ref.read(appDioProvider).options.headers['Authorization'] =
          'Bearer ${session.accessToken}';
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

class _LoginBrandPanel extends StatelessWidget {
  const _LoginBrandPanel({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final logoSize = compact ? 72.0 : 96.0;
    final terminalWidth = compact ? 300.0 : 440.0;
    final terminalHeight = compact ? 215.0 : 320.0;
    final titleSize = compact ? 34.0 : 40.0;
    final taglineSize = compact ? 18.0 : 20.0;

    return DecoratedBox(
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
      child: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? TenantAdminSpacing.lg : 48,
            vertical: compact ? TenantAdminSpacing.xl : 32,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                _logoAsset,
                width: logoSize,
                height: logoSize,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: TenantAdminSpacing.lg),
              Text(
                'Nytroz POS',
                style: TextStyle(
                  color: TenantAdminColors.navy,
                  fontSize: titleSize,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: TenantAdminSpacing.sm),
              Text(
                'Smart Cashier System',
                style: TextStyle(
                  color: TenantAdminColors.bodyText,
                  fontSize: taglineSize,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: compact ? TenantAdminSpacing.xl : 48),
              Image.asset(
                _terminalAsset,
                width: terminalWidth,
                height: terminalHeight,
                fit: BoxFit.contain,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoginLabeledField extends StatelessWidget {
  const _LoginLabeledField({
    required this.label,
    required this.hintText,
    required this.controller,
    required this.prefixIcon,
    this.validator,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.none,
    this.obscureText = false,
    this.suffixIcon,
    this.large = false,
  });

  final String label;
  final String hintText;
  final TextEditingController controller;
  final IconData prefixIcon;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;
  final bool obscureText;
  final Widget? suffixIcon;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final labelSize = large ? 15.0 : 14.0;
    final textSize = large ? 18.0 : 16.0;
    final hintSize = large ? 17.0 : 15.0;
    final iconSize = large ? 26.0 : 24.0;
    final verticalPadding = large ? 20.0 : 17.0;
    final borderRadius = large ? 14.0 : 12.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: TenantAdminColors.navy,
            fontSize: labelSize,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          textCapitalization: textCapitalization,
          validator: validator,
          style: TextStyle(
            color: TenantAdminColors.bodyText,
            fontWeight: FontWeight.w500,
            fontSize: textSize,
          ),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(
              color: TenantAdminColors.mutedText.withValues(alpha: 0.75),
              fontWeight: FontWeight.w400,
              fontSize: hintSize,
            ),
            prefixIcon: Icon(
              prefixIcon,
              color: TenantAdminColors.mutedText,
              size: iconSize,
            ),
            suffixIcon: suffixIcon,
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
        ),
      ],
    );
  }
}

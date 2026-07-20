import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:developer' as developer;

import '../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';
import '../../../../shared/widgets/pos_action_buttons.dart';
import '../../domain/entities/auth_exception.dart';
import '../providers/login_provider.dart';
import '../providers/session_provider.dart';
import '../widgets/auth_error_banner.dart';

const _brandPanelAsset = 'assets/images/login_brand_panel.png';
const _brandPanelBackground = Color(0xFF000E2B);

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
          PosPrimaryActionButton(
            label: 'Sign In',
            semanticLabel: 'Sign in to Nytroz POS',
            onPressed: _submitting ? null : _login,
            isLoading: _submitting,
            fullWidth: true,
            minimumHeight: isWide ? 62 : 56,
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

class _LoginBrandPanel extends StatelessWidget {
  const _LoginBrandPanel({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final image = Image.asset(
      _brandPanelAsset,
      fit: BoxFit.contain,
    );

    if (compact) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: ColoredBox(
          color: _brandPanelBackground,
          child: SizedBox(
            width: double.infinity,
            height: 480,
            child: image,
          ),
        ),
      );
    }

    return ColoredBox(
      color: _brandPanelBackground,
      child: SizedBox.expand(
        child: Center(child: image),
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

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';
import '../../../tenant_admin/presentation/widgets/tenant_admin_buttons.dart';
import '../providers/setup_token_provider.dart';
import '../widgets/auth_error_banner.dart';
import '../widgets/auth_page_shell.dart';

class SetupLinkValidationScreen extends ConsumerWidget {
  const SetupLinkValidationScreen({
    super.key,
    required this.setupToken,
  });

  final String setupToken;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final validationState = ref.watch(setupTokenValidationProvider(setupToken));

    return AuthPageShell(
      title: 'Validating setup link',
      subtitle: 'We are checking your account setup token.',
      child: validationState.when(
        loading: () => const Column(
          children: [
            CircularProgressIndicator(),
          ],
        ),
        error: (error, stackTrace) => _InvalidSetupToken(
          message: 'Unable to validate setup link.',
          onRetry: () {
            ref
                .refresh(setupTokenValidationProvider(setupToken))
                .maybeWhen(orElse: () {});
          },
        ),
        data: (validation) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted && validation.valid && !validation.expired) {
              context.go('/tenant-admin/setup/$setupToken/password');
            }
          });

          if (!validation.valid || validation.expired) {
            return _InvalidSetupToken(
              message: validation.message ??
                  (validation.expired
                      ? 'This setup link has expired.'
                      : 'This setup link is invalid.'),
              onRetry: () => context.go('/tenant-login'),
            );
          }

          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }
}

class _InvalidSetupToken extends StatelessWidget {
  const _InvalidSetupToken({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AuthErrorBanner(message: message),
        const SizedBox(height: TenantAdminSpacing.xl),
        TenantAdminSecondaryButton(label: 'Back to login', onPressed: onRetry),
      ],
    );
  }
}

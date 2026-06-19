import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/tenant_admin/presentation/theme/tenant_admin_theme.dart';
import 'pos_session_bootstrap_provider.dart';

class PosSessionBootScreen extends ConsumerWidget {
  const PosSessionBootScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bootstrap = ref.watch(posSessionBootstrapProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FD),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(TenantAdminSpacing.xl),
            child: bootstrap.hasError
                ? _BootError(
                    message: bootstrap.errorMessage!,
                    failedStep: bootstrap.failedStep,
                    onRetry: () {
                      ref
                          .read(posSessionBootstrapProvider.notifier)
                          .bootstrap(force: true);
                    },
                  )
                : const _BootLoading(),
          ),
        ),
      ),
    );
  }
}

class _BootLoading extends StatelessWidget {
  const _BootLoading();

  @override
  Widget build(BuildContext context) {
    return const Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 36,
          height: 36,
          child: CircularProgressIndicator(
            strokeWidth: 3,
            color: TenantAdminColors.navy,
          ),
        ),
        SizedBox(height: TenantAdminSpacing.lg),
        Text(
          'Preparing POS session...',
          style: TextStyle(
            color: TenantAdminColors.bodyText,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _BootError extends StatelessWidget {
  const _BootError({
    required this.message,
    required this.onRetry,
    this.failedStep,
  });

  final String message;
  final String? failedStep;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: TenantAdminColors.surface,
        borderRadius: BorderRadius.circular(TenantAdminRadius.lg),
        border: Border.all(color: TenantAdminColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(TenantAdminSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: TenantAdminColors.danger,
              size: 36,
            ),
            const SizedBox(height: TenantAdminSpacing.md),
            Text(
              'Unable to prepare POS session',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: TenantAdminColors.bodyText,
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: TenantAdminSpacing.sm),
            Text(
              failedStep == null ? message : '$message\nStep: $failedStep',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: TenantAdminColors.mutedText,
                  ),
            ),
            const SizedBox(height: TenantAdminSpacing.lg),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

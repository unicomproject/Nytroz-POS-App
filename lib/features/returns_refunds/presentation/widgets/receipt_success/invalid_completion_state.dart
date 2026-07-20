import 'package:flutter/material.dart';

import '../../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';

class InvalidCompletionState extends StatelessWidget {
  const InvalidCompletionState({
    super.key,
    required this.onBackToHome,
    this.onBackToReview,
    this.onRetry,
    this.title = 'Completion details unavailable',
    this.message =
        'This success page can only be shown after a confirmed return or exchange completion.',
    this.showBackToReview = false,
    this.showRetry = false,
  });

  final VoidCallback onBackToHome;
  final VoidCallback? onBackToReview;
  final VoidCallback? onRetry;
  final String title;
  final String message;
  final bool showBackToReview;
  final bool showRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Container(
          padding: const EdgeInsets.all(TenantAdminSpacing.xl),
          decoration: BoxDecoration(
            color: TenantAdminColors.surface,
            borderRadius: BorderRadius.circular(TenantAdminRadius.lg),
            border: Border.all(color: TenantAdminColors.border),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                size: 48,
                color: TenantAdminColors.warning,
              ),
              const SizedBox(height: TenantAdminSpacing.lg),
              Text(
                title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
              ),
              const SizedBox(height: TenantAdminSpacing.sm),
              Text(
                message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: TenantAdminColors.mutedText,
                    ),
              ),
              const SizedBox(height: TenantAdminSpacing.xl),
              Row(
                children: [
                  if (showRetry && onRetry != null) ...[
                    Expanded(
                      child: OutlinedButton(
                        onPressed: onRetry,
                        child: const Text('Retry'),
                      ),
                    ),
                    const SizedBox(width: TenantAdminSpacing.md),
                  ],
                  if (showBackToReview && onBackToReview != null) ...[
                    Expanded(
                      child: OutlinedButton(
                        onPressed: onBackToReview,
                        child: const Text('Back to Review'),
                      ),
                    ),
                    const SizedBox(width: TenantAdminSpacing.md),
                  ],
                  Expanded(
                    child: FilledButton(
                      onPressed: onBackToHome,
                      child: const Text('POS Home'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

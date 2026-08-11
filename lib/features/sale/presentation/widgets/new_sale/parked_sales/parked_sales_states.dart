import 'package:flutter/material.dart';
import 'package:nytroz_pos/features/tenant_admin/presentation/theme/tenant_admin_theme.dart';

class ParkedSalesLoadingState extends StatelessWidget {
  const ParkedSalesLoadingState({super.key});

  @override
  Widget build(BuildContext context) => Center(
        child: Semantics(
          label: 'Loading parked sales',
          child: const CircularProgressIndicator(),
        ),
      );
}

class ParkedSalesEmptyState extends StatelessWidget {
  const ParkedSalesEmptyState({super.key});

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.pause_circle_outline_rounded,
              size: 48,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: TenantAdminSpacing.md),
            Text(
              'No parked sales available',
              style: TenantAdminTextStyles.sectionTitle(context),
            ),
            const SizedBox(height: TenantAdminSpacing.xs),
            Text(
              'Parked sales will appear here.',
              style: TenantAdminTextStyles.muted(context),
            ),
          ],
        ),
      );
}

class ParkedSalesLoadError extends StatelessWidget {
  const ParkedSalesLoadError({
    super.key,
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(TenantAdminSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ParkedSalesInlineError(message: message),
              const SizedBox(height: TenantAdminSpacing.md),
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Try Again'),
              ),
            ],
          ),
        ),
      );
}

class ParkedSalesInlineError extends StatelessWidget {
  const ParkedSalesInlineError({
    super.key,
    required this.message,
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      liveRegion: true,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: TenantAdminSpacing.lg),
        padding: const EdgeInsets.all(TenantAdminSpacing.md),
        decoration: BoxDecoration(
          color: scheme.errorContainer,
          borderRadius: BorderRadius.circular(TenantAdminRadius.md),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded, color: scheme.onErrorContainer),
            const SizedBox(width: TenantAdminSpacing.sm),
            Flexible(
              child: Text(
                message,
                style: TextStyle(color: scheme.onErrorContainer),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

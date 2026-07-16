import 'package:flutter/material.dart';

import '../../../../presentation/theme/tenant_admin_theme.dart';
import '../../../../presentation/widgets/tenant_admin_buttons.dart';
import '../../utils/report_error_mapper.dart';

class ReportLoadingState extends StatelessWidget {
  const ReportLoadingState({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const _ReportSkeleton(height: 92),
        const SizedBox(height: TenantAdminSpacing.lg),
        LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth < 600
                ? constraints.maxWidth
                : (constraints.maxWidth - 48) / 4;
            return Wrap(
              spacing: TenantAdminSpacing.lg,
              runSpacing: TenantAdminSpacing.lg,
              children: List.generate(
                4,
                (_) => SizedBox(
                  width: width,
                  child: const _ReportSkeleton(height: 116),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: TenantAdminSpacing.xl),
        const _ReportSkeleton(height: 280),
      ],
    );
  }
}

class ReportApiUnavailableState extends StatelessWidget {
  const ReportApiUnavailableState({
    super.key,
    this.onRetry,
    this.fallbackActions,
  });

  final VoidCallback? onRetry;
  final Widget? fallbackActions;

  @override
  Widget build(BuildContext context) {
    return ReportStateShell(
      icon: Icons.cloud_off_outlined,
      iconColor: TenantAdminColors.warning,
      title: 'Reports service is not available yet',
      message:
          'The Reports frontend is ready, but this reporting endpoint has not yet been implemented.',
      action: _ReportApiUnavailableActions(
        onRetry: onRetry,
        fallbackActions: fallbackActions,
      ),
    );
  }
}

class _ReportApiUnavailableActions extends StatelessWidget {
  const _ReportApiUnavailableActions({
    required this.onRetry,
    required this.fallbackActions,
  });

  final VoidCallback? onRetry;
  final Widget? fallbackActions;

  @override
  Widget build(BuildContext context) {
    if (onRetry == null && fallbackActions == null) {
      return const SizedBox.shrink();
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (onRetry != null)
          TenantAdminSecondaryButton(
            label: 'Retry',
            icon: Icons.refresh,
            onPressed: onRetry,
          ),
        if (fallbackActions != null) ...[
          const SizedBox(height: TenantAdminSpacing.md),
          fallbackActions!,
        ],
      ],
    );
  }
}

class ReportPermissionDeniedState extends StatelessWidget {
  const ReportPermissionDeniedState({super.key});

  @override
  Widget build(BuildContext context) {
    return const ReportStateShell(
      icon: Icons.lock_outline,
      iconColor: TenantAdminColors.danger,
      title: 'Report access denied',
      message: 'You do not have permission to view this report.',
    );
  }
}

class ReportFeatureDisabledState extends StatelessWidget {
  const ReportFeatureDisabledState({super.key});

  @override
  Widget build(BuildContext context) {
    return const ReportStateShell(
      icon: Icons.toggle_off_outlined,
      iconColor: TenantAdminColors.warning,
      title: 'Reports are not enabled',
      message: 'Reports are not enabled for this tenant.',
    );
  }
}

class ReportEmptyState extends StatelessWidget {
  const ReportEmptyState({super.key, required this.filtered, this.onClear});

  final bool filtered;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    return ReportStateShell(
      icon: filtered ? Icons.filter_alt_off_outlined : Icons.bar_chart_outlined,
      iconColor: TenantAdminColors.mutedText,
      title: filtered ? 'No matching report data' : 'No report data available',
      message: filtered
          ? 'Try changing or clearing the selected filters.'
          : 'No report data is available for the selected period.',
      action: filtered && onClear != null
          ? TenantAdminSecondaryButton(
              label: 'Clear filters',
              onPressed: onClear,
            )
          : null,
    );
  }
}

class ReportRequestErrorState extends StatelessWidget {
  const ReportRequestErrorState({
    super.key,
    required this.error,
    this.onRetry,
    this.fallbackActions,
  });

  final Object error;
  final VoidCallback? onRetry;
  final Widget? fallbackActions;

  @override
  Widget build(BuildContext context) {
    final kind = reportErrorKind(error);
    if (kind == ReportErrorKind.apiUnavailable) {
      return ReportApiUnavailableState(
        onRetry: onRetry,
        fallbackActions: fallbackActions,
      );
    }
    if (kind == ReportErrorKind.permissionDenied) {
      return const ReportPermissionDeniedState();
    }

    return ReportStateShell(
      icon: _errorIcon(kind),
      iconColor: _errorIconColor(kind),
      title: _errorTitle(kind),
      message: reportErrorMessage(error),
      action: kind == ReportErrorKind.validation || onRetry == null
          ? null
          : TenantAdminSecondaryButton(
              label: 'Retry',
              icon: Icons.refresh,
              onPressed: onRetry,
            ),
    );
  }
}

IconData _errorIcon(ReportErrorKind kind) {
  return switch (kind) {
    ReportErrorKind.validation => Icons.event_busy_outlined,
    ReportErrorKind.unauthorized => Icons.lock_clock_outlined,
    ReportErrorKind.notFound => Icons.search_off_outlined,
    ReportErrorKind.network => Icons.wifi_off_outlined,
    ReportErrorKind.conflict => Icons.sync_problem_outlined,
    ReportErrorKind.server => Icons.dns_outlined,
    _ => Icons.error_outline,
  };
}

Color _errorIconColor(ReportErrorKind kind) {
  return switch (kind) {
    ReportErrorKind.validation ||
    ReportErrorKind.conflict ||
    ReportErrorKind.network =>
      TenantAdminColors.warning,
    _ => TenantAdminColors.danger,
  };
}

String _errorTitle(ReportErrorKind kind) {
  return switch (kind) {
    ReportErrorKind.validation => 'Choose a valid report period',
    ReportErrorKind.unauthorized => 'Session expired',
    ReportErrorKind.notFound => 'Report not found',
    ReportErrorKind.network => 'Reports server unreachable',
    ReportErrorKind.conflict => 'Report request conflict',
    ReportErrorKind.server => 'Reports server error',
    _ => 'Unable to load report',
  };
}

class ReportStateShell extends StatelessWidget {
  const ReportStateShell({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.message,
    this.action,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 56),
      decoration: BoxDecoration(
        color: TenantAdminColors.surface,
        borderRadius: BorderRadius.circular(TenantAdminRadius.lg),
        border: Border.all(color: TenantAdminColors.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 46, color: iconColor),
          const SizedBox(height: TenantAdminSpacing.lg),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TenantAdminTextStyles.sectionTitle(context),
          ),
          const SizedBox(height: TenantAdminSpacing.sm),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: TenantAdminTextStyles.muted(context),
            ),
          ),
          if (action != null) ...[
            const SizedBox(height: TenantAdminSpacing.lg),
            action!,
          ],
        ],
      ),
    );
  }
}

class _ReportSkeleton extends StatelessWidget {
  const _ReportSkeleton({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: height,
      decoration: BoxDecoration(
        color: TenantAdminColors.border.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(TenantAdminRadius.lg),
      ),
    );
  }
}

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';
import '../../data/datasources/pos_home_remote_datasource.dart';
import '../providers/hardware_telemetry_provider.dart';
import '../providers/pos_home_dashboard_provider.dart';
import '../widgets/home/pos_home_dashboard.dart';

class PosHomeScreen extends ConsumerWidget {
  const PosHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardAsync = ref.watch(posHomeDashboardProvider);
    ref.watch(hardwareTelemetryProvider);

    return dashboardAsync.when(
      data: (dashboard) => PosHomeDashboard(dashboard: dashboard),
      loading: () => PosHomeDashboard(
        dashboard: buildPosHomeShellDashboard(ref),
        status: const _DashboardInlineStatus.loading(),
      ),
      error: (error, _) {
        final message = error is PosHomeException
            ? error.message
            : 'POS home dashboard could not be loaded. Try again.';
        final showOpenTillAction = error is PosHomeException &&
            error.reasonCode == 'NO_OPEN_TILL_SESSION';

        return PosHomeDashboard(
          dashboard: buildPosHomeShellDashboard(ref, homeError: error),
          onSummaryRetry: () => unawaited(retryPosHomeDashboard(ref)),
          status: _DashboardInlineStatus.error(
            message: message,
            onRetry: () => unawaited(retryPosHomeDashboard(ref)),
            actionLabel: showOpenTillAction ? 'Open Till' : null,
            onAction: showOpenTillAction ? () => _openTill(context) : null,
          ),
        );
      },
    );
  }

  void _openTill(BuildContext context) {
    context.push('/pos/open-till');
  }
}

class _DashboardInlineStatus extends StatelessWidget {
  const _DashboardInlineStatus.loading()
      : message = 'Dashboard information is loading.',
        onRetry = null,
        actionLabel = null,
        onAction = null;

  const _DashboardInlineStatus.error({
    required this.message,
    required this.onRetry,
    this.actionLabel,
    this.onAction,
  });

  final String message;
  final VoidCallback? onRetry;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final isError = onRetry != null;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(TenantAdminSpacing.md),
      decoration: BoxDecoration(
        color: TenantAdminColors.surface,
        borderRadius: BorderRadius.circular(TenantAdminRadius.md),
        border: Border.all(color: TenantAdminColors.border),
      ),
      child: Row(
        children: [
          if (isError)
            const Icon(
              Icons.error_outline_rounded,
              color: TenantAdminColors.warning,
            )
          else
            const SizedBox.square(
              dimension: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          const SizedBox(width: TenantAdminSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: TenantAdminColors.bodyText,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
          if (onAction != null && actionLabel != null) ...[
            TextButton(
              onPressed: onAction,
              child: Text(actionLabel!),
            ),
            const SizedBox(width: TenantAdminSpacing.sm),
          ],
          if (onRetry != null)
            TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
            ),
        ],
      ),
    );
  }
}

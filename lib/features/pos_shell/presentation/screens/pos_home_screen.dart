import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/session_provider.dart';
import '../../../device_activation/presentation/providers/device_activation_provider.dart';
import '../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';
import '../../../till/presentation/providers/till_provider.dart';
import '../../application/state/pos_home_dashboard_state.dart';
import '../../data/datasources/pos_home_remote_datasource.dart';
import '../providers/pos_home_dashboard_provider.dart';
import '../widgets/home/pos_home_dashboard.dart';

class PosHomeScreen extends ConsumerWidget {
  const PosHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardAsync = ref.watch(posHomeDashboardProvider);
    final shellDashboard = _shellDashboard(ref);

    return dashboardAsync.when(
      data: (dashboard) => PosHomeDashboard(dashboard: dashboard),
      loading: () => PosHomeDashboard(
        dashboard: shellDashboard,
        status: const _DashboardInlineStatus.loading(),
      ),
      error: (error, _) => PosHomeDashboard(
        dashboard: shellDashboard,
        onSummaryRetry: () => ref.invalidate(posHomeDashboardProvider),
        status: _DashboardInlineStatus.error(
          message: error is PosHomeException
              ? error.message
              : 'POS home dashboard could not be loaded. Try again.',
          onRetry: () => ref.invalidate(posHomeDashboardProvider),
        ),
      ),
    );
  }

  PosHomeDashboardState _shellDashboard(WidgetRef ref) {
    final session = ref.watch(authSessionProvider);
    final deviceContext = ref.watch(deviceActivationProvider).deviceContext;
    final tillState = ref.watch(tillProvider);

    return buildPosHomeShellState(
      userDisplayName: session?.userDisplayName ?? '',
      isTrustedDevice: deviceContext?.isTrusted == true,
      hasOpenTillSession: tillState.hasOpenSession,
      permissionCodes: session?.permissionCodes.toSet() ?? const {},
    );
  }
}

class _DashboardInlineStatus extends StatelessWidget {
  const _DashboardInlineStatus.loading()
      : message = 'Dashboard information is loading.',
        onRetry = null;

  const _DashboardInlineStatus.error({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback? onRetry;

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

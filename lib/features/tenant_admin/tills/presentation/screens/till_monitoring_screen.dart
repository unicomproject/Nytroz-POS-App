import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../presentation/theme/tenant_admin_theme.dart';
import '../../../presentation/widgets/tenant_admin_page_scaffold.dart';
import '../../../presentation/widgets/tenant_admin_states.dart';
import '../../../presentation/theme/tenant_admin_theme.dart';
import '../providers/till_visibility_provider.dart';
import '../widgets/till_monitoring_workspace.dart';

class TillMonitoringScreen extends ConsumerWidget {
  const TillMonitoringScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final visibilityState = ref.watch(tillListVisibilityProvider);

    return visibilityState.when(
      loading: () => const TenantAdminPageScaffold(
        title: 'Tills',
        subtitle: 'Monitor till status and hardware readiness.',
        fillHeight: true,
        child: TenantAdminLoadingSkeleton(rowCount: 8),
      ),
      error: (error, stackTrace) => TenantAdminPageScaffold(
        title: 'Tills',
        subtitle: 'Monitor till status and hardware readiness.',
        fillHeight: true,
        child: TenantAdminErrorState(
          title: 'Unable to load tills',
          message: 'Please try again.',
          onRetry: () => ref.invalidate(tillListVisibilityProvider),
        ),
      ),
      data: (visibility) {
        if (!visibility.showPage) {
          return const TenantAdminPageScaffold(
            title: 'No access to Tills',
            fillHeight: true,
            child: TenantAdminEmptyState(
              title: 'No access',
              message: 'You do not have permission to view tills.',
            ),
          );
        }

        return TenantAdminPageScaffold(
          title: visibility.showTitle ? 'Tills' : '',
          subtitle: visibility.showSubtitle
              ? 'Monitor till status and hardware readiness.'
              : null,
          fillHeight: true,
          scrollable: false,
          actions: [
            if (visibility.showAddTill)
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: TenantAdminColors.posHomeAccentOrange,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  minimumSize: const Size(132, 46),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 13,
                  ),
                  textStyle: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              TenantAdminPrimaryButton(
                label: 'Add Till',
                icon: Icons.add,
                backgroundColor: TenantAdminColors.posHomeAccentOrange,
                onPressed: () => context.go('/tenant-admin/tills/add'),
                icon: const Icon(Icons.add, size: 20),
                label: const Text('Add Till'),
              ),
          ],
          child: TillMonitoringWorkspace(visibility: visibility),
        );
      },
    );
  }
}

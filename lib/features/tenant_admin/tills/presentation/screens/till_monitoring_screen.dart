import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../presentation/widgets/tenant_admin_buttons.dart';
import '../../../presentation/widgets/tenant_admin_page_scaffold.dart';
import '../../../presentation/widgets/tenant_admin_states.dart';
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
        child: TenantAdminLoadingSkeleton(rowCount: 8),
      ),
      error: (error, stackTrace) => TenantAdminPageScaffold(
        title: 'Tills',
        subtitle: 'Monitor till status and hardware readiness.',
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
          actions: [
            if (visibility.showAddTill)
              TenantAdminPrimaryButton(
                label: 'Add Till',
                icon: Icons.add,
                onPressed: () => context.go('/tenant-admin/tills/add'),
              ),
          ],
          child: TillMonitoringWorkspace(visibility: visibility),
        );
      },
    );
  }
}

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../auth/presentation/providers/session_provider.dart';
import '../../../presentation/widgets/tenant_admin_page_scaffold.dart';
import '../../../presentation/widgets/tenant_admin_states.dart';
import '../providers/till_providers.dart';
import '../providers/till_visibility_provider.dart';
import '../widgets/add_till_single_page_form.dart';

class AddTillScreen extends ConsumerWidget {
  const AddTillScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(authHeaderSyncProvider);
    final canCreate = ref.watch(tillCreateAccessProvider);
    final canViewHardware = ref.watch(tillHardwareViewAccessProvider);
    final canManageHardware = ref.watch(tillHardwareManageAccessProvider);

    // Auto dispose provider for create options
    final optionsState = ref.watch(tillCreateOptionsProvider(null));

    if (!canCreate) {
      return const TenantAdminPageScaffold(
        title: 'No access',
        child: TenantAdminEmptyState(
          title: 'No access',
          message: 'You do not have permission to create tills.',
        ),
      );
    }

    return TenantAdminPageScaffold(
      title: 'Add till',
      subtitle: 'Enter the details for the new till.',
      child: optionsState.when(
        loading: () => const TenantAdminLoadingSkeleton(rowCount: 4),
        error: (error, stackTrace) {
          if (error is DioException && error.response?.statusCode == 401) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              ref.read(authSessionProvider.notifier).clear();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content:
                      Text('Your session has expired. Please sign in again.'),
                ),
              );
              context.go('/tenant-login');
            });
            return const SizedBox.shrink();
          }

          return TenantAdminErrorState(
            title: 'Unable to load options',
            message: 'Please try again.',
            onRetry: () => ref.invalidate(tillCreateOptionsProvider(null)),
          );
        },
        data: (options) {
          if (options == null || options.outlets.isEmpty) {
            return const TenantAdminEmptyState(
              title: 'No outlets available',
              message: 'Create an outlet before adding a till.',
            );
          }

          return AddTillSinglePageForm(
            options: options,
            canViewHardware: canViewHardware,
            canManageHardware: canManageHardware,
          );
        },
      ),
    );
  }
}

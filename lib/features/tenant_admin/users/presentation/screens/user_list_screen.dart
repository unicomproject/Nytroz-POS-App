import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../domain/services/tenant_admin_access_checker.dart';
import '../../../presentation/theme/tenant_admin_theme.dart';
import '../../../presentation/widgets/tenant_admin_buttons.dart';
import '../../../presentation/widgets/tenant_admin_page_scaffold.dart';
import '../../../presentation/widgets/tenant_admin_search_field.dart';
import '../../../presentation/widgets/tenant_admin_states.dart';
import '../providers/tenant_user_providers.dart';
import '../providers/tenant_user_visibility_provider.dart';
import '../widgets/user_filter_chips.dart';
import '../widgets/user_list_panel.dart';

class UserListScreen extends ConsumerWidget {
  const UserListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final visibilityState = ref.watch(userListVisibilityProvider);
    final usersState = ref.watch(userListProvider);
    final statusFilter = ref.watch(userStatusFilterProvider);

    return visibilityState.when(
      loading: () => const TenantAdminPageScaffold(
        title: 'Users',
        subtitle: 'Manage all tenant users and their access.',
        child: TenantAdminLoadingSkeleton(rowCount: 8),
      ),
      error: (error, stackTrace) => TenantAdminPageScaffold(
        title: 'Users',
        subtitle: 'Manage all tenant users and their access.',
        child: TenantAdminErrorState(
          title: 'Unable to load users',
          message: 'Please try again.',
          onRetry: () => ref.invalidate(userListVisibilityProvider),
        ),
      ),
      data: (visibility) {
        if (!visibility.showPage) {
          return const TenantAdminPageScaffold(
            title: 'No access to Users',
            child: TenantAdminEmptyState(
              title: 'No access',
              message: 'You do not have permission to view users.',
            ),
          );
        }

        return usersState.when(
          loading: () => TenantAdminPageScaffold(
            title: visibility.showTitle ? 'Users' : '',
            subtitle: visibility.showSubtitle
                ? 'Manage all tenant users and their access.'
                : null,
            child: const TenantAdminLoadingSkeleton(rowCount: 8),
          ),
          error: (error, stackTrace) => TenantAdminPageScaffold(
            title: 'Users',
            subtitle: 'Manage all tenant users and their access.',
            child: TenantAdminErrorState(
              title: 'Unable to load users',
              message: 'Please try again.',
              onRetry: () => ref.refresh(userListProvider),
            ),
          ),
          data: (result) {
            if (result == null) {
              return const TenantAdminPageScaffold(
                title: 'No access to Users',
                child: TenantAdminEmptyState(
                  title: 'No access',
                  message: 'You do not have permission to view users.',
                ),
              );
            }

            return LayoutBuilder(
              builder: (context, constraints) {
                final isMobile = constraints.maxWidth < 700;

                return TenantAdminPageScaffold(
                  title: visibility.showTitle ? 'Users' : '',
                  subtitle: visibility.showSubtitle
                      ? 'Manage all tenant users and their access.'
                      : null,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _UserSearchToolbar(
                        visibility: visibility,
                        isMobile: isMobile,
                      ),
                      if (visibility.showSearch || visibility.showAddUser)
                        const SizedBox(height: TenantAdminSpacing.lg),
                      if (visibility.showStatusFilter) ...[
                        UserFilterChips(selectedFilter: statusFilter),
                        const SizedBox(height: TenantAdminSpacing.xl),
                      ],
                      if (visibility.showList)
                        UserListPanel(
                          result: result,
                          visibility: visibility,
                          statusFilter: statusFilter,
                          isMobile: isMobile,
                        ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}

class _UserSearchToolbar extends ConsumerWidget {
  const _UserSearchToolbar({required this.visibility, required this.isMobile});

  final UserListVisibility visibility;
  final bool isMobile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!visibility.showSearch && !visibility.showAddUser) {
      return const SizedBox.shrink();
    }

    final searchField = TenantAdminSearchField(
      hint: 'Search users by name or email',
      value: ref.watch(userSearchProvider),
      onChanged: (value) {
        ref.read(userSearchProvider.notifier).state = value;
        ref.read(userPageProvider.notifier).state = 1;
      },
    );

    final addButton = TenantAdminPrimaryButton(
      label: 'Add New User',
      icon: Icons.add,
      onPressed: () => context.go('/tenant-admin/staff/add'),
    );

    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (visibility.showSearch) searchField,
          if (visibility.showAddUser) ...[
            if (visibility.showSearch)
              const SizedBox(height: TenantAdminSpacing.sm),
            Align(alignment: Alignment.centerRight, child: addButton),
          ],
        ],
      );
    }

    return Row(
      children: [
        if (visibility.showSearch) Expanded(child: searchField),
        if (visibility.showAddUser) ...[
          if (visibility.showSearch)
            const SizedBox(width: TenantAdminSpacing.sm),
          addButton,
        ],
      ],
    );
  }
}
